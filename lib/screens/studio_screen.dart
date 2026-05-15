import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../theme/app_colors.dart';
import '../models/topic.dart';
import '../widgets/assistant_avatar.dart';
import '../widgets/step_panel.dart';
import '../widgets/kalvin_toast.dart';

class StudioScreen extends StatefulWidget {
  final Topic? activeTopic;

  const StudioScreen({super.key, this.activeTopic});

  @override
  State<StudioScreen> createState() => StudioScreenState();
}

class StudioScreenState extends State<StudioScreen> {
  InAppWebViewController? _webController;
  final TextEditingController _inputController = TextEditingController();
  Topic? _currentTopic;
  bool _webViewReady = false;

  // Layout state: visualization fraction (0.0 to 1.0)
  double _vizFraction = 0.6;
  static const double _minViz = 0.15;
  static const double _maxViz = 0.9;

  // Educational content per scene
  static const Map<String, List<Map<String, String>>> _sceneSteps = {
    'solar_system': [
      {
        'title': 'Observe the Solar System',
        'content':
            'The Sun sits at the center of our solar system. Earth orbits around it, held by gravity. Rotate the view to explore from different angles!'
      },
      {
        'title': 'The Sun — Our Star',
        'content':
            'A massive ball of hydrogen and helium undergoing nuclear fusion. Its surface temperature reaches 5,500°C, and it contains 99.8% of the solar system\'s mass.'
      },
      {
        'title': 'The Earth — Our Home',
        'content':
            'Earth orbits the Sun at ~150 million km (1 AU). Its thin nitrogen-oxygen atmosphere and magnetic field protect all known life. Notice the blue atmosphere glow.'
      },
    ],
    'volcano': [
      {
        'title': 'Volcanic Formation',
        'content':
            'Volcanoes form at tectonic plate boundaries where magma from the mantle reaches the surface. The cone shape is built from layers of hardened lava and ash.'
      },
      {
        'title': 'Inside the Volcano',
        'content':
            'Beneath the crater lies a magma chamber filled with molten rock at 700–1300°C. Gas pressure builds until the magma erupts violently through the vent.'
      },
      {
        'title': 'Eruption & Effects',
        'content':
            'During eruption, lava, ash, and volcanic gases are expelled. Pyroclastic flows can travel at 700 km/h. Volcanic ash can affect global climate for years.'
      },
    ],
    'water_cycle': [
      {
        'title': 'The Water Cycle Begins',
        'content':
            'The Sun heats water in oceans, lakes, and rivers. This thermal energy causes water molecules to evaporate — changing from liquid to invisible water vapour.'
      },
      {
        'title': 'Condensation & Cloud Formation',
        'content':
            'As water vapour rises, it cools and condenses around tiny dust particles, forming clouds. Billions of water droplets cluster together to create visible clouds.'
      },
      {
        'title': 'Precipitation & Return',
        'content':
            'When cloud droplets merge and grow heavy enough, they fall as rain, snow, or hail. Water flows through rivers back to the ocean, completing the cycle.'
      },
    ],
  };

  int _activeStep = 0;

  List<Map<String, String>> get _steps {
    return _sceneSteps[_currentTopic?.scene ?? 'solar_system'] ??
        _sceneSteps['solar_system']!;
  }

  @override
  void initState() {
    super.initState();
    _currentTopic = widget.activeTopic ?? Topic.allTopics[0];
  }

  void loadTopic(Topic topic) {
    setState(() {
      _currentTopic = topic;
      _activeStep = 0;
    });
    if (_webViewReady && _webController != null) {
      _webController!.evaluateJavascript(
        source: "loadScene('${topic.scene}')",
      );
    }
  }

  void runJS(String code) {
    _webController?.evaluateJavascript(source: code);
  }

  // Layout presets
  void _setDefaultLayout() => setState(() => _vizFraction = 0.6);
  void _setReadingLayout() => setState(() => _vizFraction = 0.25);
  void _setFullVisualLayout() => setState(() => _vizFraction = 0.9);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height - topPadding - 56;

    // Scene-specific camera buttons
    final sceneButtons = _getSceneButtons();

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: topPadding),

          // ── Top bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentTopic?.title ?? 'Studio',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1A1C20),
                        ),
                      ),
                      Row(
                        children: [
                          // Progress dots
                          ...List.generate(_steps.length, (i) {
                            return Container(
                              margin: const EdgeInsets.only(right: 4, top: 4),
                              width: i == _activeStep ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _activeStep
                                    ? AppColors.primaryBlue
                                    : (i < _activeStep
                                        ? AppColors.success
                                        : AppColors.grey400.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '${_activeStep + 1}/${_steps.length}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.grey400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Layout toggle buttons
                _LayoutButton(
                  icon: Icons.vertical_split_rounded,
                  onTap: _setDefaultLayout,
                  isActive: (_vizFraction - 0.6).abs() < 0.05,
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _LayoutButton(
                  icon: Icons.chrome_reader_mode_rounded,
                  onTap: _setReadingLayout,
                  isActive: _vizFraction < 0.3,
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _LayoutButton(
                  icon: Icons.fullscreen_rounded,
                  onTap: _setFullVisualLayout,
                  isActive: _vizFraction > 0.85,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // ── Camera controls strip ──
          Container(
            height: 34,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: sceneButtons.map((btn) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _CameraButton(
                    icon: btn['icon'] as IconData,
                    label: btn['label'] as String,
                    onTap: btn['onTap'] as VoidCallback,
                    isDark: isDark,
                    isAccent: btn['accent'] == true,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 6),

          // ── Draggable split: Visualization + Study panel ──
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalH = constraints.maxHeight;
                final vizH = (totalH * _vizFraction).clamp(
                  totalH * _minViz,
                  totalH * _maxViz,
                );

                return Column(
                  children: [
                    // ── 3D Visualization ──
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      height: vizH,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
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
                              onWebViewCreated: (controller) {
                                _webController = controller;
                              },
                              onLoadStop: (controller, url) {
                                _webViewReady = true;
                                // Load the current topic's scene
                                if (_currentTopic != null) {
                                  controller.evaluateJavascript(
                                    source:
                                        "loadScene('${_currentTopic!.scene}')",
                                  );
                                }
                              },
                            ),
                          ),
                          // Floating Kalvin avatar
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: AssistantAvatar(
                              size: 46,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Drag handle ──
                    GestureDetector(
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          _vizFraction += details.delta.dy / totalH;
                          _vizFraction = _vizFraction.clamp(_minViz, _maxViz);
                        });
                      },
                      child: Container(
                        height: 24,
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.grey400.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Educational Step Panel ──
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.only(
                                    top: 8, bottom: 8),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _steps.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _activeStep = index);
                                    },
                                    child: StepPanel(
                                      title: _steps[index]['title']!,
                                      content: _steps[index]['content']!,
                                      stepNumber: index + 1,
                                      isActive: index == _activeStep,
                                    ),
                                  );
                                },
                              ),
                            ),
                            // ── Input bar ──
                            _buildInputBar(isDark),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
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
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.image_outlined),
              color: AppColors.grey400,
              iconSize: 20,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _inputController,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1A1C20),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask Kalvin...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () {
                  _inputController.clear();
                },
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

  List<Map<String, dynamic>> _getSceneButtons() {
    final scene = _currentTopic?.scene ?? 'solar_system';

    switch (scene) {
      case 'volcano':
        return [
          {
            'icon': Icons.terrain,
            'label': 'Mountain',
            'onTap': () => runJS("focusMountain()"),
          },
          {
            'icon': Icons.local_fire_department_rounded,
            'label': 'Eruption',
            'onTap': () {
              runJS("triggerEruption()");
              KalvinToast.show(context,
                  message: '🌋 Eruption triggered!',
                  type: ToastType.warning);
            },
            'accent': true,
          },
          {
            'icon': Icons.restart_alt_rounded,
            'label': 'Reset',
            'onTap': () => runJS("resetCamera()"),
          },
        ];
      case 'water_cycle':
        return [
          {
            'icon': Icons.wb_sunny_rounded,
            'label': 'Sun',
            'onTap': () => runJS("focusSun()"),
          },
          {
            'icon': Icons.water,
            'label': 'Ocean',
            'onTap': () => runJS("focusOcean()"),
          },
          {
            'icon': Icons.restart_alt_rounded,
            'label': 'Reset',
            'onTap': () => runJS("resetCamera()"),
          },
        ];
      default: // solar_system
        return [
          {
            'icon': Icons.public,
            'label': 'Earth',
            'onTap': () => runJS("focusEarth()"),
          },
          {
            'icon': Icons.wb_sunny_rounded,
            'label': 'Sun',
            'onTap': () => runJS("focusSun()"),
          },
          {
            'icon': Icons.restart_alt_rounded,
            'label': 'Reset',
            'onTap': () => runJS("resetCamera()"),
          },
        ];
    }
  }
}

class _CameraButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isAccent;

  const _CameraButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: isAccent ? AppColors.orangeGradient : null,
          color: isAccent
              ? null
              : (isDark ? AppColors.darkCard : AppColors.grey100),
          borderRadius: BorderRadius.circular(8),
          border: isAccent
              ? null
              : Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: isAccent ? Colors.white : AppColors.primaryBlue),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isAccent
                    ? Colors.white
                    : (isDark ? AppColors.grey300 : AppColors.grey600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDark;

  const _LayoutButton({
    required this.icon,
    required this.onTap,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryBlue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? AppColors.primaryBlue : AppColors.grey400,
        ),
      ),
    );
  }
}
