import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../theme/app_colors.dart';
import '../models/topic.dart';
import '../models/session_model.dart';
import '../models/scene_metadata.dart';
import '../widgets/message_bubble.dart';
import '../widgets/timeline_bar.dart';
import '../widgets/kalvin_toast.dart';
import '../core/kalvin_core_controller.dart';
import '../core/failure_recovery.dart';
import '../ai/life_companion_engine.dart';

class LearnScreen extends StatefulWidget {
  final Topic? activeTopic;

  const LearnScreen({super.key, this.activeTopic});

  @override
  State<LearnScreen> createState() => LearnScreenState();
}

class LearnScreenState extends State<LearnScreen> {
  InAppWebViewController? _webController;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _webViewReady = false;

  Topic? _currentTopic;
  SessionModel? _session;

  // Renderer mode: hidden, inline, expanded, fullscreen
  _RendererMode _rendererMode = _RendererMode.inline;
  bool _rendererVisible = true;
  bool _audioMuted = false;

  // AI integration
  final KalvinCoreController _core = KalvinCoreController();
  bool _aiThinking = false;
  bool _aiInitialized = false;

  // Educational content per scene
  static const Map<String, List<Map<String, String>>> _sceneSteps = {
    'solar_system': [
      {
        'title': 'Observe the Solar System',
        'content':
            'The Sun sits at the center of our solar system. Earth orbits around it, held by gravity. Rotate the 3D view to explore from every angle!',
      },
      {
        'title': 'The Sun — Our Star',
        'content':
            'A massive ball of hydrogen and helium undergoing nuclear fusion. Its surface temperature reaches 5,500°C and it contains 99.8% of the solar system\'s total mass.',
      },
      {
        'title': 'The Earth — Our Home',
        'content':
            'Earth orbits the Sun at approximately 150 million km (1 AU). Its thin nitrogen-oxygen atmosphere and magnetic field protect all known life.',
      },
    ],
    'volcano': [
      {
        'title': 'Volcanic Formation',
        'content':
            'Volcanoes form at tectonic plate boundaries where magma from the mantle reaches the surface. The cone shape is built from alternating layers of hardened lava and volcanic ash.',
      },
      {
        'title': 'Inside the Volcano',
        'content':
            'Beneath the crater lies a magma chamber filled with molten rock at 700–1,300°C. Immense gas pressure builds until the magma erupts violently through the central vent.',
      },
      {
        'title': 'Eruption & Effects',
        'content':
            'During eruption, lava, ash, and volcanic gases are expelled. Pyroclastic flows can travel at 700 km/h. Volcanic ash clouds can affect global climate for years.',
      },
    ],
    'water_cycle': [
      {
        'title': 'The Water Cycle Begins',
        'content':
            'The Sun heats water in oceans, lakes, and rivers. This thermal energy causes water molecules to break free of the surface — evaporating from liquid into invisible water vapour.',
      },
      {
        'title': 'Condensation & Clouds',
        'content':
            'As water vapour rises into cooler air, it condenses around tiny dust particles called condensation nuclei. Billions of water droplets cluster together to form visible clouds.',
      },
      {
        'title': 'Precipitation & Return',
        'content':
            'When cloud droplets merge and grow heavy enough, they fall as rain, snow, or hail. Water flows through rivers and streams back to the ocean, completing the cycle.',
      },
    ],
  };

  int _timelineStep = 0;

  List<Map<String, String>> get _steps =>
      _sceneSteps[_currentTopic?.scene ?? 'solar_system'] ??
      _sceneSteps['solar_system']!;

  @override
  void initState() {
    super.initState();
    _currentTopic = widget.activeTopic ?? Topic.allTopics[0];
    _initSession();
    _initAI();
  }

  Future<void> _initAI() async {
    try {
      await _core.init();
      _core.onExecuteJS = (js) {
        if (_webViewReady && _webController != null) {
          _webController!.evaluateJavascript(source: js);
        }
      };
      if (mounted) {
        setState(() => _aiInitialized = true);
      }
    } catch (e) {
      debugPrint('AI init error: $e');
      // Even if AI init fails, mark as initialized so fallback works
      if (mounted) {
        setState(() => _aiInitialized = true);
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _initSession() {
    _session = SessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _currentTopic?.title ?? 'Untitled',
      scene: _currentTopic?.scene ?? 'solar_system',
    );

    _session!.messages.add(ChatMessage(
      text:
          'Welcome to the ${_currentTopic?.title ?? 'learning'} experience! 🎓\n\nI\'ll guide you through this topic step by step. You can interact with the 3D visualization above and ask me questions anytime.',
      isUser: false,
    ));

    if (_steps.isNotEmpty) {
      _session!.messages.add(ChatMessage(
        text: _steps[0]['content']!,
        isUser: false,
        type: MessageType.educationalCard,
        metadata: {'title': _steps[0]['title'], 'step': 1},
      ));
    }
  }

  void loadTopic(Topic topic) {
    setState(() {
      _currentTopic = topic;
      _timelineStep = 0;
      _rendererVisible = true;
      _rendererMode = _RendererMode.inline;
      _initSession();
    });
    if (_webViewReady && _webController != null) {
      _webController!.evaluateJavascript(
        source: "if(typeof loadScene!=='undefined') loadScene('${topic.scene}')",
      );
    }
    _scrollToBottom();
  }

  void runJS(String code) {
    _webController?.evaluateJavascript(source: code);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTimelineStep(int step) {
    if (step < 0 || step >= _steps.length) return;
    setState(() => _timelineStep = step);

    _session!.messages.add(ChatMessage(
      text: _steps[step]['content']!,
      isUser: false,
      type: MessageType.educationalCard,
      metadata: {'title': _steps[step]['title'], 'step': step + 1},
    ));

    _triggerStepCinematic(step);
    _scrollToBottom();
  }

  void _triggerStepCinematic(int step) {
    final scene = _currentTopic?.scene ?? '';
    switch (scene) {
      case 'solar_system':
        if (step == 1) runJS("focusSun()");
        if (step == 2) runJS("focusEarth()");
        break;
      case 'volcano':
        if (step == 1) runJS("focusMountain()");
        if (step == 2) runJS("triggerEruption()");
        break;
      case 'water_cycle':
        if (step == 1) runJS("focusOcean()");
        if (step == 2) runJS("focusSun()");
        break;
    }
  }

  void _showFactsFor(String objectName) {
    final scene = _currentTopic?.scene ?? '';
    final facts = SceneMetadata.getFacts(scene, objectName);
    if (facts.isEmpty) return;

    setState(() {
      _session!.messages.add(ChatMessage(
        text: '',
        isUser: false,
        type: MessageType.factCard,
        metadata: {'object': objectName, 'scene': scene},
      ));
    });
    _scrollToBottom();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _aiThinking) return;

    setState(() {
      _session!.messages.add(ChatMessage(text: text, isUser: true));
      _aiThinking = true;
      // Add thinking indicator
      _session!.messages.add(ChatMessage.thinking());
    });
    _inputController.clear();
    _inputFocusNode.unfocus();
    _scrollToBottom();

    _processWithAI(text);
  }

  Future<void> _processWithAI(String input) async {
    // Small delay so thinking indicator is visible
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) {
      _aiThinking = false;
      return;
    }

    try {
      // Try the full AI pipeline if orchestrator is ready and LLM reachable
      if (_aiInitialized &&
          _core.orchestrator != null &&
          _core.llmAvailable.value) {
        final response = await _core.processMessage(input);
        if (!mounted) return;

        if (response != null) {
          // SUCCESS — Replace thinking with real AI response
          _replaceThinkerWith(ChatMessage.fromAI(
            text: response.learningResponse.response,
            emotion: response.learningResponse.emotion,
            visual: response.learningResponse.visualScene,
            visualTriggered: response.learningResponse.visualRequired,
          ));

          // Show visual if triggered and renderer hidden
          if (response.learningResponse.visualRequired && !_rendererVisible) {
            setState(() => _rendererVisible = true);
          }

          // Show life companion message if present
          if (response.companionMessage != null) {
            _showCompanionMessage(response.companionMessage!);
          }

          _scrollToBottom();
          return;
        }
      }

      // FALLBACK — LLM not available or response was null
      _replaceThinkerWith(ChatMessage.fromAI(
        text: _getOfflineResponse(input),
        emotion: 'supportive',
      ));
    } catch (e) {
      debugPrint('AI error: $e');
      // ERROR — Show graceful recovery
      final fallback = FailureRecovery.recoverFromLLMFailure(e.toString());
      _replaceThinkerWith(ChatMessage.fromAI(
        text: fallback.response,
        emotion: 'supportive',
      ));
    }

    _scrollToBottom();
  }

  /// Offline response when LLM is not reachable.
  /// Provides a helpful message instead of dead silence.
  String _getOfflineResponse(String input) {
    final lower = input.toLowerCase();

    // Topic-specific offline hints
    if (lower.contains('volcano') || lower.contains('eruption')) {
      return 'Great question about volcanoes! 🌋 I need my AI brain '
          '(llama.cpp on localhost:8080) to give you a detailed answer. '
          'For now, tap the volcano scene steps above to explore interactively!\n\n'
          'Tip: Start the llama.cpp server on your computer to unlock full AI teaching.';
    }
    if (lower.contains('solar') || lower.contains('planet') || lower.contains('sun')) {
      return 'I love talking about space! 🪐 My AI engine needs to be running '
          'to give you a detailed explanation. Use the step navigator above to '
          'explore the solar system visually!\n\n'
          'Tip: Start llama.cpp to get full adaptive teaching.';
    }
    if (lower.contains('water') || lower.contains('rain') || lower.contains('cloud')) {
      return 'The water cycle is fascinating! 💧 I need my AI brain connected '
          'to explain it adaptively. Try the step-by-step guide above to learn '
          'about evaporation, condensation, and precipitation!\n\n'
          'Tip: Connect llama.cpp on localhost:8080 for full AI responses.';
    }

    return 'Hi! I\'m Kalvin, your learning companion. 🧠 Right now my AI brain '
        '(llama.cpp server) isn\'t connected, so I can\'t give you a detailed answer.\n\n'
        'You can still:\n'
        '• Use the step navigator to explore topics\n'
        '• Tap the 3D scenes to learn visually\n'
        '• Tap fact buttons to discover details\n\n'
        'To enable full AI: start llama.cpp server on localhost:8080.';
  }

  void _replaceThinkerWith(ChatMessage msg) {
    if (!mounted) return;
    setState(() {
      // Remove the thinking indicator
      _session!.messages.removeWhere((m) => m.type == MessageType.thinking);
      _session!.messages.add(msg);
      _aiThinking = false;
    });
    _scrollToBottom();
  }

  void _showCompanionMessage(LifeCompanionMessage msg) {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _session!.messages.add(ChatMessage.system(msg.text));
      });
      _scrollToBottom();
    });
  }

  void _startNewChat() {
    _core.stopNarration();
    _core.newConversation();
    setState(() {
      _aiThinking = false;
      _session = SessionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Chat',
        scene: _currentTopic?.scene ?? 'solar_system',
      );
      _session!.messages.add(ChatMessage(
        text: 'What would you like to explore? Ask me about science, space, nature, math — anything! 🌍',
        isUser: false,
      ));
      _timelineStep = 0;
    });
    _scrollToBottom();
    KalvinToast.show(context, message: '✨ New chat started', type: ToastType.info);
  }

  void _onFollowUpTap(String question) {
    _inputController.text = question;
    _sendMessage();
  }

  void _toggleRendererVisibility() {
    setState(() {
      _rendererVisible = !_rendererVisible;
      if (!_rendererVisible) {
        _rendererMode = _RendererMode.inline;
      }
    });
  }

  void _cycleRendererMode() {
    setState(() {
      switch (_rendererMode) {
        case _RendererMode.inline:
          _rendererMode = _RendererMode.expanded;
          break;
        case _RendererMode.expanded:
          _rendererMode = _RendererMode.fullscreen;
          break;
        case _RendererMode.fullscreen:
          _rendererMode = _RendererMode.inline;
          break;
      }
    });
  }

  double get _rendererHeight {
    if (!_rendererVisible) return 0;
    switch (_rendererMode) {
      case _RendererMode.inline:
        return 200;
      case _RendererMode.expanded:
        return 340;
      case _RendererMode.fullscreen:
        return MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            56; // leave room for close bar
    }
  }

  IconData get _rendererSizeIcon {
    switch (_rendererMode) {
      case _RendererMode.inline:
        return Icons.open_in_full_rounded;
      case _RendererMode.expanded:
        return Icons.fullscreen_rounded;
      case _RendererMode.fullscreen:
        return Icons.close_fullscreen_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final isFullscreen = _rendererMode == _RendererMode.fullscreen && _rendererVisible;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: isFullscreen ? _buildFullscreenLayout(isDark, topPadding) : _buildNormalLayout(isDark, topPadding),
    );
  }

  // ── FULLSCREEN LAYOUT ──
  Widget _buildFullscreenLayout(bool isDark, double topPadding) {
    return Stack(
      children: [
        // Renderer fills screen
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: InAppWebView(
            initialFile: "assets/visual_engine/index.html",
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              allowFileAccessFromFileURLs: true,
              allowUniversalAccessFromFileURLs: true,
              allowFileAccess: true,
              domStorageEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              transparentBackground: true,
            ),
            onWebViewCreated: (c) => _webController = c,
            onLoadStop: (c, url) {
              _webViewReady = true;
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_currentTopic != null && mounted) {
                  c.evaluateJavascript(
                    source:
                        "if(typeof loadScene!=='undefined') loadScene('${_currentTopic!.scene}')",
                  );
                }
              });
            },
          ),
        ),

        // Top bar overlay
        Positioned(
          top: topPadding + 8,
          left: 12,
          right: 12,
          child: Row(
            children: [
              // Scene label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentTopic?.title ?? 'Scene',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const Spacer(),
              // Close fullscreen
              _OverlayButton(
                icon: Icons.close_rounded,
                onTap: () {
                  setState(() {
                    _rendererMode = _RendererMode.inline;
                  });
                },
                isDark: true,
              ),
            ],
          ),
        ),

        // Bottom controls overlay
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._getQuickButtons(true),
              const SizedBox(height: 8),
              _OverlayButton(
                icon: _audioMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                onTap: _toggleSound,
                isDark: true,
              ),
              const SizedBox(height: 8),
              _OverlayButton(
                icon: Icons.restart_alt_rounded,
                onTap: () => runJS("resetCamera()"),
                isDark: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── NORMAL LAYOUT ──
  Widget _buildNormalLayout(bool isDark, double topPadding) {
    return Column(
      children: [
        SizedBox(height: topPadding),

        // ── Top bar ──
        _buildTopBar(isDark),

        // ── Timeline ──
        TimelineBar(
          currentStep: _timelineStep,
          totalSteps: _steps.length,
          onStepTap: _onTimelineStep,
          stepTitles: _steps.map((s) => s['title']!).toList(),
        ),

        // ── Main content ──
        Expanded(
          child: Column(
            children: [
              // ── Renderer (adaptive) ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _rendererHeight,
                child: _rendererVisible
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(16)),
                            child: InAppWebView(
                              initialFile:
                                  "assets/visual_engine/index.html",
                              initialSettings: InAppWebViewSettings(
                                javaScriptEnabled: true,
                                allowFileAccessFromFileURLs: true,
                                allowUniversalAccessFromFileURLs: true,
                                allowFileAccess: true,
                                domStorageEnabled: true,
                                mediaPlaybackRequiresUserGesture: false,
                                transparentBackground: true,
                              ),
                              onWebViewCreated: (c) =>
                                  _webController = c,
                              onLoadStop: (c, url) {
                                _webViewReady = true;
                                Future.delayed(
                                    const Duration(milliseconds: 500),
                                    () {
                                  if (_currentTopic != null && mounted) {
                                    c.evaluateJavascript(
                                      source:
                                          "if(typeof loadScene!=='undefined') loadScene('${_currentTopic!.scene}')",
                                    );
                                  }
                                });
                              },
                            ),
                          ),

                          // Renderer overlay controls
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ..._getQuickButtons(isDark),
                                const SizedBox(width: 4),
                                // Sound toggle
                                _OverlayButton(
                                  icon: _audioMuted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  onTap: _toggleSound,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 4),
                                _OverlayButton(
                                  icon: _rendererSizeIcon,
                                  onTap: _cycleRendererMode,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),

                          // Scene label
                          Positioned(
                            left: 12,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _currentTopic?.title ?? 'Scene',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Conversation area ──
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _session?.messages.length ?? 0,
                  itemBuilder: (context, index) {
                    return MessageBubble(
                        message: _session!.messages[index],
                        onFollowUpTap: _onFollowUpTap);
                  },
                ),
              ),

              // ── Object facts strip ──
              if (_currentTopic != null) _buildFactStrip(isDark),

              // ── Input bar ──
              _buildInputBar(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Kalvin avatar image
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/avatars/leftideal.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentTopic?.title ?? 'Kalvin Studio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1C20),
                  ),
                ),
                Text(
                  _aiThinking
                      ? 'Kalvin is thinking...'
                      : (_aiInitialized && _core.llmAvailable.value
                          ? 'AI Ready • Step ${_timelineStep + 1} of ${_steps.length}'
                          : 'Step ${_timelineStep + 1} of ${_steps.length}'),
                  style: TextStyle(
                    fontSize: 11,
                    color: _aiThinking
                        ? AppColors.primaryOrange
                        : AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Visual toggle button
          GestureDetector(
            onTap: _toggleRendererVisibility,
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _rendererVisible
                    ? AppColors.primaryBlue.withValues(alpha: 0.12)
                    : (isDark ? AppColors.darkCard : AppColors.grey100),
                borderRadius: BorderRadius.circular(8),
                border: _rendererVisible
                    ? Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3))
                    : null,
              ),
              child: Icon(
                _rendererVisible
                    ? Icons.view_in_ar_rounded
                    : Icons.view_in_ar_outlined,
                size: 16,
                color: _rendererVisible
                    ? AppColors.primaryBlue
                    : AppColors.grey400,
              ),
            ),
          ),

          // New Chat button
          GestureDetector(
            onTap: _startNewChat,
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add_rounded,
                  size: 18, color: AppColors.primaryOrange),
            ),
          ),

          // Reset camera
          GestureDetector(
            onTap: () => runJS("resetCamera()"),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.restart_alt_rounded,
                  size: 16, color: AppColors.grey400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactStrip(bool isDark) {
    final objects =
        SceneMetadata.getObjects(_currentTopic?.scene ?? '');
    if (objects.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        physics: const BouncingScrollPhysics(),
        children: objects.map((obj) {
          return GestureDetector(
            onTap: () => _showFactsFor(obj),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome,
                      size: 12, color: AppColors.primaryOrange),
                  const SizedBox(width: 4),
                  Text(
                    obj[0].toUpperCase() + obj.substring(1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.grey300 : AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.mic_none_rounded),
              color: AppColors.primaryOrange,
              iconSize: 20,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.image_outlined),
              color: AppColors.grey400,
              iconSize: 20,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark ? Colors.white : const Color(0xFF1A1C20),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask Kalvin anything...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey400,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.darkElevated : AppColors.grey100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.arrow_upward_rounded),
                color: Colors.white,
                iconSize: 16,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSound() {
    setState(() => _audioMuted = !_audioMuted);
    runJS("toggleAudio()");
    KalvinToast.show(context,
        message: _audioMuted ? '🔇 Sound muted' : '🔊 Sound on',
        type: ToastType.info);
  }

  List<Widget> _getQuickButtons(bool isDark) {
    final scene = _currentTopic?.scene ?? 'solar_system';
    switch (scene) {
      case 'volcano':
        return [
          _OverlayButton(
            icon: Icons.local_fire_department_rounded,
            onTap: () {
              runJS("triggerEruption()");
              KalvinToast.show(context,
                  message: '🌋 Eruption triggered!',
                  type: ToastType.warning);
            },
            isDark: isDark,
            isAccent: true,
          ),
        ];
      default:
        return [];
    }
  }
}

enum _RendererMode { inline, expanded, fullscreen }

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isAccent;

  const _OverlayButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isAccent
              ? AppColors.primaryOrange.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
