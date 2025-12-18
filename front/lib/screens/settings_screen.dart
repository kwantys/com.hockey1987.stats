import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../models/user_preferences.dart';
import '../shared/services/logger.dart'; //

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefsService = PreferencesService();

  UserPreferences _prefs = const UserPreferences();
  bool _isLoading = true;

  final Color _textColor = const Color(0xFF0F265C);
  final Color _headerColor = const Color(0xFF8ACEF2);
  final Color _bgColor = const Color(0xFFE8F4F8);

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
    // Вимога п. 11 гайду: кожна зміна логується через AppLogger
    AppLogger.i('User preference updated: $settingName = $value'); //
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
          // 1. Goal Alerts
          _buildToggleTile('Goal alerts', _prefs.goalAlerts, (v) {
            _updateSetting(_prefs.copyWith(goalAlerts: v), 'goalAlerts', v);
          }),
          const Divider(height: 1),

          // 2. Final Score Alerts (підключено до моделі)
          _buildToggleTile('Final score alerts', _prefs.finalScoreAlerts, (v) {
            _updateSetting(_prefs.copyWith(finalScoreAlerts: v), 'finalScoreAlerts', v);
          }),
          const Divider(height: 1),

          // 3. Prediction Reminders (підключено до моделі)
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