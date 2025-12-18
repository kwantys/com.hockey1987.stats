/// Модель для інсайтів команди
class TeamInsight {
  final int teamId;
  final String teamName;
  final String teamAbbrev;
  final String? teamLogo;

  // Hot streaks data
  final int wins;
  final int losses;
  final int otLosses;
  final int goalDifferential;
  final String streakLabel; // 'On fire', 'Heating up', 'Cooling down'

  // Form tracker data
  final List<double> pointsPerGame;
  final List<int> goalsFor;
  final List<int> goalsAgainst;
  final List<int> shotsFor;
  final List<int> shotsAgainst;

  // Favorites trends data
  final double powerPlayPercent;
  final double penaltyKillPercent;

  const TeamInsight({
    required this.teamId,
    required this.teamName,
    required this.teamAbbrev,
    this.teamLogo,
    required this.wins,
    required this.losses,
    required this.otLosses,
    required this.goalDifferential,
    required this.streakLabel,
    required this.pointsPerGame,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.shotsFor,
    required this.shotsAgainst,
    required this.powerPlayPercent,
    required this.penaltyKillPercent,
  });

  /// Форматований запис (W-L-OTL)
  String get record => '$wins-$losses-$otLosses';

  /// Форматований goal diff з плюсом
  String get goalDiffFormatted {
    if (goalDifferential > 0) return '+$goalDifferential';
    return goalDifferential.toString();
  }

  /// Кольор для streak label
  String get streakColor {
    switch (streakLabel) {
      case 'On fire':
        return '#E74C3C'; // Red
      case 'Heating up':
        return '#F39C12'; // Orange
      case 'Cooling down':
        return '#3498DB'; // Blue
      default:
        return '#95A5A6'; // Gray
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'teamAbbrev': teamAbbrev,
      'teamLogo': teamLogo,
      'wins': wins,
      'losses': losses,
      'otLosses': otLosses,
      'goalDifferential': goalDifferential,
      'streakLabel': streakLabel,
      'pointsPerGame': pointsPerGame,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'shotsFor': shotsFor,
      'shotsAgainst': shotsAgainst,
      'powerPlayPercent': powerPlayPercent,
      'penaltyKillPercent': penaltyKillPercent,
    };
  }

  factory TeamInsight.fromJson(Map<String, dynamic> json) {
    return TeamInsight(
      teamId: json['teamId'] as int,
      teamName: json['teamName'] as String,
      teamAbbrev: json['teamAbbrev'] as String,
      teamLogo: json['teamLogo'] as String?,
      wins: json['wins'] as int,
      losses: json['losses'] as int,
      otLosses: json['otLosses'] as int,
      goalDifferential: json['goalDifferential'] as int,
      streakLabel: json['streakLabel'] as String,
      pointsPerGame: (json['pointsPerGame'] as List).map((e) => (e as num).toDouble()).toList(),
      goalsFor: (json['goalsFor'] as List).map((e) => e as int).toList(),
      goalsAgainst: (json['goalsAgainst'] as List).map((e) => e as int).toList(),
      shotsFor: (json['shotsFor'] as List).map((e) => e as int).toList(),
      shotsAgainst: (json['shotsAgainst'] as List).map((e) => e as int).toList(),
      powerPlayPercent: (json['powerPlayPercent'] as num).toDouble(),
      penaltyKillPercent: (json['penaltyKillPercent'] as num).toDouble(),
    );
  }
}