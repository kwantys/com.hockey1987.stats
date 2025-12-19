/// Модель для команди в турнірній таблиці
class TeamStanding {
  final int teamId;
  final String teamName;
  final String teamAbbrev;
  final String? teamLogo;
  final int divisionId;
  final String divisionName;
  final int conferenceId;
  final String conferenceName;

  // Standings stats
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int overtimeLosses;
  final int points;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifferential;

  // Additional stats
  final int regulationWins; // ROW - для тайбрейкера
  final String last10; // Останні 10 ігор (e.g. "7-2-1")
  final String streak; // Серія (e.g. "W3", "L2")
  final int homeWins;
  final int homeLosses;
  final int homeOT;
  final int awayWins;
  final int awayLosses;
  final int awayOT;

  // Позиція
  final int? divisionRank;
  final int? conferenceRank;
  final int? leagueRank;
  final int? wildCardRank;

  // Статус плей-офф
  final bool clinchIndicator; // Вийшли в плейофф
  final String? playoffStatus; // 'playoff', 'wildcard', 'eliminated', null

  const TeamStanding({
    required this.teamId,
    required this.teamName,
    required this.teamAbbrev,
    this.teamLogo,
    required this.divisionId,
    required this.divisionName,
    required this.conferenceId,
    required this.conferenceName,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
    required this.overtimeLosses,
    required this.points,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifferential,
    required this.regulationWins,
    required this.last10,
    required this.streak,
    this.homeWins = 0,
    this.homeLosses = 0,
    this.homeOT = 0,
    this.awayWins = 0,
    this.awayLosses = 0,
    this.awayOT = 0,
    this.divisionRank,
    this.conferenceRank,
    this.leagueRank,
    this.wildCardRank,
    this.clinchIndicator = false,
    this.playoffStatus,
  });

  /// Створити з JSON (NHL Standings API)
  factory TeamStanding.fromJson(Map<String, dynamic> json) {
    // Витягуємо абревіатуру (це завжди є)
    String teamAbbrev = '';
    if (json['teamAbbrev'] != null) {
      final abbrevData = json['teamAbbrev'];
      teamAbbrev = abbrevData is Map ? (abbrevData['default'] ?? '') : abbrevData.toString();
    }

    // 🔧 FIX: NHL API standings НЕ повертає teamId!
    // Використовуємо мапу abbrev → id
    final Map<String, int> teamIds = {
      'ANA': 24, 'UTA': 59, 'BOS': 6, 'BUF': 7, 'CAR': 12,
      'CBJ': 29, 'CGY': 20, 'CHI': 16, 'COL': 21, 'DAL': 25,
      'DET': 17, 'EDM': 22, 'FLA': 13, 'LAK': 26, 'MIN': 30,
      'MTL': 8, 'NJD': 1, 'NSH': 18, 'NYI': 2, 'NYR': 3,
      'OTT': 9, 'PHI': 4, 'PIT': 5, 'SEA': 55, 'SJS': 28,
      'STL': 19, 'TBL': 14, 'TOR': 10, 'VAN': 23, 'VGK': 54,
      'WPG': 52, 'WSH': 15,
    };

    final teamId = teamIds[teamAbbrev] ?? 0;

    print('📋 Parsing: $teamAbbrev → ID: $teamId');

    // Витягуємо назву команди
    String teamName = '';
    if (json['teamCommonName'] != null) {
      final nameData = json['teamCommonName'];
      teamName = nameData is Map ? (nameData['default'] ?? '') : nameData.toString();
    } else if (json['teamName'] != null) {
      final nameData = json['teamName'];
      teamName = nameData is Map ? (nameData['default'] ?? '') : nameData.toString();
    }

    // Витягуємо статистику
    final gp = json['gamesPlayed'] ?? 0;
    final w = json['wins'] ?? 0;
    final l = json['losses'] ?? 0;
    final otl = json['otLosses'] ?? 0;
    final pts = json['points'] ?? 0;
    final gf = json['goalFor'] ?? json['goalsFor'] ?? 0;
    final ga = json['goalAgainst'] ?? json['goalsAgainst'] ?? 0;
    final diff = json['goalDifferential'] ?? (gf - ga);
    final row = json['regulationWins'] ?? json['row'] ?? 0;

    // Серія та останні 10
    final streakCode = json['streakCode'] ?? '';
    final streakCount = json['streakCount'] ?? 0;
    final streak = streakCount > 0 ? '$streakCode$streakCount' : '';
    final last10Record = json['l10Wins'] != null
        ? '${json['l10Wins']}-${json['l10Losses']}-${json['l10OtLosses']}'
        : '';

    // Division і Conference
    String divisionName = json['divisionName'] ?? '';
    String conferenceName = json['conferenceName'] ?? '';

    // teamLogo - сконструювати з abbrev
    String? teamLogo = json['teamLogo'];
    if (teamLogo == null && teamAbbrev.isNotEmpty) {
      teamLogo = 'https://assets.nhle.com/logos/nhl/svg/${teamAbbrev}_light.svg';
    }

    return TeamStanding(
      teamId: teamId,
      teamName: teamName,
      teamAbbrev: teamAbbrev,
      teamLogo: teamLogo,
      divisionId: json['divisionId'] ?? 0,
      divisionName: divisionName,
      conferenceId: json['conferenceId'] ?? 0,
      conferenceName: conferenceName,
      gamesPlayed: gp,
      wins: w,
      losses: l,
      overtimeLosses: otl,
      points: pts,
      goalsFor: gf,
      goalsAgainst: ga,
      goalDifferential: diff,
      regulationWins: row,
      last10: last10Record,
      streak: streak,
      homeWins: json['homeWins'] ?? 0,
      homeLosses: json['homeLosses'] ?? 0,
      homeOT: json['homeOtLosses'] ?? 0,
      awayWins: json['roadWins'] ?? 0,
      awayLosses: json['roadLosses'] ?? 0,
      awayOT: json['roadOtLosses'] ?? 0,
      divisionRank: json['divisionSequence'],
      conferenceRank: json['conferenceSequence'],
      leagueRank: json['leagueSequence'],
      wildCardRank: json['wildcardSequence'],
      clinchIndicator: json['clinchIndicator'] ?? false,
      playoffStatus: _determinePlayoffStatus(json),
    );
  }

  /// ✅ ДОДАНО: Конвертувати в JSON для кешування
  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'teamAbbrev': teamAbbrev,
      'teamLogo': teamLogo,
      'divisionId': divisionId,
      'divisionName': divisionName,
      'conferenceId': conferenceId,
      'conferenceName': conferenceName,
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'losses': losses,
      'otLosses': overtimeLosses,
      'points': points,
      'goalFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'goalDifferential': goalDifferential,
      'regulationWins': regulationWins,
      'last10': last10,
      'streak': streak,
      'homeWins': homeWins,
      'homeLosses': homeLosses,
      'homeOtLosses': homeOT,
      'roadWins': awayWins,
      'roadLosses': awayLosses,
      'roadOtLosses': awayOT,
      'divisionSequence': divisionRank,
      'conferenceSequence': conferenceRank,
      'leagueSequence': leagueRank,
      'wildcardSequence': wildCardRank,
      'clinchIndicator': clinchIndicator,
      'playoffStatus': playoffStatus,
      // Додаємо поля для зворотної сумісності з fromJson
      'streakCode': streak.isNotEmpty ? streak.substring(0, 1) : '',
      'streakCount': streak.length > 1 ? int.tryParse(streak.substring(1)) ?? 0 : 0,
    };
  }

  /// Визначити статус плей-офф
  static String? _determinePlayoffStatus(Map<String, dynamic> json) {
    // Якщо є wildcardSequence - це wildcard
    if (json['wildcardSequence'] != null && json['wildcardSequence'] <= 2) {
      return 'wildcard';
    }

    // Якщо divisionSequence <= 3 - це playoff
    if (json['divisionSequence'] != null && json['divisionSequence'] <= 3) {
      return 'playoff';
    }

    // Інакше - поза зоною
    return null;
  }

  /// Отримати кольоровий індикатор
  String get statusIndicator {
    if (playoffStatus == 'playoff') return '🟢';
    if (playoffStatus == 'wildcard') return '🟡';
    return '🔴';
  }

  @override
  String toString() {
    return 'TeamStanding(${teamAbbrev}: $points pts, $wins-$losses-$overtimeLosses)';
  }
}
