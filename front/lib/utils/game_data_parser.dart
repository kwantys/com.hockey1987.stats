/// Helper клас для парсингу даних гри з NHL API
class GameDataParser {
  final Map<String, dynamic> data;

  GameDataParser(this.data);

  /// Отримати всі події Timeline
  List<Map<String, dynamic>> getTimelineEvents() {
    try {
      // Спробувати різні місця де можуть бути plays
      var plays = data['plays'] as List?;

      // Якщо немає в корені, спробувати в summary
      if (plays == null || plays.isEmpty) {
        plays = data['summary']?['scoring'] as List?;
      }

      // Якщо досі немає, спробувати linescore
      if (plays == null || plays.isEmpty) {
        plays = data['linescore']?['plays'] as List?;
      }

      print('Timeline: Found ${plays?.length ?? 0} plays');

      if (plays == null || plays.isEmpty) {
        return [];
      }

      final events = <Map<String, dynamic>>[];
      int goalCount = 0, shotCount = 0, hitCount = 0, penaltyCount = 0, faceoffCount = 0;

      for (var playData in plays) {
        try {
          // Safely convert play data
          final play = playData is Map<String, dynamic>
              ? playData
              : Map<String, dynamic>.from(playData as Map);

          final typeCode = play['typeCode'] as int? ?? play['eventTypeId'] as int?;
          final typeDescKey = play['typeDescKey']?.toString();

          // Count by type
          if (typeCode == 505) goalCount++;
          else if (typeCode == 506) shotCount++;
          else if (typeCode == 507) hitCount++;
          else if (typeCode == 509) penaltyCount++;
          else if (typeCode == 508) faceoffCount++;

          final periodDescData = play['periodDescriptor'];
          final periodDesc = periodDescData is Map<String, dynamic>
              ? periodDescData
              : (periodDescData != null ? Map<String, dynamic>.from(periodDescData as Map) : null);

          final aboutData = play['about'];
          final about = aboutData is Map<String, dynamic>
              ? aboutData
              : (aboutData != null ? Map<String, dynamic>.from(aboutData as Map) : null);

          final period = periodDesc?['number'] ?? about?['period'] ?? 1;
          final timeInPeriod = play['timeInPeriod']?.toString() ?? about?['periodTime']?.toString() ?? '';

          final detailsData = play['details'];
          final details = detailsData is Map<String, dynamic>
              ? detailsData
              : (detailsData != null ? Map<String, dynamic>.from(detailsData as Map) : <String, dynamic>{});

          events.add({
            'type': _getEventType(typeCode),
            'time': '$period ${_formatTime(timeInPeriod)}',
            'description': _getEventDescription(play),
            'player': _getPlayerName(details),
            'typeCode': typeCode,
          });
        } catch (e) {
          print('Error parsing play: $e');
          continue;
        }
      }

      print('Timeline breakdown: Goals=$goalCount, Shots=$shotCount, Hits=$hitCount, Penalties=$penaltyCount, Faceoffs=$faceoffCount');

      return events;
    } catch (e) {
      print('Error parsing timeline: $e');
      return [];
    }
  }

  /// Отримати голи
  List<Map<String, dynamic>> getGoals() {
    try {
      // Get home and away team IDs from game data
      final homeTeamId = data['homeTeam']?['id'] as int?;
      final awayTeamId = data['awayTeam']?['id'] as int?;

      print('Game teams: Home ID=$homeTeamId, Away ID=$awayTeamId');

      // Завжди використовувати plays з typeCode=505 (більш надійно)
      final plays = data['plays'] as List?;

      if (plays == null || plays.isEmpty) {
        print('Goals: No plays found');
        return [];
      }

      // Фільтрувати тільки голи
      final goalPlays = plays.where((playData) {
        try {
          final play = playData is Map<String, dynamic>
              ? playData
              : Map<String, dynamic>.from(playData as Map);
          final typeCode = play['typeCode'] as int?;
          return typeCode == 505;
        } catch (e) {
          return false;
        }
      }).toList();

      print('Goals: Found ${goalPlays.length} goals');

      if (goalPlays.isEmpty) {
        return [];
      }

      final goals = <Map<String, dynamic>>[];
      int homeGoals = 0, awayGoals = 0;

      for (var playData in goalPlays) {
        try {
          final play = playData is Map<String, dynamic>
              ? playData
              : Map<String, dynamic>.from(playData as Map);

          // DEBUG: Log first goal structure
          if (goals.isEmpty) {
            print('=== FIRST GOAL STRUCTURE ===');
            print('Play keys: ${play.keys}');
            print('homeTeamDefending: ${play['homeTeamDefending']}');

            final detailsData = play['details'];
            if (detailsData != null) {
              final details = detailsData is Map<String, dynamic>
                  ? detailsData
                  : Map<String, dynamic>.from(detailsData as Map);
              print('Details keys: ${details.keys}');
              print('eventOwnerTeamId: ${details['eventOwnerTeamId']}');
              print('teamAbbrev: ${details['teamAbbrev']}');
            }
            print('===========================');
          }

          final periodDescData = play['periodDescriptor'];
          final periodDesc = periodDescData is Map<String, dynamic>
              ? periodDescData
              : (periodDescData != null ? Map<String, dynamic>.from(periodDescData as Map) : null);

          final period = periodDesc?['number'] ?? 1;
          final timeInPeriod = play['timeInPeriod']?.toString() ?? '';

          final detailsData = play['details'];
          final details = detailsData is Map<String, dynamic>
              ? detailsData
              : (detailsData != null ? Map<String, dynamic>.from(detailsData as Map) : <String, dynamic>{});

          // Get scorer
          final scoringPlayerData = details['scoringPlayer'];
          final scoringPlayer = scoringPlayerData is Map<String, dynamic>
              ? scoringPlayerData
              : (scoringPlayerData != null ? Map<String, dynamic>.from(scoringPlayerData as Map) : <String, dynamic>{});

          final firstNameData = scoringPlayer['firstName'];
          final scorerFirstName = firstNameData is Map
              ? (firstNameData['default'] ?? '')
              : (firstNameData ?? '');

          final lastNameData = scoringPlayer['lastName'];
          final scorerLastName = lastNameData is Map
              ? (lastNameData['default'] ?? '')
              : (lastNameData ?? '');

          // Get assists
          final assistsList = details['assists'] as List? ?? [];
          final assistNames = assistsList.map((assistData) {
            try {
              final assist = assistData is Map<String, dynamic>
                  ? assistData
                  : Map<String, dynamic>.from(assistData as Map);

              final firstNameData = assist['firstName'];
              final firstName = firstNameData is Map
                  ? (firstNameData['default'] ?? '')
                  : (firstNameData ?? '');

              final lastNameData = assist['lastName'];
              final lastName = lastNameData is Map
                  ? (lastNameData['default'] ?? '')
                  : (lastNameData ?? '');

              return '$firstName $lastName'.trim();
            } catch (e) {
              return '';
            }
          }).where((n) => n.isNotEmpty).join(', ');

          // Get team info from eventOwnerTeamId
          final eventOwnerTeamId = details['eventOwnerTeamId'] as int?;

          // Determine if Home or Away based on team ID comparison
          final isHome = eventOwnerTeamId == homeTeamId;

          // Get team abbreviation from game data
          String teamAbbrev = '';
          if (isHome) {
            final abbrevData = data['homeTeam']?['abbrev'];
            teamAbbrev = abbrevData?.toString() ?? '';
          } else {
            final abbrevData = data['awayTeam']?['abbrev'];
            teamAbbrev = abbrevData?.toString() ?? '';
          }

          if (isHome) homeGoals++;
          else awayGoals++;

          goals.add({
            'time': '$period ${_formatTime(timeInPeriod)}',
            'scorer': '$scorerFirstName $scorerLastName'.trim(),
            'assists': assistNames,
            'type': _getGoalType(details),
            'team': teamAbbrev,
            'isHome': isHome,
          });
        } catch (e) {
          print('Error parsing goal: $e');
          continue;
        }
      }

      print('Goals breakdown: Home=$homeGoals, Away=$awayGoals');

      return goals;
    } catch (e) {
      print('Error parsing goals: $e');
      return [];
    }
  }

  /// Отримати штрафи
  List<Map<String, dynamic>> getPenalties() {
    try {
      // Спробувати summary.penalties
      var penaltyPlays = data['summary']?['penalties'] as List?;

      // Якщо немає, спробувати plays з фільтром
      if (penaltyPlays == null || penaltyPlays.isEmpty) {
        final plays = data['plays'] as List?;
        penaltyPlays = plays?.where((play) {
          final typeCode = play['typeCode'] as int?;
          return typeCode == 509; // Penalty
        }).toList();
      }

      print('Penalties: Found ${penaltyPlays?.length ?? 0} penalties');

      if (penaltyPlays == null || penaltyPlays.isEmpty) {
        return [];
      }

      final penalties = <Map<String, dynamic>>[];

      for (var play in penaltyPlays) {
        try {
          final period = play['periodDescriptor']?['number'] ?? play['period'] ?? 1;
          final timeInPeriod = play['timeInPeriod'] ?? '';
          final details = play['details'] ?? play;

          final committedByPlayer = details['committedByPlayer'] ??
              details['players']?.firstWhere(
                    (p) => p['playerType'] == 'PenaltyOn',
                orElse: () => {},
              ) ?? {};

          final firstName = committedByPlayer['firstName']?['default'] ??
              committedByPlayer['firstName'] ?? '';
          final lastName = committedByPlayer['lastName']?['default'] ??
              committedByPlayer['lastName'] ?? '';

          penalties.add({
            'time': '$period ${_formatTime(timeInPeriod)}',
            'team': details['teamAbbrev']?['default'] ??
                details['eventOwnerTeamId']?.toString() ?? '',
            'player': '$firstName $lastName'.trim(),
            'type': details['typeCode'] ?? details['type'] ?? 'Penalty',
            'minutes': details['duration'] ?? details['penaltyMinutes'] ?? 2,
          });
        } catch (e) {
          print('Error parsing penalty: $e');
          continue;
        }
      }

      return penalties;
    } catch (e) {
      print('Error parsing penalties: $e');
      return [];
    }
  }

  /// Отримати командну статистику (Включає ручний підрахунок з подій)
  Map<String, dynamic> getTeamStats() {
    print('=== TEAM STATS DEBUG ===');

    // 1. Спроба: Знайти готовий список від API
    List? statsList;
    if (data['teamGameStats'] is List) statsList = data['teamGameStats'];
    else if (data['summary']?['teamGameStats'] is List) statsList = data['summary']['teamGameStats'];
    else if (data['boxscore']?['teamGameStats'] is List) statsList = data['boxscore']['teamGameStats'];

    if (statsList != null && statsList.isNotEmpty) {
      print('Using API provided stats list');
      return _parseStatsFromList(statsList);
    }

    // 2. Спроба: Витягнути з об'єктів команд (якщо є)
    final homeTeamObj = data['boxscore']?['homeTeam'] ?? data['homeTeam'] ?? {};
    final awayTeamObj = data['boxscore']?['awayTeam'] ?? data['awayTeam'] ?? {};

    // Якщо в об'єктах команд є дані про хіти (більше 0), використовуємо їх
    if ((homeTeamObj['hits'] ?? 0) > 0 || (awayTeamObj['hits'] ?? 0) > 0) {
      print('Using Team objects direct stats');
      return _extractFromTeamObjects(homeTeamObj, awayTeamObj);
    }

    // 3. ФІНАЛЬНА СПРОБА: Рахуємо вручну з Play-by-Play (найбільш надійно)
    print('Stats missing in metadata. Calculating manually from Play-by-Play...');
    return _calculateStatsFromPlays();
  }

  // --- Допоміжні методи ---

  Map<String, dynamic> _extractFromTeamObjects(Map home, Map away) {
    dynamic getVal(Map m, String key) => m[key];
    int parsePct(dynamic v) => v is double ? (v * 100).round() : (v as int? ?? 0);

    return {
      'shots': {
        'home': getVal(home, 'sog') ?? getVal(home, 'shots') ?? 0,
        'away': getVal(away, 'sog') ?? getVal(away, 'shots') ?? 0,
      },
      'hits': {
        'home': getVal(home, 'hits') ?? 0,
        'away': getVal(away, 'hits') ?? 0,
      },
      'faceoffPct': {
        'home': parsePct(getVal(home, 'faceoffWinningPctg')),
        'away': parsePct(getVal(away, 'faceoffWinningPctg')),
      },
      'blocks': {
        'home': getVal(home, 'blockedShots') ?? getVal(home, 'blocks') ?? 0,
        'away': getVal(away, 'blockedShots') ?? getVal(away, 'blocks') ?? 0,
      },
      'pim': {
        'home': getVal(home, 'pim') ?? 0,
        'away': getVal(away, 'pim') ?? 0,
      },
      'powerPlay': {'home': '0/0', 'away': '0/0'}, // Важко порахувати вручну
    };
  }

  Map<String, dynamic> _calculateStatsFromPlays() {
    final plays = data['plays'] as List? ?? [];
    final homeTeamId = data['homeTeam']?['id'] ?? data['boxscore']?['homeTeam']?['id'];

    // Отримуємо абревіатури команд для порівняння в summary
    final homeAbbrev = data['homeTeam']?['abbrev']?.toString() ?? 'HOME';

    int hShots = 0, aShots = 0;
    int hHits = 0, aHits = 0;
    int hBlocks = 0, aBlocks = 0;
    int hPim = 0, aPim = 0;
    int hFaceoffWins = 0, aFaceoffWins = 0;
    int totalFaceoffs = 0;

    // Змінні для Power Play
    int hPPGoals = 0, aPPGoals = 0;
    int hPPOpps = 0, aPPOpps = 0;

    // --- КРОК 1: Рахуємо точні голи через Summary (надійніше) ---
    final scoringPlays = data['summary']?['scoring'] as List? ?? [];

    if (scoringPlays.isNotEmpty) {
      print('Using SUMMARY for Goal Types (Reliable)');
      for (var goal in scoringPlays) {
        final teamAbbrev = goal['teamAbbrev']?['default']?.toString() ?? '';
        final type = goal['strength']?.toString().toLowerCase() ?? 'ev';

        // Визначаємо команду за абревіатурою (бо ID там може не бути)
        final isHomeGoal = teamAbbrev == homeAbbrev;

        if (type.contains('pp')) {
          if (isHomeGoal) hPPGoals++; else aPPGoals++;
        }
      }
    }

    // --- КРОК 2: Рахуємо все інше через Plays ---
    for (var play in plays) {
      final p = play is Map ? play : Map<String, dynamic>.from(play as Map);
      final type = p['typeCode'] as int? ?? p['eventTypeId'] as int?;
      final details = p['details'] ?? {};
      final ownerId = details['eventOwnerTeamId'] as int?;

      // Якщо ID немає, пропускаємо (буває для системних подій)
      if (ownerId == null) continue;

      bool isHomeEvent = ownerId == homeTeamId;

      switch (type) {
        case 506: // Shot
          if (isHomeEvent) hShots++; else aShots++;
          break;

        case 505: // Goal
        // Рахуємо ТІЛЬКИ як кидок (SOG).
        // Голи PP ми вже порахували вище через summary.
          if (isHomeEvent) hShots++; else aShots++;

          // Fallback: Якщо summary було пустим, пробуємо витягнути PP звідси
          if (scoringPlays.isEmpty) {
            final strength = details['strength']?.toString().toLowerCase() ?? '';
            final sitCode = details['situationCode']?.toString();
            bool isPP = strength.contains('pp');

            if (!isPP && sitCode != null && sitCode.length == 4) {
              int awaySkaters = int.tryParse(sitCode[1]) ?? 5;
              int homeSkaters = int.tryParse(sitCode[2]) ?? 5;
              if (isHomeEvent && homeSkaters > awaySkaters) isPP = true;
              if (!isHomeEvent && awaySkaters > homeSkaters) isPP = true;
            }
            if (isPP) {
              if (isHomeEvent) hPPGoals++; else aPPGoals++;
            }
          }
          break;

        case 507: // Hit
          if (isHomeEvent) hHits++; else aHits++;
          break;

        case 516: // Block
          if (isHomeEvent) hBlocks++; else aBlocks++;
          break;

        case 509: // Penalty
          final min = details['duration'] as int? ?? 2;
          final typeCode = details['typeCode']?.toString();
          final descKey = details['descKey']?.toString() ?? '';

          if (isHomeEvent) hPim += min; else aPim += min;

          // Рахуємо спроби (Opportunities)
          final isFighting = descKey == 'fighting' || typeCode == '5';
          final isMisconduct = min > 5;

          if (!isFighting && !isMisconduct) {
            if (isHomeEvent) aPPOpps++; else hPPOpps++;
          }
          break;

        case 508: // Faceoff
          totalFaceoffs++;
          if (isHomeEvent) hFaceoffWins++; else aFaceoffWins++;
          break;
      }
    }

    // Лог для перевірки
    print('FINAL CALC -> Home PP: $hPPGoals/$hPPOpps, Away PP: $aPPGoals/$aPPOpps');

    int hFaceoffPct = totalFaceoffs > 0 ? ((hFaceoffWins / totalFaceoffs) * 100).round() : 0;
    int aFaceoffPct = totalFaceoffs > 0 ? ((aFaceoffWins / totalFaceoffs) * 100).round() : 0;

    final apiHomeShots = data['homeTeam']?['sog'] ?? data['boxscore']?['homeTeam']?['sog'];
    final apiAwayShots = data['awayTeam']?['sog'] ?? data['boxscore']?['awayTeam']?['sog'];

    return {
      'shots': {
        'home': apiHomeShots ?? hShots,
        'away': apiAwayShots ?? aShots,
      },
      'hits': {'home': hHits, 'away': aHits},
      'faceoffPct': {'home': hFaceoffPct, 'away': aFaceoffPct},
      'blocks': {'home': hBlocks, 'away': aBlocks},
      'pim': {'home': hPim, 'away': aPim},
      'powerPlay': {
        'home': '$hPPGoals/$hPPOpps',
        'away': '$aPPGoals/$aPPOpps'
      },
    };
  }

  /// Допоміжний метод для парсингу списку статистики
  Map<String, dynamic> _parseStatsFromList(List statsList) {
    // Ініціалізуємо нулями
    final result = {
      'shots': {'home': 0, 'away': 0},
      'hits': {'home': 0, 'away': 0},
      'faceoffPct': {'home': 0, 'away': 0},
      'blocks': {'home': 0, 'away': 0},
      'pim': {'home': 0, 'away': 0},
      'powerPlay': {'home': '0/0', 'away': '0/0'},
    };

    for (var item in statsList) {
      final category = item['category'].toString();
      final homeVal = item['homeValue'];
      final awayVal = item['awayValue'];

      switch (category) {
        case 'sog': // Shots on Goal
          result['shots'] = {'home': homeVal, 'away': awayVal};
          break;
        case 'hits':
          result['hits'] = {'home': homeVal, 'away': awayVal};
          break;
        case 'faceoffWinningPctg':
        // API часто повертає 0.55, треба перевести в 55
          result['faceoffPct'] = {
            'home': ((homeVal is num ? homeVal : 0) * 100).round(),
            'away': ((awayVal is num ? awayVal : 0) * 100).round(),
          };
          break;
        case 'blockedShots':
          result['blocks'] = {'home': homeVal, 'away': awayVal};
          break;
        case 'pim': // Penalty Minutes
          result['pim'] = {'home': homeVal, 'away': awayVal};
          break;
        case 'powerPlay':
        // API повертає рядок "1/3" або "0/2"
          result['powerPlay'] = {
            'home': homeVal.toString(),
            'away': awayVal.toString()
          };
          break;
      }
    }
    return result;
  }

  /// Отримати статистику гравців (skaters)
  List<Map<String, dynamic>> getSkaters() {
    try {
      print('=== SKATERS DEBUG ===');
      print('Has playerByGameStats: ${data['playerByGameStats'] != null}');

      if (data['playerByGameStats'] != null) {
        final playerStats = data['playerByGameStats'];
        print('PlayerByGameStats keys: ${playerStats.keys}');

        if (playerStats['homeTeam'] != null) {
          print('HomeTeam keys: ${playerStats['homeTeam'].keys}');
        }
      }
      print('====================');

      final homeSkaters =
          data['playerByGameStats']?['homeTeam']?['forwards'] as List? ?? [];
      final awaySkaters =
          data['playerByGameStats']?['awayTeam']?['forwards'] as List? ?? [];

      final allSkaters = [...homeSkaters, ...awaySkaters];

      print('Found ${allSkaters.length} skaters');

      return allSkaters.map((player) {
        return {
          'name':
          '${player['name']?['default'] ?? player['firstName']?['default'] ?? ''} ${player['lastName']?['default'] ?? ''}',
          'goals': player['goals'] ?? 0,
          'assists': player['assists'] ?? 0,
          'points': player['points'] ?? 0,
          'plusMinus': _formatPlusMinus(player['plusMinus']),
          'shots': player['sog'] ?? 0,
          'toi': player['toi'] ?? '0:00',
        };
      }).toList();
    } catch (e) {
      print('Error parsing skaters: $e');
      return [];
    }
  }

  /// Отримати статистику воротарів
  List<Map<String, dynamic>> getGoalies() {
    try {
      final homeGoalies =
          data['playerByGameStats']?['homeTeam']?['goalies'] as List? ?? [];
      final awayGoalies =
          data['playerByGameStats']?['awayTeam']?['goalies'] as List? ?? [];

      final allGoalies = [...homeGoalies, ...awayGoalies];

      return allGoalies.map((goalie) {
        final saves = goalie['saves'] ?? 0;
        final shotsAgainst = goalie['shotsAgainst'] ?? 0;
        final savePercent = shotsAgainst > 0
            ? (saves / shotsAgainst * 100).toStringAsFixed(1)
            : '0.0';

        return {
          'name':
          '${goalie['name']?['default'] ?? goalie['firstName']?['default'] ?? ''} ${goalie['lastName']?['default'] ?? ''}',
          'saves': saves,
          'savePercent': savePercent,
          'toi': goalie['toi'] ?? '0:00',
        };
      }).toList();
    } catch (e) {
      print('Error parsing goalies: $e');
      return [];
    }
  }

  /// Отримати рахунок по періодам
  Map<String, List<int>> getPeriodScores() {
    try {
      final periodScores = data['periodScores'] as List? ?? [];

      final Map<String, List<int>> result = {};

      for (int i = 0; i < periodScores.length; i++) {
        final period = periodScores[i];
        final periodLabel = i < 3 ? '${i + 1}st' : 'OT${i - 2}';

        result[periodLabel] = [
          period['homeScore'] ?? 0,
          period['awayScore'] ?? 0,
        ];
      }

      return result;
    } catch (e) {
      print('Error parsing period scores: $e');
      return {};
    }
  }

  /// Отримати ключові моменти
  List<String> getKeyMoments() {
    try {
      final summary = data['summary'] as Map<String, dynamic>?;
      if (summary == null) return [];

      final moments = <String>[];

      // Goals
      final scoringPlays = summary['scoringPlays'] as List? ?? [];
      if (scoringPlays.isNotEmpty) {
        moments.add('${scoringPlays.length} goals scored');
      }

      // Penalties
      final penalties = summary['penalties'] as List? ?? [];
      if (penalties.isNotEmpty) {
        moments.add('${penalties.length} penalties called');
      }

      // Shots
      final homeShots = data['homeTeam']?['sog'] ?? 0;
      final awayShots = data['awayTeam']?['sog'] ?? 0;
      moments.add('Total shots: $homeShots - $awayShots');

      return moments;
    } catch (e) {
      print('Error parsing key moments: $e');
      return [];
    }
  }

  // Helper methods

  String _getEventType(int? typeCode) {
    switch (typeCode) {
      case 505:
        return 'Goal';
      case 506:
        return 'Shot';
      case 507:
        return 'Hit';
      case 508:
        return 'Faceoff';
      case 509:
        return 'Penalty';
      case 516:
        return 'Blocked Shot';
      default:
        return 'Event';
    }
  }

  String _getEventDescription(dynamic playData) {
    if (playData == null) return 'Event';

    try {
      // Safely convert to Map<String, dynamic>
      final play = playData is Map<String, dynamic>
          ? playData
          : Map<String, dynamic>.from(playData as Map);

      final typeCode = play['typeCode'] as int?;
      final detailsData = play['details'];
      final details = detailsData is Map<String, dynamic>
          ? detailsData
          : (detailsData != null ? Map<String, dynamic>.from(detailsData as Map) : <String, dynamic>{});

      switch (typeCode) {
        case 505:
          return 'Goal scored';
        case 506:
          return details['shotType']?.toString() ?? 'Shot on goal';
        case 507:
          return 'Body check';
        case 508:
          return 'Faceoff won';
        case 509:
          return details['typeCode']?.toString() ?? 'Penalty';
        default:
          return 'Event';
      }
    } catch (e) {
      print('Error in _getEventDescription: $e');
      return 'Event';
    }
  }

  String _getPlayerName(dynamic detailsData) {
    if (detailsData == null) return '';

    try {
      final details = detailsData is Map<String, dynamic>
          ? detailsData
          : Map<String, dynamic>.from(detailsData as Map);

      final firstNameData = details['firstName'];
      final firstName = firstNameData is Map
          ? (firstNameData['default'] ?? firstNameData['en'] ?? '')
          : (firstNameData ?? '');

      final lastNameData = details['lastName'];
      final lastName = lastNameData is Map
          ? (lastNameData['default'] ?? lastNameData['en'] ?? '')
          : (lastNameData ?? '');

      return '$firstName $lastName'.trim();
    } catch (e) {
      print('Error in _getPlayerName: $e');
      return '';
    }
  }

  String _formatTime(String time) {
    // Convert "12:34" format
    return time;
  }

  String _getGoalType(dynamic detailsData) {
    if (detailsData == null) return 'EV';

    try {
      final details = detailsData is Map<String, dynamic>
          ? detailsData
          : Map<String, dynamic>.from(detailsData as Map);

      final strength = details['strength']?.toString() ?? details['situationCode']?.toString() ?? '';
      if (strength.contains('PP') || strength.contains('pp')) return 'PP';
      if (strength.contains('SH') || strength.contains('sh')) return 'SH';
      return 'EV';
    } catch (e) {
      return 'EV';
    }
  }

  String _formatPlusMinus(dynamic value) {
    if (value == null) return '0';
    final num = value is int ? value : int.tryParse(value.toString()) ?? 0;
    if (num > 0) return '+$num';
    return num.toString();
  }
}