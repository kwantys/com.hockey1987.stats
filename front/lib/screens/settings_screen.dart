import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../models/user_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefsService = PreferencesService();

  // Використовуємо початкові значення з вашої моделі
  UserPreferences _prefs = const UserPreferences();
  bool _isLoading = true;

  // Кольори та стилі додатка
  final Color _textColor = const Color(0xFF0F265C);
  final Color _headerColor = const Color(0xFF8ACEF2);
  final Color _bgColor = const Color(0xFFE8F4F8);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Завантажуємо налаштування через ваш сервіс
    final prefs = await _prefsService.loadPreferences();
    if (mounted) {
      setState(() {
        _prefs = prefs;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(UserPreferences newPrefs) async {
    setState(() => _prefs = newPrefs);
    // Зберігаємо оновлені налаштування
    await _prefsService.savePreferences(newPrefs);
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
          // Реальний перемикач з вашої моделі
          _buildToggleTile('Goal alerts', _prefs.goalAlertsEnabled, (v) {
            _updateSetting(_prefs.copyWith(goalAlertsEnabled: v));
          }),
          const Divider(height: 1),
          // Заглушки за запитом
          _buildToggleTile('Final score alerts', false, (v) {}),
          const Divider(height: 1),
          _buildToggleTile('Prediction reminders', true, (v) {}),
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
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Lato'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Встановлюємо перший запуск у true для скидання
                await _updateSetting(_prefs.copyWith(isFirstLaunch: true));

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
            onTap: () {}, // Заглушка
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Terms of Service', style: TextStyle(color: Colors.blue, fontFamily: 'Lato')),
            onTap: () {}, // Заглушка
          ),
        ],
      ),
    );
  }
}