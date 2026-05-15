/// Kalvin AI — Dual-Mode Llama Service
///
/// THE HYBRID BRAIN: Coordinates between the Remote PC server 
/// and the Local On-Device engine. Automatically fails over
/// to local inference if the remote server is unreachable.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_llama_service.dart';
import 'local_model_manager.dart';
import 'package:flutter/foundation.dart';

enum LlamaMode { remote, local, unavailable }

class LlamaService {
  final String remoteUrl;
  final http.Client _httpClient;
  final LocalLlamaService _localLlama;
  
  LlamaMode _currentMode = LlamaMode.unavailable;
  bool _localInitialized = false;

  LlamaService({
    this.remoteUrl = 'http://192.168.1.3:8080',
  }) : _httpClient = http.Client(),
       _localLlama = LocalLlamaService();

  LlamaMode get mode => _currentMode;

  /// Check availability of both brains.
  Future<bool> isAvailable() async {
    // 1. Try Remote
    try {
      final response = await _httpClient
          .get(Uri.parse('$remoteUrl/health'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        _currentMode = LlamaMode.remote;
        return true;
      }
    } catch (_) {}

    // 2. Try Local (Check if model is extracted)
    if (await LocalModelManager.isModelExtracted()) {
      _currentMode = LlamaMode.local;
      return true;
    }

    _currentMode = LlamaMode.unavailable;
    return false;
  }

  /// Generate response using the best available mode.
  Future<String> generateResponse(String prompt) async {
    // Determine mode first
    await isAvailable();

    if (_currentMode == LlamaMode.remote) {
      debugPrint('[LlamaService] Using REMOTE brain (PC)');
      return _generateRemote(prompt);
    } 
    
    if (_currentMode == LlamaMode.local) {
      debugPrint('[LlamaService] Using LOCAL brain (On-device)');
      if (!_localInitialized) {
        final success = await _localLlama.init();
        if (success) {
          _localInitialized = true;
        } else {
          return 'My local brain is still warming up or having a little trouble starting. Please try again in a few seconds! 🧠';
        }
      }
      return await _localLlama.generateResponse(prompt);
    }

    throw Exception('No AI engine available (Local or Remote)');
  }

  /// Private: Call the PC server.
  Future<String> _generateRemote(String prompt) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$remoteUrl/completion'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'n_predict': 180,
          'temperature': 0.7,
          'top_k': 40,
          'top_p': 0.9,
          'repeat_penalty': 1.15,
          'stop': ['</s>', 'Student:', 'Human:', 'User:', '<end_of_turn>', '\nStudent:'],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['content'] ?? body['response'] ?? '';
      }
      throw Exception('Remote server error: ${response.statusCode}');
    } catch (e) {
      // If remote fails mid-request, try to fall back to local immediately
      if (await LocalModelManager.isModelExtracted()) {
        debugPrint('[LlamaService] Remote FAILED, falling back to LOCAL');
        _currentMode = LlamaMode.local;
        if (!_localInitialized) {
          await _localLlama.init();
          _localInitialized = true;
        }
        return await _localLlama.generateResponse(prompt);
      }
      rethrow;
    }
  }

  void dispose() {
    _httpClient.close();
    _localLlama.dispose();
  }
}
