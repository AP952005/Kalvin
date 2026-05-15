import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/model_setup_screen.dart';
import 'screens/main_navigation.dart';
import 'ai/local_model_manager.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const KalvinApp());
}

class KalvinApp extends StatefulWidget {
  const KalvinApp({super.key});

  @override
  State<KalvinApp> createState() => _KalvinAppState();
}

class _KalvinAppState extends State<KalvinApp> {
  bool isDarkMode = true;
  bool _setupComplete = false;
  bool _checkingSetup = true;

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final exists = await LocalModelManager.isModelExtracted();
    if (mounted) {
      setState(() {
        _setupComplete = exists;
        _checkingSetup = false;
      });
    }
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSetup) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          backgroundColor: Color(0xFF0F1728),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kalvin',
      theme: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: !_setupComplete 
        ? ModelSetupScreen(onComplete: () => setState(() => _setupComplete = true))
        : MainNavigation(
            isDarkMode: isDarkMode,
            onToggleTheme: toggleTheme,
          ),
    );
  }
}
