import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_preferences.dart';
import '../services/preferences_service.dart';
import '../services/notification_permission_service.dart';
import '../widgets/main_navigation.dart';
import '../widgets/notification_permission_dialogs.dart';
import '../shared/services/logger.dart';

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

  /// Handle notification permission request flow.
  /// Returns true if permission was granted, false otherwise.
  Future<bool> _requestNotificationPermission() async {
    // Show rationale dialog first
    final userChoice = await showNotificationRationale(context);

    if (userChoice != true) {
      // User chose "Not Now" or dismissed
      AppLogger.i('User declined notification permission in rationale');
      return false;
    }

    // User chose "Allow" - request actual system permission
    final status = await NotificationPermissionService.requestPermission();

    if (status.isGranted) {
      AppLogger.i('Notification permission granted');
      return true;
    }

    if (status.isPermanentlyDenied) {
      // Show dialog to open settings
      AppLogger.w('Notification permission permanently denied');
      if (mounted) {
        await showPermanentlyDeniedDialog(context);
      }
      return false;
    }

    // Permission denied but not permanently
    AppLogger.i('Notification permission denied');
    return false;
  }

  Future<void> _completeOnboarding({bool useDefaults = false}) async {
    bool goalAlertsEnabled = useDefaults ? true : _goalAlertsEnabled;

    // If user enabled goal alerts, request permission
    if (!useDefaults && _goalAlertsEnabled) {
      final permissionGranted = await _requestNotificationPermission();
      // If permission not granted, disable goal alerts
      if (!permissionGranted) {
        goalAlertsEnabled = false;
      }
    }

    // Save preferences
    final preferences = UserPreferences(
      isFirstLaunch: false,
      defaultGameDay: useDefaults ? 'today' : _selectedGameDay,
      goalAlerts: goalAlertsEnabled,
      homeFocus: useDefaults ? 'games' : _selectedHomeFocus,
    );

    await _preferencesService.savePreferences(preferences);
    AppLogger.i('Onboarding completed. Settings: $preferences');

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