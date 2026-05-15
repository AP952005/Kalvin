import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class LocalModelManager {
  /// ============================================================
  /// PUT YOUR GOOGLE DRIVE FILE ID HERE
  /// ============================================================
  /// After uploading your .gguf file to Google Drive:
  ///   1. Right-click → Share → Anyone with the link
  ///   2. Copy the link. It looks like:
  ///      https://drive.google.com/file/d/XXXXX/view?usp=sharing
  ///   3. Copy the XXXXX part and paste it below.
  /// ============================================================
  static const String _driveFileId = '1xi_oYyocgtN-JTxVWEVCRG_3MiAN3VwQ';

  static const String _modelFileName = 'kalvin_brain_gemma.gguf';

  /// Check if the model already exists in local storage.
  static Future<bool> isModelExtracted() async {
    final path = await getLocalModelPath();
    final file = File(path);
    if (!await file.exists()) return false;

    // Basic integrity check: file should be at least 1GB
    final size = await file.length();
    debugPrint('[LocalModel] Existing model size: ${(size / (1024 * 1024)).toStringAsFixed(1)} MB');
    return size > 1024 * 1024 * 1000;
  }

  /// Get the absolute path where the model should live on the phone.
  static Future<String> getLocalModelPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_modelFileName';
  }

  /// Download the model from Google Drive with large-file confirmation handling.
  static Future<void> downloadModel({
    void Function(double progress)? onProgress,
  }) async {
    final localPath = await getLocalModelPath();
    final file = File(localPath);

    if (await isModelExtracted()) {
      debugPrint('[LocalModel] Model already exists and is healthy.');
      return;
    }

    // Delete any partial downloads
    if (await file.exists()) {
      await file.delete();
    }

    debugPrint('[LocalModel] Starting Google Drive download...');

    final client = http.Client();

    try {
      // Step 1: Initial request to Google Drive
      final initialUrl =
          'https://drive.google.com/uc?export=download&id=$_driveFileId';
      debugPrint('[LocalModel] Requesting: $initialUrl');

      final initialResponse = await client.get(Uri.parse(initialUrl));

      // Step 2: Google Drive shows a "virus scan" confirmation page for large files.
      //         We need to extract the confirmation token and retry.
      String downloadUrl;

      if (initialResponse.statusCode == 200 &&
          initialResponse.body.contains('confirm=')) {
        // Extract confirmation token from HTML
        final confirmMatch = RegExp(r'confirm=([0-9A-Za-z_\-]+)')
            .firstMatch(initialResponse.body);
        final uuid = RegExp(r'uuid=([0-9A-Za-z_\-]+)')
            .firstMatch(initialResponse.body);

        if (confirmMatch != null) {
          final token = confirmMatch.group(1);
          downloadUrl =
              'https://drive.google.com/uc?export=download&confirm=$token&id=$_driveFileId';
          if (uuid != null) {
            downloadUrl += '&uuid=${uuid.group(1)}';
          }
          debugPrint('[LocalModel] Got confirmation token, retrying...');
        } else {
          // Try alternate large file download URL
          downloadUrl =
              'https://drive.usercontent.google.com/download?id=$_driveFileId&export=download&confirm=t';
          debugPrint('[LocalModel] Using alternate download URL...');
        }
      } else if (initialResponse.statusCode == 302 ||
          initialResponse.statusCode == 303) {
        // Direct redirect
        downloadUrl = initialResponse.headers['location'] ?? initialUrl;
        debugPrint('[LocalModel] Got redirect to: $downloadUrl');
      } else {
        // Try the direct usercontent URL (works for most shared files)
        downloadUrl =
            'https://drive.usercontent.google.com/download?id=$_driveFileId&export=download&confirm=t';
        debugPrint('[LocalModel] Trying direct usercontent URL...');
      }

      // Step 3: Stream the actual file download
      final streamResponse = await _sendWithRedirects(client, downloadUrl);

      if (streamResponse.statusCode != 200) {
        throw Exception(
            'Download failed (Status: ${streamResponse.statusCode}). '
            'Make sure the file is shared as "Anyone with the link".');
      }

      // Google Drive may not always return content-length for large files
      final int totalBytes = streamResponse.contentLength ?? 1630263008;
      int receivedBytes = 0;

      final sink = file.openWrite();
      debugPrint(
          '[LocalModel] Download streaming... Expected: ${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB');

      await for (final List<int> chunk in streamResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (onProgress != null) {
          onProgress((receivedBytes / totalBytes).clamp(0.0, 1.0));
        }

        // Log progress every 50MB
        if (receivedBytes % (50 * 1024 * 1024) < chunk.length) {
          debugPrint(
              '[LocalModel] Progress: ${(receivedBytes / (1024 * 1024)).toStringAsFixed(1)} MB');
        }
      }

      await sink.close();
      client.close();

      // Verify download
      final downloadedSize = await file.length();
      debugPrint(
          '[LocalModel] Download complete! Size: ${(downloadedSize / (1024 * 1024)).toStringAsFixed(1)} MB');

      if (downloadedSize < 1024 * 1024 * 100) {
        // Less than 100MB means we probably got an HTML error page
        await file.delete();
        throw Exception(
            'Downloaded file is too small (${(downloadedSize / 1024).toStringAsFixed(0)} KB). '
            'Check that the Google Drive link is correct and publicly shared.');
      }
    } catch (e) {
      client.close();
      debugPrint('[LocalModel] Download ERROR: $e');
      // Clean up partial download
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Follow HTTP redirects for streamed responses.
  static Future<http.StreamedResponse> _sendWithRedirects(
    http.Client client,
    String url, {
    int maxRedirects = 10,
  }) async {
    if (maxRedirects <= 0) throw Exception('Too many redirects');

    final request = http.Request('GET', Uri.parse(url));
    request.followRedirects = false;
    // Pretend to be a browser so Google Drive doesn't block us
    request.headers['User-Agent'] =
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36';

    final response = await client.send(request);

    if (response.statusCode == 301 ||
        response.statusCode == 302 ||
        response.statusCode == 303 ||
        response.statusCode == 307 ||
        response.statusCode == 308) {
      final location = response.headers['location'];
      if (location == null) throw Exception('Redirect without location header');

      debugPrint('[LocalModel] Following redirect → ${location.substring(0, location.length.clamp(0, 80))}...');
      // Drain the current response before following redirect
      await response.stream.drain();
      return _sendWithRedirects(client, location,
          maxRedirects: maxRedirects - 1);
    }

    return response;
  }

  /// Remove the model to free up space.
  static Future<void> deleteLocalModel() async {
    final path = await getLocalModelPath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      debugPrint('[LocalModel] Model deleted.');
    }
  }
}
