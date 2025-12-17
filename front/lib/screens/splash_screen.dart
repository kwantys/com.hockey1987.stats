import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentImageIndex = 0;
  Timer? _imageTimer;

  // Два зображення для анімації
  final List<String> _loadingImages = [
    'assets/images/loading_1.webp',
    'assets/images/loading_2.webp',
  ];

  @override
  void initState() {
    super.initState();

    // Ініціалізація контролера анімації
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Таймер для зміни зображень
    _imageTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _loadingImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _imageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Простір зверху
              const Spacer(flex: 2),

              // Анімоване зображення завантаження
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Image.asset(
                  _loadingImages[_currentImageIndex],
                  key: ValueKey<int>(_currentImageIndex),
                  width: 70,
                  height: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Якщо зображення не завантажилося, показуємо іконку
                    return Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade100,
                      ),
                      child: Icon(
                        Icons.sports_hockey,
                        size: 35,
                        color: Colors.blue.shade700,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Текст "Loading..." з анімацією
              FadeTransition(
                opacity: _animationController,
                child: const Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F265C),
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // Простір знизу
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}