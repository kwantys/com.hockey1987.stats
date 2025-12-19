/// Модель для NHL гри
class Game {
  final int gameId;
  final String status; // "Scheduled", "InProgress", "Final", "Canceled"
  final String? statusText; // Додатковий статус (наприклад "1st", "2nd", "OT")
  final DateTime dateTime;
  final String? timeRemaining; // Час що залишився в періоді (наприклад "07:44")
  final int? period; // Поточний період (1, 2, 3, 4=OT)

  // Home team
  final int homeTeamId;
  final String homeTeamName;
  final String? homeTeamCity;
  final int? homeTeamScore;
  final String? homeTeamLogo;

  // Away team
  final int awayTeamId;
  final String awayTeamName;
  final String? awayTeamCity;
  final int? awayTeamScore;
  final String? awayTeamLogo;

  // Додаткова інформація
  final String? venue;
  final bool? isHomeGame;

  const Game({
    required this.gameId,
    required this.status,
    this.statusText,
    required this.dateTime,
    this.timeRemaining,
    this.period,
    required this.homeTeamId,
    required this.homeTeamName,
    this.homeTeamCity,
    this.homeTeamScore,
    this.homeTeamLogo,
    required this.awayTeamId,
    required this.awayTeamName,
    this.awayTeamCity,
    this.awayTeamScore,
    this.awayTeamLogo,
    this.venue,
    this.isHomeGame,
  });

  /// Створити з JSON (NHL Stats API v1)
  /// Створити з JSON (NHL Stats API v1)
  factory Game.fromJson(Map<String, dynamic> json) {
    final gamePk = json['gamePk'] ?? 0;
    final gameDate = json['gameDate'] ?? '';
    final status = json['status'] ?? {};
    final teams = json['teams'] ?? {};

    final homeTeam = teams['home'] ?? {};
    final awayTeam = teams['away'] ?? {};

    final homeTeamData = homeTeam['team'] ?? {};
    final awayTeamData = awayTeam['team'] ?? {};

    final statusCode = status['statusCode'] ?? '1';
    final detailedState = status['detailedState'] ?? 'Scheduled';

    String simplifiedStatus;
    if (statusCode == '2' || statusCode == '3' || detailedState.contains('Progress')) {
      simplifiedStatus = 'InProgress';
    } else if (statusCode == '7' || statusCode == '6' || detailedState.contains('Final')) {
      simplifiedStatus = 'Final';
    } else {
      simplifiedStatus = 'Scheduled';
    }

    final linescore = json['linescore'] ?? {};
    final currentPeriod = linescore['currentPeriod'];
    final currentPeriodTimeRemaining = linescore['currentPeriodTimeRemaining'];

    // ✅ ВИПРАВЛЕННЯ: Використовуємо PNG замість SVG
    final homeAbbrev = homeTeamData['abbreviation']?.toString() ?? '';
    final awayAbbrev = awayTeamData['abbreviation']?.toString() ?? '';

    String? homeLogoUrl;
    if (homeAbbrev.isNotEmpty) {
      homeLogoUrl = 'https://assets.nhle.com/logos/nhl/png/${homeAbbrev}_dark.png';
    }

    String? awayLogoUrl;
    if (awayAbbrev.isNotEmpty) {
      awayLogoUrl = 'https://assets.nhle.com/logos/nhl/png/${awayAbbrev}_dark.png';
    }

    return Game(
      gameId: gamePk,
      status: simplifiedStatus,
      statusText: detailedState,
      dateTime: gameDate.isNotEmpty
          ? DateTime.parse(gameDate)
          : DateTime.now(),
      timeRemaining: currentPeriodTimeRemaining,
      period: currentPeriod,
      homeTeamId: homeTeamData['id'] ?? 0,
      homeTeamName: homeTeamData['name'] ?? 'Unknown',
      homeTeamCity: null,
      homeTeamScore: homeTeam['score'],
      homeTeamLogo: homeLogoUrl,
      awayTeamId: awayTeamData['id'] ?? 0,
      awayTeamName: awayTeamData['name'] ?? 'Unknown',
      awayTeamCity: null,
      awayTeamScore: awayTeam['score'],
      awayTeamLogo: awayLogoUrl,
      venue: json['venue']?['name'],
      isHomeGame: null,
    );
  }

  /// Створити з JSON (NHL API v2 - новий формат)
  factory Game.fromNHLv2Json(Map<String, dynamic> json) {
    final id = json['id'] ?? 0;
    final gameState = json['gameState'] ?? 'FUT';
    final startTimeUTC = json['startTimeUTC'] ?? '';

    final homeTeam = json['homeTeam'] ?? {};
    final awayTeam = json['awayTeam'] ?? {};

    // ✅ ВИПРАВЛЕННЯ: Використовуємо PNG замість SVG
    final homeTeamAbbrev = homeTeam['abbrev']?.toString() ?? '';
    final awayTeamAbbrev = awayTeam['abbrev']?.toString() ?? '';

    // Формуємо URL логотипів у PNG форматі (працює на Android)
    String? homeTeamLogo = homeTeam['logo'];
    if ((homeTeamLogo == null || homeTeamLogo.isEmpty) && homeTeamAbbrev.isNotEmpty) {
      // Використовуємо темний варіант у великому розмірі (196x196)
      homeTeamLogo = 'https://assets.nhle.com/logos/nhl/png/${homeTeamAbbrev}_dark.png';
    }

    String? awayTeamLogo = awayTeam['logo'];
    if ((awayTeamLogo == null || awayTeamLogo.isEmpty) && awayTeamAbbrev.isNotEmpty) {
      awayTeamLogo = 'https://assets.nhle.com/logos/nhl/png/${awayTeamAbbrev}_dark.png';
    }

    print('🏒 Game ${id}: Home logo: $homeTeamLogo, Away logo: $awayTeamLogo');

    final period = json['period'];
    final periodDescriptor = json['periodDescriptor'] ?? {};
    final periodType = periodDescriptor['periodType'];
    final timeRemaining = json['clock']?['timeRemaining'];

    return Game(
      gameId: id,
      status: gameState,
      statusText: gameState,
      dateTime: startTimeUTC.isNotEmpty
          ? DateTime.parse(startTimeUTC)
          : DateTime.now(),
      timeRemaining: timeRemaining,
      period: period,
      homeTeamId: homeTeam['id'] ?? 0,
      homeTeamName: homeTeam['name']?['default'] ?? homeTeam['abbrev'] ?? 'Unknown',
      homeTeamCity: null,
      homeTeamScore: homeTeam['score'],
      homeTeamLogo: homeTeamLogo,
      awayTeamId: awayTeam['id'] ?? 0,
      awayTeamName: awayTeam['name']?['default'] ?? awayTeam['abbrev'] ?? 'Unknown',
      awayTeamCity: null,
      awayTeamScore: awayTeam['score'],
      awayTeamLogo: awayTeamLogo,
      venue: json['venue']?['default'],
      isHomeGame: null,
    );
  }

  /// Конвертувати в JSON
  Map<String, dynamic> toJson() {
    return {
      'GameID': gameId,
      'Status': status,
      'StatusText': statusText,
      'DateTime': dateTime.toIso8601String(),
      'TimeRemaining': timeRemaining,
      'Period': period,
      'HomeTeamID': homeTeamId,
      'HomeTeam': homeTeamName,
      'HomeTeamCity': homeTeamCity,
      'HomeTeamScore': homeTeamScore,
      'HomeTeamLogo': homeTeamLogo,
      'AwayTeamID': awayTeamId,
      'AwayTeam': awayTeamName,
      'AwayTeamCity': awayTeamCity,
      'AwayTeamScore': awayTeamScore,
      'AwayTeamLogo': awayTeamLogo,
      'StadiumName': venue,
      'IsHomeGame': isHomeGame,
    };
  }

  /// Чи гра в прямому ефірі
  bool get isLive =>
      status == 'InProgress' ||
          status == 'LIVE' ||
          status == 'CRIT' ||
          statusText == 'LIVE' ||
          statusText == 'CRIT';

  /// Чи гра заплановані (майбутня)
  bool get isUpcoming =>
      status == 'Scheduled' ||
          status == 'FUT' ||
          status == 'Not Started' ||
          statusText == 'FUT';

  /// Чи гра завершена
  bool get isFinal =>
      status == 'Final' ||
          status == 'OFF' ||
          status == 'FINAL' ||
          status == 'F/OT' ||
          status == 'F/SO' ||
          statusText == 'OFF' ||
          statusText == 'FINAL';

  /// Повне ім'я команди Home
  String get homeTeamFullName {
    if (homeTeamCity != null && homeTeamCity!.isNotEmpty) {
      return '$homeTeamCity $homeTeamName';
    }
    return homeTeamName;
  }

  /// Повне ім'я команди Away
  String get awayTeamFullName {
    if (awayTeamCity != null && awayTeamCity!.isNotEmpty) {
      return '$awayTeamCity $awayTeamName';
    }
    return awayTeamName;
  }

  /// Отримати текст періоду (1st, 2nd, 3rd, OT, SO)
  String get periodText {
    if (period == null) return '';
    switch (period!) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      case 4:
        return 'OT';
      case 5:
        return 'SO';
      default:
        return '${period}th';
    }
  }

  /// Отримати форматований час гри для Live
  String get liveTimeDisplay {
    if (!isLive) return '';
    if (timeRemaining != null && timeRemaining!.isNotEmpty) {
      return '$timeRemaining • $periodText';
    }
    return periodText;
  }

  /// Отримати форматований час початку для Upcoming
  String get upcomingTimeDisplay {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return 'Faceoff $hour:$minute';
  }

  /// Хто виграв (для Final)
  String? get winner {
    if (!isFinal) return null;
    if (homeTeamScore == null || awayTeamScore == null) return null;

    if (homeTeamScore! > awayTeamScore!) {
      return 'home';
    } else if (awayTeamScore! > homeTeamScore!) {
      return 'away';
    } else {
      return 'draw';
    }
  }

  @override
  String toString() {
    return 'Game(id: $gameId, $awayTeamName @ $homeTeamName, '
        'status: $status, score: $awayTeamScore-$homeTeamScore)';
  }
}