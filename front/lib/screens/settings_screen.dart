import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/preferences_service.dart';
import '../services/notification_permission_service.dart';
import '../models/user_preferences.dart';
import '../widgets/notification_permission_dialogs.dart';
import '../shared/services/logger.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final PreferencesService _prefsService = PreferencesService();

  UserPreferences _prefs = const UserPreferences();
  bool _isLoading = true;
  bool _waitingForSettingsReturn = false;

  final Color _textColor = const Color(0xFF0F265C);
  final Color _headerColor = const Color(0xFF8ACEF2);
  final Color _bgColor = const Color(0xFFE8F4F8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForSettingsReturn) {
      _waitingForSettingsReturn = false;
      _recheckNotificationPermission();
    }
  }

  Future<void> _recheckNotificationPermission() async {
    final isGranted = await NotificationPermissionService.isGranted();
    AppLogger.d('Re-checking notification permission: granted=$isGranted');

    if (!isGranted && (_prefs.goalAlerts || _prefs.finalScoreAlerts)) {
      // Permission was revoked but toggles are ON - disable them
      final newPrefs = _prefs.copyWith(
        goalAlerts: false,
        finalScoreAlerts: false,
      );
      setState(() => _prefs = newPrefs);
      await _prefsService.savePreferences(newPrefs);
      AppLogger.w('Notification permission revoked - disabled notification toggles');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefsService.loadPreferences();
    if (mounted) {
      setState(() {
        _prefs = prefs;
        _isLoading = false;
      });
      AppLogger.d('Settings loaded successfully'); //
    }
  }

  // Оновлений метод для збереження з логуванням
  Future<void> _updateSetting(UserPreferences newPrefs, String settingName, dynamic value) async {
    setState(() => _prefs = newPrefs);
    await _prefsService.savePreferences(newPrefs);
    AppLogger.i('User preference updated: $settingName = $value');
  }

  /// Handle notification toggle change with permission check.
  /// Only used for goalAlerts and finalScoreAlerts toggles.
  Future<void> _handleNotificationToggle(String settingName, bool newValue) async {
    // If turning OFF, no permission check needed
    if (!newValue) {
      final newPrefs = settingName == 'goalAlerts'
          ? _prefs.copyWith(goalAlerts: false)
          : _prefs.copyWith(finalScoreAlerts: false);
      await _updateSetting(newPrefs, settingName, false);
      return;
    }

    // Turning ON - check if permission is already granted
    final status = await NotificationPermissionService.checkStatus();

    if (status.isGranted) {
      // Permission already granted - enable toggle
      final newPrefs = settingName == 'goalAlerts'
          ? _prefs.copyWith(goalAlerts: true)
          : _prefs.copyWith(finalScoreAlerts: true);
      await _updateSetting(newPrefs, settingName, true);
      return;
    }

    if (status.isPermanentlyDenied) {
      // Permanently denied - show settings dialog
      AppLogger.w('Notification permission permanently denied');
      if (mounted) {
        final openedSettings = await showPermanentlyDeniedDialog(context);
        if (openedSettings) {
          _waitingForSettingsReturn = true;
        }
      }
      return;
    }

    // Permission not yet requested or denied - show rationale and request
    if (mounted) {
      final userChoice = await showNotificationRationale(context);
      if (userChoice != true) {
        // User chose "Not Now"
        AppLogger.i('User declined notification permission in settings');
        return;
      }

      // Request permission
      final result = await NotificationPermissionService.requestPermission();

      if (result.isGranted) {
        // Permission granted - enable toggle
        final newPrefs = settingName == 'goalAlerts'
            ? _prefs.copyWith(goalAlerts: true)
            : _prefs.copyWith(finalScoreAlerts: true);
        await _updateSetting(newPrefs, settingName, true);
      } else if (result.isPermanentlyDenied && mounted) {
        // Permanently denied after request - show settings dialog
        final openedSettings = await showPermanentlyDeniedDialog(context);
        if (openedSettings) {
          _waitingForSettingsReturn = true;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF0F265C),
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        centerTitle: true,
        backgroundColor: _headerColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _textColor),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Notifications'),
            _buildNotificationToggles(),

            const SizedBox(height: 24),
            _buildSectionTitle('Maintenance'),
            _buildOnboardingSection(),

            const SizedBox(height: 24),
            _buildSectionTitle('About'),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B9EB8),
          letterSpacing: 1.2,
          fontFamily: 'Lato',
        ),
      ),
    );
  }

  Widget _buildNotificationToggles() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Column(
        children: [
          // 1. Goal Alerts - requires permission check
          _buildToggleTile('Goal alerts', _prefs.goalAlerts, (v) {
            _handleNotificationToggle('goalAlerts', v);
          }),
          const Divider(height: 1),

          // 2. Final Score Alerts - requires permission check
          _buildToggleTile('Final score alerts', _prefs.finalScoreAlerts, (v) {
            _handleNotificationToggle('finalScoreAlerts', v);
          }),
          const Divider(height: 1),

          // 3. Prediction Reminders - no permission check (no background notifications)
          _buildToggleTile('Prediction reminders', _prefs.predictionReminders, (v) {
            _updateSetting(_prefs.copyWith(predictionReminders: v), 'predictionReminders', v);
          }),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(
          title,
          style: TextStyle(fontFamily: 'Lato', color: _textColor, fontWeight: FontWeight.w500)
      ),
      value: value,
      onChanged: onChanged,
      activeColor: _textColor,
    );
  }

  Widget _buildOnboardingSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ListTile(
        title: const Text(
          'Reset Application',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        subtitle: const Text(
          'This will re-run the onboarding process',
          style: TextStyle(fontFamily: 'Lato', fontSize: 13),
        ),
        trailing: const Icon(Icons.refresh, color: Colors.red),
        onTap: () => _showResetConfirmation(context),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    // Використання діалогу згідно з паттерном п. 8.1 гайду
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Reset App?',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          content: const Text(
            'Are you sure you want to reset the app? This will start the onboarding process on the next launch.',
            style: TextStyle(fontFamily: 'Lato', fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                AppLogger.d('Reset cancelled'); //
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Lato'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                AppLogger.w('User initiated application reset'); //
                await _updateSetting(_prefs.copyWith(isFirstLaunch: true), 'isFirstLaunch', true);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('App will reset on next launch'),
                      backgroundColor: _textColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Reset',
                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lato'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Column(
        children: [
          const ListTile(
            title: Text('Version', style: TextStyle(fontFamily: 'Lato')),
            trailing: Text('1.0.0', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lato')),
          ),
          const Divider(height: 1),
          const ListTile(
            title: Text('Data source', style: TextStyle(fontFamily: 'Lato')),
            trailing: Text('NHL Stats API', style: TextStyle(fontFamily: 'Lato')),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Privacy Policy', style: TextStyle(color: Colors.blue, fontFamily: 'Lato')),
            onTap: () => AppLogger.d('Privacy Policy tapped'), //
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Terms of Service', style: TextStyle(color: Colors.blue, fontFamily: 'Lato')),
            onTap: () => AppLogger.d('Terms of Service tapped'), //
          ),
        ],
      ),
    );
  }
}