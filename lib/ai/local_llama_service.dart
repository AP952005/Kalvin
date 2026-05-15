/// Kalvin AI — Local Llama Service
///
/// Runs inference locally on the device using llama_cpp_dart.
/// NO internet or PC required after the first extraction.

import 'dart:async';
import 'dart:io';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'local_model_manager.dart';
import 'package:flutter/foundation.dart';

class LocalLlamaService {
  Llama? _llama;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Initialize the local engine. 
  /// MUST be called after LocalModelManager has finished downloading.
  Future<bool> init() async {
    if (_isLoaded) return true;

    try {
      final modelPath = await LocalModelManager.getLocalModelPath();
      final file = File(modelPath);
      
      if (!await file.exists()) {
        debugPrint('[LocalLlama] ERROR: Model file does not exist at $modelPath');
        return false;
      }

      debugPrint('[LocalLlama] Loading model from: $modelPath');
      
      // Load the model
      // Using nThreads = 4 for balanced performance on mobile
      _llama = Llama(
        modelPath,
        null, // No LoRA
        ContextParams()..nThreads = 4,
      );
      
      _isLoaded = true;
      debugPrint('[LocalLlama] Engine initialized successfully.');
      return true;
    } catch (e) {
      debugPrint('[LocalLlama] CRITICAL ERROR initializing engine: $e');
      _isLoaded = false;
      return false;
    }
  }

  /// Generate a response locally.
  Future<String> generateResponse(String prompt) async {
    if (!_isLoaded || _llama == null) {
      return 'I am still waking up my brain. Please wait a moment while I load my knowledge! 🧠';
    }

    try {
      _llama!.setPrompt(prompt);
      final result = await _llama!.generateCompleteText();
      return result;
    } catch (e) {
      debugPrint('[LocalLlama] Inference ERROR: $e');
      return 'I had a little trouble thinking just now. Could you try asking that again?';
    }
  }

  /// Free up memory.
  void dispose() {
    _llama?.dispose();
    _isLoaded = false;
  }
}
