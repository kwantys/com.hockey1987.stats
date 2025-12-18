import 'dart:convert';

/// Модель для збереження налаштувань користувача
class UserPreferences {
  final bool isFirstLaunch;
  final String defaultGameDay; // 'today', 'lastnight', 'tomorrow'
  final String homeFocus; // 'teams', 'games', 'predictions'

  // Нові поля для сповіщень
  final bool goalAlerts;
  final bool finalScoreAlerts;
  final bool predictionReminders;

  const UserPreferences({
    this.isFirstLaunch = true,
    this.defaultGameDay = 'today',
    this.homeFocus = 'games',
    this.goalAlerts = true,
    this.finalScoreAlerts = true,
    this.predictionReminders = true,
  });

  /// Створити копію з новими значеннями (ВИПРАВЛЕНО: додано нові поля)
  UserPreferences copyWith({
    bool? isFirstLaunch,
    String? defaultGameDay,
    String? homeFocus,
    bool? goalAlerts,
    bool? finalScoreAlerts,
    bool? predictionReminders,
  }) {
    return UserPreferences(
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      defaultGameDay: defaultGameDay ?? this.defaultGameDay,
      homeFocus: homeFocus ?? this.homeFocus,
      goalAlerts: goalAlerts ?? this.goalAlerts,
      finalScoreAlerts: finalScoreAlerts ?? this.finalScoreAlerts,
      predictionReminders: predictionReminders ?? this.predictionReminders,
    );
  }

  /// Конвертувати в JSON (ВИПРАВЛЕНО: додано нові поля для збереження)
  Map<String, dynamic> toJson() {
    return {
      'isFirstLaunch': isFirstLaunch,
      'defaultGameDay': defaultGameDay,
      'homeFocus': homeFocus,
      'goalAlerts': goalAlerts,
      'finalScoreAlerts': finalScoreAlerts,
      'predictionReminders': predictionReminders,
    };
  }

  /// Створити з JSON (ВИПРАВЛЕНО: додано нові поля для завантаження)
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      isFirstLaunch: json['isFirstLaunch'] as bool? ?? true,
      defaultGameDay: json['defaultGameDay'] as String? ?? 'today',
      homeFocus: json['homeFocus'] as String? ?? 'games',
      goalAlerts: json['goalAlerts'] as bool? ?? true,
      finalScoreAlerts: json['finalScoreAlerts'] as bool? ?? true,
      predictionReminders: json['predictionReminders'] as bool? ?? true,
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
        'goalAlerts: $goalAlerts, '
        'finalScoreAlerts: $finalScoreAlerts, '
        'predictionReminders: $predictionReminders, '
        'homeFocus: $homeFocus)';
  }
}