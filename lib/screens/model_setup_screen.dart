/// Kalvin AI — Model Setup Screen
///
/// Downloads Kalvin's "Brain" from Google Drive on first launch.
/// Shows a beautiful progress UI with download speed info.

import 'package:flutter/material.dart';
import '../ai/local_model_manager.dart';
import '../theme/app_colors.dart';

class ModelSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const ModelSetupScreen({super.key, required this.onComplete});

  @override
  State<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends State<ModelSetupScreen> {
  double _progress = 0;
  String _status = 'Preparing Kalvin\'s Brain...';
  bool _isDownloading = false;
  bool _hasFailed = false;
  String _errorDetail = '';

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final exists = await LocalModelManager.isModelExtracted();
    if (exists) {
      widget.onComplete();
    }
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return; // Prevent double-tap

    setState(() {
      _isDownloading = true;
      _hasFailed = false;
      _errorDetail = '';
      _progress = 0;
      _status = 'Downloading Kalvin\'s Brain...\n(~1.6GB — Use Wi-Fi for best results)';
    });

    try {
      await LocalModelManager.downloadModel(
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _progress = p;
              final mb = (p * 1630).toStringAsFixed(0);
              _status = 'Downloading... ${mb}MB / 1630MB\n${(p * 100).toStringAsFixed(1)}% complete';
            });
          }
        },
      );
      if (mounted) widget.onComplete();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasFailed = true;
          _isDownloading = false;
          _errorDetail = e.toString();
          _status = 'Download failed.\nCheck your internet and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1728),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              AppColors.primaryBlue.withValues(alpha: 0.15),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'K',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),

            const Text(
              'AstraLearn AI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 60),

            // Progress bar
            if (_isDownloading) ...[
              Stack(
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 12,
                    width: (MediaQuery.of(context).size.width - 80) * _progress,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${(_progress * 100).toInt()}% Ready',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ] else ...[
              // Download / Retry button
              ElevatedButton(
                onPressed: _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasFailed
                      ? AppColors.primaryOrange
                      : AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(_hasFailed
                    ? 'Retry Download'
                    : 'Download Offline AI'),
              ),

              // Error detail
              if (_hasFailed && _errorDetail.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorDetail.length > 200
                        ? '${_errorDetail.substring(0, 200)}...'
                        : _errorDetail,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.withValues(alpha: 0.8),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
