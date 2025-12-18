import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/main_navigation.dart';
import 'services/preferences_service.dart';
import 'services/notification_service.dart'; // ДОДАНО
import 'shared/services/logger.dart'; // ДОДАНО згідно з гайдом

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Ініціалізація сервісу сповіщень (Workmanager)
  // Це обов'язково зробити до запуску runApp
  await NotificationService.init();
  AppLogger.i('App started and NotificationService initialized');

  // Lock to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NHL Stats',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F265C)),
        useMaterial3: true,
        fontFamily: 'Lato',
      ),
      home: const AppInitializer(),
    );
  }
}

/// Ініціалізатор додатку - показує Splash Screen, потім вирішує куди направити
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final PreferencesService _preferencesService = PreferencesService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Показуємо Splash Screen 3 секунди
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Перевіряємо чи це перший запуск
    try {
      final isFirstLaunch = await _preferencesService.isFirstLaunch();
      AppLogger.d('Check first launch: $isFirstLaunch');

      if (!mounted) return;

      if (isFirstLaunch) {
        // Перший запуск - показуємо onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        // Не перший запуск - переходимо на MainNavigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e, stack) {
      AppLogger.e('Failed to initialize app state', e, stack);
      // У разі помилки все одно намагаємося відкрити головний екран
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}