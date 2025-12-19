/// Модель для команди NHL
class Team {
  final int teamId;
  final String teamName;
  final String teamAbbrev;
  final String? teamLogo;
  final String divisionName;
  final String conferenceName;

  // Додаткова інформація
  final String? venue;
  final String? city;
  final int? foundedYear;
  final String? website;

  const Team({
    required this.teamId,
    required this.teamName,
    required this.teamAbbrev,
    this.teamLogo,
    required this.divisionName,
    required this.conferenceName,
    this.venue,
    this.city,
    this.foundedYear,
    this.website,
  });

  /// Створити з JSON (NHL API)
  factory Team.fromJson(Map<String, dynamic> json) {
    final teamNameData = json['teamName'] ?? json['name'];
    final teamName = teamNameData is Map
        ? (teamNameData['default'] ?? teamNameData['en'] ?? '')
        : (teamNameData ?? '');

    final abbrevData = json['teamAbbrev'] ?? json['abbrev'];
    final abbrev = abbrevData is Map
        ? (abbrevData['default'] ?? '')
        : (abbrevData ?? '');

    final venueData = json['venue'];
    final venue = venueData is Map
        ? (venueData['default'] ?? '')
        : (venueData ?? '');

    // ✅ ВИПРАВЛЕННЯ: Використовуємо PNG замість SVG
    String? teamLogo = json['teamLogo'] ?? json['logo'];

    if ((teamLogo == null || teamLogo.isEmpty) && abbrev.isNotEmpty) {
      teamLogo = 'https://assets.nhle.com/logos/nhl/png/${abbrev}_dark.png';
      print('🖼️ Generated PNG logo URL for $abbrev: $teamLogo');
    }

    return Team(
      teamId: json['teamId'] ?? json['id'] ?? 0,
      teamName: teamName,
      teamAbbrev: abbrev,
      teamLogo: teamLogo,
      divisionName: json['divisionName'] ?? json['division'] ?? '',
      conferenceName: json['conferenceName'] ?? json['conference'] ?? '',
      venue: venue,
      city: json['city'],
      foundedYear: json['foundedYear'],
      website: json['website'],
    );
  }
  /// Конвертувати в JSON
  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'teamAbbrev': teamAbbrev,
      'teamLogo': teamLogo,
      'divisionName': divisionName,
      'conferenceName': conferenceName,
      'venue': venue,
      'city': city,
      'foundedYear': foundedYear,
      'website': website,
    };
  }

  @override
  String toString() {
    return 'Team($teamName - $divisionName, $conferenceName)';
  }
}

/// Модель для гравця в roster
class Player {
  final int playerId;
  final String firstName;
  final String lastName;
  final int jerseyNumber;
  final String position; // C, LW, RW, D, G
  final String? shoots; // L, R (лівша/правша)
  final String? birthDate;
  final String? birthCity;
  final String? birthCountry;
  final int? height; // в см
  final int? weight; // в кг

  // Статистика сезону
  final int gamesPlayed;
  final int goals;
  final int assists;
  final int points;
  final int? plusMinus;
  final int? penaltyMinutes;

  // Для воротарів
  final int? wins;
  final int? losses;
  final int? otLosses;
  final double? savePercentage;
  final double? goalsAgainstAverage;

  const Player({
    required this.playerId,
    required this.firstName,
    required this.lastName,
    required this.jerseyNumber,
    required this.position,
    this.shoots,
    this.birthDate,
    this.birthCity,
    this.birthCountry,
    this.height,
    this.weight,
    this.gamesPlayed = 0,
    this.goals = 0,
    this.assists = 0,
    this.points = 0,
    this.plusMinus,
    this.penaltyMinutes,
    this.wins,
    this.losses,
    this.otLosses,
    this.savePercentage,
    this.goalsAgainstAverage,
  });

  /// Повне ім'я
  String get fullName => '$firstName $lastName';

  /// Чи це воротар
  bool get isGoalie => position == 'G';

  /// Створити з JSON
  factory Player.fromJson(Map<String, dynamic> json) {
    // Обробка імен
    final firstNameData = json['firstName'];
    final firstName = firstNameData is Map
        ? (firstNameData['default'] ?? '')
        : (firstNameData ?? '');

    final lastNameData = json['lastName'];
    final lastName = lastNameData is Map
        ? (lastNameData['default'] ?? '')
        : (lastNameData ?? '');

    // === ВИПРАВЛЕННЯ: Допоміжна функція для отримання локалізованих рядків ===
    String? getLocalizedStr(dynamic data) {
      if (data == null) return null;
      if (data is Map) {
        return data['default']?.toString() ?? data.values.first.toString();
      }
      return data.toString();
    }

    return Player(
      playerId: json['playerId'] ?? json['id'] ?? 0,
      firstName: firstName,
      lastName: lastName,
      jerseyNumber: json['sweaterNumber'] ?? json['jerseyNumber'] ?? 0,
      position: json['positionCode'] ?? json['position'] ?? '',
      shoots: json['shootsCatches'] ?? json['shoots'],
      birthDate: json['birthDate'],

      // Використовуємо виправлену логіку
      birthCity: getLocalizedStr(json['birthCity']),
      birthCountry: getLocalizedStr(json['birthCountry']),

      height: json['heightInCentimeters'],
      weight: json['weightInKilograms'],
      gamesPlayed: json['gamesPlayed'] ?? 0,
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      points: json['points'] ?? 0,
      plusMinus: json['plusMinus'],
      penaltyMinutes: json['pim'],
      wins: json['wins'],
      losses: json['losses'],
      otLosses: json['otLosses'],
      savePercentage: json['savePctg']?.toDouble(),
      goalsAgainstAverage: json['goalsAgainstAvg']?.toDouble(),
    );
  }

  /// Конвертувати в JSON
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'firstName': firstName,
      'lastName': lastName,
      'jerseyNumber': jerseyNumber,
      'position': position,
      'shoots': shoots,
      'birthDate': birthDate,
      'birthCity': birthCity,
      'birthCountry': birthCountry,
      'height': height,
      'weight': weight,
      'gamesPlayed': gamesPlayed,
      'goals': goals,
      'assists': assists,
      'points': points,
      'plusMinus': plusMinus,
      'penaltyMinutes': penaltyMinutes,
      'wins': wins,
      'losses': losses,
      'otLosses': otLosses,
      'savePercentage': savePercentage,
      'goalsAgainstAverage': goalsAgainstAverage,
    };
  }

  @override
  String toString() {
    return 'Player(#$jerseyNumber $fullName - $position)';
  }
}

/// Модель для майбутнього матчу команди
class TeamScheduleGame {
  final int gameId;
  final DateTime gameDate;
  final String opponentName;
  final String opponentAbbrev;
  final bool isHomeGame;
  final String? venue;
  final String gameState; // FUT, LIVE, FINAL

  const TeamScheduleGame({
    required this.gameId,
    required this.gameDate,
    required this.opponentName,
    required this.opponentAbbrev,
    required this.isHomeGame,
    this.venue,
    required this.gameState,
  });

  /// Створити з JSON
  factory TeamScheduleGame.fromJson(Map<String, dynamic> json, int myTeamId) {
    final homeTeam = json['homeTeam'] ?? {};
    final awayTeam = json['awayTeam'] ?? {};

    final homeTeamId = homeTeam['id'] ?? 0;
    final awayTeamId = awayTeam['id'] ?? 0;

    final isHome = homeTeamId == myTeamId;

    // Визначити опонента
    final opponentData = isHome ? awayTeam : homeTeam;

    // Обробка назви (може бути String або Map)
    String opponentName = '';
    final nameData = opponentData['name'];
    if (nameData is Map) {
      opponentName = nameData['default'] ?? '';
    } else if (nameData is String) {
      opponentName = nameData;
    }

    // Обробка абревіатури (може бути String або Map)
    String opponentAbbrev = '';
    final abbrevData = opponentData['abbrev'];
    if (abbrevData is Map) {
      opponentAbbrev = abbrevData['default'] ?? '';
    } else if (abbrevData is String) {
      opponentAbbrev = abbrevData;
    }

    // Якщо немає абревіатури, спробувати витягнути з назви
    if (opponentAbbrev.isEmpty && opponentName.isNotEmpty) {
      final words = opponentName.split(' ');
      opponentAbbrev = words.last.substring(0, 3).toUpperCase();
    }

    // Обробка venue
    String venue = '';
    final venueData = json['venue'];
    if (venueData is Map) {
      venue = venueData['default'] ?? '';
    } else if (venueData is String) {
      venue = venueData;
    }

    // Обробка дати
    DateTime gameDate;
    try {
      final dateStr = json['startTimeUTC'] ?? json['gameDate'];
      gameDate = DateTime.parse(dateStr);
    } catch (e) {
      gameDate = DateTime.now();
      print('Error parsing game date: $e');
    }

    return TeamScheduleGame(
      gameId: json['id'] ?? 0,
      gameDate: gameDate,
      opponentName: opponentName,
      opponentAbbrev: opponentAbbrev,
      isHomeGame: isHome,
      venue: venue.isNotEmpty ? venue : null,
      gameState: json['gameState'] ?? 'FUT',
    );
  }

  /// Форматований час
  String get timeDisplay {
    final hour = gameDate.hour.toString().padLeft(2, '0');
    final minute = gameDate.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Форматована дата
  String get dateDisplay {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[gameDate.month - 1]} ${gameDate.day}';
  }
}