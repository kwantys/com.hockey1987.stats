import 'package:flutter/material.dart';
import '../models/user_preferences.dart';
import '../services/preferences_service.dart';
import '../widgets/main_navigation.dart';
import '../shared/services/logger.dart'; // Додано логер згідно з гайдом

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final PreferencesService _preferencesService = PreferencesService();

  int _currentPage = 0;

  // Налаштування для третього слайду
  String _selectedGameDay = 'today';
  bool _goalAlertsEnabled = true;
  String _selectedHomeFocus = 'games';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ВІКНО ПОЯСНЕННЯ ДОСТУПУ (Стилізоване під додаток)
  Future<void> _showPermissionExplanation() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.notifications_active, size: 48, color: Color(0xFF0F265C)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Stay in the Game',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'RinkSync needs notification access to send you real-time goal alerts, game starts, and final scores for your favorite teams.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F265C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'I Understand',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding({bool useDefaults = false}) async {
    // Якщо користувач увімкнув сповіщення, показуємо пояснення перед завершенням
    if (!useDefaults && _goalAlertsEnabled) {
      await _showPermissionExplanation();
    }

    // Зберігаємо налаштування (ВИПРАВЛЕНО: назва параметра goalAlerts)
    final preferences = UserPreferences(
      isFirstLaunch: false,
      defaultGameDay: useDefaults ? 'today' : _selectedGameDay,
      goalAlerts: useDefaults ? true : _goalAlertsEnabled, // Виправлено помилку іменування
      homeFocus: useDefaults ? 'games' : _selectedHomeFocus,
    );

    await _preferencesService.savePreferences(preferences);
    AppLogger.i('Onboarding completed. Settings: $preferences'); // Логування згідно з гайдом

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (_currentPage < 2)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => _completeOnboarding(useDefaults: true),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: Color(0xFF0F265C),
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 48),

            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildSlide1(),
                  _buildSlide2(),
                  _buildSlide3(),
                ],
              ),
            ),

            _buildPageIndicators(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide1() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Image.asset(
              'assets/images/onboarding_1.webp',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.sports_hockey,
                    size: 100,
                    color: Colors.blue.shade300,
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Never Miss a Drop',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F265C),
                    fontFamily: 'Lato',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Track live scores, play-by-play updates, and boxscores from one place.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    fontFamily: 'Lato',
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F265C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlide2() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Image.asset(
              'assets/images/onboarding_2.webp',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    size: 100,
                    color: Colors.blue.shade300,
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Turn Stats into Insight',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F265C),
                    fontFamily: 'Lato',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Use Outcome Studio to test your predictions and build your streak.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    fontFamily: 'Lato',
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F265C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlide3() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 280,
            padding: const EdgeInsets.all(40),
            child: Image.asset(
              'assets/images/onboarding_3.webp',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 100,
                    color: Colors.blue.shade300,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Make RinkSync Yours',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F265C),
                      fontFamily: 'Lato',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Set how you want to browse games and alerts.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                      fontFamily: 'Lato',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Goal alerts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F265C),
                          fontFamily: 'Lato',
                        ),
                      ),
                      Switch(
                        value: _goalAlertsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _goalAlertsEnabled = value;
                          });
                        },
                        activeColor: const Color(0xFF0F265C),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Default game day',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F265C),
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildGameDayChip('Today', 'today'),
                    const SizedBox(width: 12),
                    _buildGameDayChip('Last night', 'lastnight'),
                    const SizedBox(width: 12),
                    _buildGameDayChip('Tomorrow', 'tomorrow'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Home focus',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F265C),
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildHomeFocusChip('Teams', 'teams'),
                    const SizedBox(width: 12),
                    _buildHomeFocusChip('Games', 'games'),
                    const SizedBox(width: 12),
                    _buildHomeFocusChip('Predictions', 'predictions'),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _completeOnboarding(useDefaults: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F265C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Jump in',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: () => _completeOnboarding(useDefaults: true),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0F265C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameDayChip(String label, String value) {
    final isSelected = _selectedGameDay == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGameDay = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F265C)
                : const Color(0xFF93C3DD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeFocusChip(String label, String value) {
    final isSelected = _selectedHomeFocus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedHomeFocus = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F265C)
                : const Color(0xFF93C3DD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFF0F265C)
                : const Color(0xFFE8F0FE),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}