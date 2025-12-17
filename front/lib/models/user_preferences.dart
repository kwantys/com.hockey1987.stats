import 'dart:convert';

/// Модель для збереження налаштувань користувача
class UserPreferences {
  final bool isFirstLaunch;
  final String defaultGameDay; // 'today', 'lastnight', 'tomorrow'
  final bool goalAlertsEnabled;
  final String homeFocus; // 'teams', 'games', 'predictions'

  const UserPreferences({
    this.isFirstLaunch = true,
    this.defaultGameDay = 'today',
    this.goalAlertsEnabled = true,
    this.homeFocus = 'games',
  });

  /// Створити копію з новими значеннями
  UserPreferences copyWith({
    bool? isFirstLaunch,
    String? defaultGameDay,
    bool? goalAlertsEnabled,
    String? homeFocus,
  }) {
    return UserPreferences(
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      defaultGameDay: defaultGameDay ?? this.defaultGameDay,
      goalAlertsEnabled: goalAlertsEnabled ?? this.goalAlertsEnabled,
      homeFocus: homeFocus ?? this.homeFocus,
    );
  }

  /// Конвертувати в JSON
  Map<String, dynamic> toJson() {
    return {
      'isFirstLaunch': isFirstLaunch,
      'defaultGameDay': defaultGameDay,
      'goalAlertsEnabled': goalAlertsEnabled,
      'homeFocus': homeFocus,
    };
  }

  /// Створити з JSON
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      isFirstLaunch: json['isFirstLaunch'] as bool? ?? true,
      defaultGameDay: json['defaultGameDay'] as String? ?? 'today',
      goalAlertsEnabled: json['goalAlertsEnabled'] as bool? ?? true,
      homeFocus: json['homeFocus'] as String? ?? 'games',
    );
  }

  /// Конвертувати в String для збереження
  String toJsonString() => jsonEncode(toJson());

  /// Створити з String
  factory UserPreferences.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserPreferences.fromJson(json);
  }

  @override
  String toString() {
    return 'UserPreferences(isFirstLaunch: $isFirstLaunch, '
        'defaultGameDay: $defaultGameDay, '
        'goalAlertsEnabled: $goalAlertsEnabled, '
        'homeFocus: $homeFocus)';
  }
}