import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/game.dart';
import '../models/team_standing.dart';

/// Сервіс для роботи з новим NHL API v2
class NHLApiService {
  static const String _baseUrl = 'https://api-web.nhle.com/v1';

  /// Перевірка наявності інтернету
  Future<void> _checkConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw Exception("No internet connection available. Please try again later.");
    }
  }

  /// Отримати розклад ігор на конкретну дату
  /// Формат дати: YYYY-MM-DD (наприклад: 2024-12-16)
  Future<List<Game>> getScheduleByDate(String date) async {
    await _checkConnection();
    try {
      final url = Uri.parse('$_baseUrl/schedule/$date');

      final response = await http.get(url);

      print('API Request: $url');
      print('Response status: ${response.statusCode}');
      print('Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('JSON keys: ${jsonData.keys}');

        final gameWeek = jsonData['gameWeek'] as List?;
        print('GameWeek length: ${gameWeek?.length}');

        if (gameWeek == null || gameWeek.isEmpty) {
          print('No games in gameWeek');
          return [];
        }

        // Знайти правильний день
        final List<Game> allGames = [];
        final requestedDate = DateTime.parse(date);

        for (var day in gameWeek) {
          print('Day keys: ${day.keys}');
          final dayDate = day['date'] as String?;
          print('Processing day: $dayDate');

          // Фільтруємо тільки потрібний день
          if (dayDate != null && dayDate == date) {
            final games = day['games'] as List?;
            print('Games count for $dayDate: ${games?.length ?? 0}');

            if (games != null && games.isNotEmpty) {
              print('First game: ${games[0]}');
              allGames.addAll(games.map((json) => Game.fromNHLv2Json(json)).toList());
            }
          }
        }

        print('Total games found for $date: ${allGames.length}');
        return allGames;
      } else {
        throw Exception('Failed to load games: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getScheduleByDate: $e');
      if (e.toString().contains("No internet")) rethrow;
      throw Exception('Error fetching schedule: $e');
    }
  }

  /// Отримати поточний розклад (сьогодні)
  Future<List<Game>> getScheduleNow() async {
    await _checkConnection();
    try {
      final url = Uri.parse('$_baseUrl/schedule/now');

      final response = await http.get(url);

      print('API Request: $url');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final gameWeek = jsonData['gameWeek'] as List?;

        if (gameWeek == null || gameWeek.isEmpty) {
          return [];
        }

        final List<Game> allGames = [];
        for (var day in gameWeek) {
          final games = day['games'] as List?;
          if (games != null) {
            allGames.addAll(games.map((json) => Game.fromNHLv2Json(json)).toList());
          }
        }

        return allGames;
      } else {
        throw Exception('Failed to load games: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getScheduleNow: $e');
      if (e.toString().contains("No internet")) rethrow;
      throw Exception('Error fetching schedule: $e');
    }
  }

  /// Отримати поточні рахунки
  Future<Map<String, dynamic>> getScoresNow() async {
    await _checkConnection();
    try {
      final url = Uri.parse('$_baseUrl/score/now');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load scores: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains("No internet")) rethrow;
      throw Exception('Error fetching scores: $e');
    }
  }

  /// Отримати standings RAW data (таблиця) - повертає Map
  Future<Map<String, dynamic>> getStandingsRaw() async {
    await _checkConnection();
    try {
      final url = Uri.parse('$_baseUrl/standings/now');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load standings: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains("No internet")) rethrow;
      throw Exception('Error fetching standings: $e');
    }
  }

  /// Отримати детальну інформацію про гру (landing)
  Future<Map<String, dynamic>> getGameDetails(int gamePk) async {
    await _checkConnection();
    try {
      final url = Uri.parse('$_baseUrl/gamecenter/$gamePk/landing');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load game details: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains("No internet")) rethrow;
      throw Exception('Error fetching game details: $e');
    }
  }

  /// Отримати play-by-play для гри (детальні події)
  Future<Map<String, dynamic>> getGamePlayByPlay(int gamePk) async {
    await _checkConnection();
    try {
      final url = Uri.parse('$_baseUrl/gamecenter/$gamePk/play-by-play');

      final response = await http.get(url);

      print('PlayByPlay Request: $url');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load play-by-play: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getGamePlayByPlay: $e');
      if (e.toString().contains("No internet")) rethrow;
      throw Exception('Error fetching play-by-play: $e');
    }
  }

  /// Отримати boxscore для гри (детальна статистика)
  Future<Map<String, dynamic>> getGameBoxscore(int gamePk) async {
    await _checkConnection();
    try {
      final url = Uri.parse('$_baseUrl/gamecenter/$gamePk/boxscore');

      final response = await http.get(url);

      print('Boxscore Request: $url');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load boxscore: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getGameBoxscore: $e');
      if (e.toString().contains("No internet")) rethrow;
      throw Exception('Error fetching boxscore: $e');
    }
  }

  /// Отримати список команд
  Future<Map<String, dynamic>> getTeams() async {
    return await getStandingsRaw();
  }

  /// Отримати статистику гравця (season stats)
  Future<Map<String, dynamic>> getPlayerStats(int playerId) async {
    await _checkConnection();
    try {
      final url = Uri.parse('$_baseUrl/player/$playerId/landing');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load player stats: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains("No internet")) rethrow;
      throw Exception('Error fetching player stats: $e');
    }
  }

  /// Отримати standings як список TeamStanding об'єктів
  Future<List<TeamStanding>> getStandings() async {
    await _checkConnection();
    try {
      final url = Uri.parse('$_baseUrl/standings/now');
      final response = await http.get(url);

      print('API Request: $url');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final standings = jsonData['standings'] as List?;

        if (standings == null || standings.isEmpty) {
          print('No standings found in response');
          return [];
        }

        print('Found ${standings.length} teams in standings');

        return standings
            .map((json) => TeamStanding.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load standings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getStandings: $e');
      if (e.toString().contains("No internet")) rethrow;
      throw Exception('Error fetching standings: $e');
    }
  }

  /// Отримати інформацію про команду
  Future<Map<String, dynamic>> getTeamInfo(int teamId) async {
    await _checkConnection();
    try {
      print('🔍 Searching for team $teamId in standings...');

      final standingsData = await getStandingsRaw();
      final standingsList = standingsData['standings'] as List? ?? [];

      for (var teamData in standingsList) {
        String targetAbbrev = _getTeamAbbrevById(teamId);

        final abbrevMap = teamData['teamAbbrev'];
        String currentAbbrev = '';
        if (abbrevMap is Map) {
          currentAbbrev = abbrevMap['default']?.toString() ?? '';
        } else {
          currentAbbrev = abbrevMap?.toString() ?? '';
        }

        if (currentAbbrev == targetAbbrev) {
          final mutableMap = Map<String, dynamic>.from(teamData);
          mutableMap['id'] = teamId;
          mutableMap['teamId'] = teamId;
          return mutableMap;
        }
      }

      throw Exception('Team $teamId not found in standings');
    } catch (e) {
      print('Error in getTeamInfo: $e');
      if (e.toString().contains("No internet")) rethrow;
      throw Exception('Error fetching team info: $e');
    }
  }

  String _getTeamAbbrevById(int id) {
    const map = {
      1: 'NJD', 2: 'NYI', 3: 'NYR', 4: 'PHI', 5: 'PIT', 6: 'BOS', 7: 'BUF', 8: 'MTL',
      9: 'OTT', 10: 'TOR', 12: 'CAR', 13: 'FLA', 14: 'TBL', 15: 'WSH', 16: 'CHI',
      17: 'DET', 18: 'NSH', 19: 'STL', 20: 'CGY', 21: 'COL', 22: 'EDM', 23: 'VAN',
      24: 'ANA', 25: 'DAL', 26: 'LAK', 28: 'SJS', 29: 'CBJ', 30: 'MIN', 52: 'WPG',
      53: 'ARI', 54: 'VGK', 55: 'SEA', 59: 'UTA'
    };
    return map[id] ?? '';
  }

  Future<Map<String, dynamic>> getTeamRoster(int teamId, {String? teamAbbrev}) async {
    await _checkConnection();
    try {
      print('🏒 Loading roster for team $teamId');

      String abbrev = teamAbbrev ?? '';

      if (abbrev.isEmpty) {
        try {
          final teamInfo = await getTeamInfo(teamId);
          final teamAbbrevData = teamInfo['teamAbbrev'];
          abbrev = teamAbbrevData is Map
              ? (teamAbbrevData['default'] ?? '')
              : teamAbbrevData.toString();
        } catch (e) {
          print('   ⚠️ Could not fetch team info for abbrev: $e');
        }
      }

      print('   Team abbrev: $abbrev');

      if (abbrev.isNotEmpty) {
        try {
          final url = Uri.parse('$_baseUrl/roster/$abbrev/20242025');
          print('   Trying new API: $url');

          final response = await http.get(url);

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            print('   ✅ New API worked! Keys: ${data.keys}');

            final forwards = data['forwards'] as List? ?? [];
            final defensemen = data['defensemen'] as List? ?? [];
            final goalies = data['goalies'] as List? ?? [];

            print('   Found: ${forwards.length}F, ${defensemen.length}D, ${goalies.length}G');

            if (forwards.isNotEmpty || defensemen.isNotEmpty || goalies.isNotEmpty) {
              return {
                'forwards': forwards,
                'defensemen': defensemen,
                'goalies': goalies,
              };
            }
          }
        } catch (e) {
          print('   ❌ New API failed: $e');
        }
      }

      // Резервний варіант зі старим API
      try {
        final oldApiUrl = 'https://statsapi.web.nhl.com/api/v1/teams/$teamId/roster';
        final url = Uri.parse(oldApiUrl);
        print('   Trying old Stats API: $url');

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final rosterData = data['roster'] as List? ?? [];

          if (rosterData.isNotEmpty) {
            final forwards = <Map<String, dynamic>>[];
            final defensemen = <Map<String, dynamic>>[];
            final goalies = <Map<String, dynamic>>[];

            for (var player in rosterData) {
              final person = player['person'] ?? {};
              final position = player['position'] ?? {};
              final posCode = position['abbreviation'] ?? position['code'] ?? '';

              final playerData = {
                'playerId': person['id'],
                'firstName': person['firstName'] ?? '',
                'lastName': person['lastName'] ?? '',
                'fullName': person['fullName'] ?? '',
                'sweaterNumber': player['jerseyNumber'] ?? 0,
                'positionCode': posCode,
                'shootsCatches': person['shootsCatches'] ?? '',
                'gamesPlayed': 0, 'goals': 0, 'assists': 0, 'points': 0,
              };

              if (posCode == 'C' || posCode == 'L' || posCode == 'R' || posCode == 'LW' || posCode == 'RW') {
                forwards.add(playerData);
              } else if (posCode == 'D') {
                defensemen.add(playerData);
              } else if (posCode == 'G') {
                goalies.add(playerData);
              }
            }
            return {'forwards': forwards, 'defensemen': defensemen, 'goalies': goalies};
          }
        }
      } catch (e) {
        print('   ❌ Old API failed: $e');
      }

      return {'forwards': [], 'defensemen': [], 'goalies': []};
    } catch (e) {
      print('❌ Error in getTeamRoster: $e');
      if (e.toString().contains("No internet")) rethrow;
      return {'forwards': [], 'defensemen': [], 'goalies': []};
    }
  }

  Future<Map<String, dynamic>> getTeamSchedule(int teamId) async {
    await _checkConnection();
    try {
      print('Loading schedule for team $teamId');

      final now = DateTime.now();
      final allGames = <Map<String, dynamic>>[];

      for (int i = 0; i < 60; i++) {
        final date = now.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        try {
          final games = await getScheduleByDate(dateStr);

          for (var game in games) {
            final isTeamGame = game.homeTeamId == teamId || game.awayTeamId == teamId;
            final isFutureGame = game.status == 'FUT' || game.status == 'PREVIEW';

            if (isTeamGame && isFutureGame) {
              allGames.add({
                'id': game.gameId,
                'startTimeUTC': game.dateTime.toIso8601String(),
                'gameDate': game.dateTime.toIso8601String(),
                'gameState': game.status,
                'homeTeam': {'id': game.homeTeamId, 'name': {'default': game.homeTeamName}, 'abbrev': {'default': _extractAbbrev(game.homeTeamName)}},
                'awayTeam': {'id': game.awayTeamId, 'name': {'default': game.awayTeamName}, 'abbrev': {'default': _extractAbbrev(game.awayTeamName)}},
                'venue': {'default': game.venue ?? ''},
              });
              if (allGames.length >= 5) break;
            }
          }
          if (allGames.length >= 5) break;
        } catch (e) {
          continue;
        }
      }
      return {'games': allGames};
    } catch (e) {
      if (e.toString().contains("No internet")) rethrow;
      return {'games': []};
    }
  }

  String _extractAbbrev(String teamName) {
    final words = teamName.split(' ');
    if (words.isNotEmpty) {
      return words.last.substring(0, 3).toUpperCase();
    }
    return teamName.substring(0, 3).toUpperCase();
  }

  /// Отримати статистику команди
  Future<Map<String, dynamic>> getTeamStats(int teamId) async {
    await _checkConnection();
    try {
      final url = Uri.parse('$_baseUrl/club-stats/$teamId/now');

      final response = await http.get(url);

      print('Team Stats Request: $url');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load team stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTeamStats: $e');
      if (e.toString().contains("No internet")) rethrow;
      throw Exception('Error fetching team stats: $e');
    }
  }

  /// Отримати об'єкт Game за ID
  Future<Game> getGameById(int gameId) async {
    await _checkConnection();
    try {
      final data = await getGameDetails(gameId);
      return Game.fromNHLv2Json(data);
    } catch (e) {
      print('Error in getGameById: $e');
      if (e.toString().contains("No internet")) rethrow;
      throw Exception('Failed to load game $gameId');
    }
  }

  /// Отримати детальну інформацію про гравця (Landing)
  Future<Map<String, dynamic>> getPlayerLanding(int playerId) async {
    await _checkConnection();
    try {
      final url = Uri.parse('$_baseUrl/player/$playerId/landing');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load player landing: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching player landing: $e');
      if (e.toString().contains("No internet")) rethrow;
      rethrow;
    }
  }

  /// Отримати лог ігор гравця
  Future<Map<String, dynamic>> getPlayerGameLog(int playerId) async {
    await _checkConnection();
    try {
      final url = Uri.parse('$_baseUrl/player/$playerId/game-log/now');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load player game log: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching player game log: $e');
      if (e.toString().contains("No internet")) rethrow;
      return {'gameLog': []};
    }
  }

  /// Список всіх команд
  Future<List<Map<String, dynamic>>> getAllTeams() async {
    return [
      {'id': 6, 'name': 'Boston Bruins', 'division': 'Atlantic', 'abbreviation': 'BOS'},
      {'id': 7, 'name': 'Buffalo Sabres', 'division': 'Atlantic', 'abbreviation': 'BUF'},
      {'id': 17, 'name': 'Detroit Red Wings', 'division': 'Atlantic', 'abbreviation': 'DET'},
      {'id': 13, 'name': 'Florida Panthers', 'division': 'Atlantic', 'abbreviation': 'FLA'},
      {'id': 8, 'name': 'Montréal Canadiens', 'division': 'Atlantic', 'abbreviation': 'MTL'},
      {'id': 9, 'name': 'Ottawa Senators', 'division': 'Atlantic', 'abbreviation': 'OTT'},
      {'id': 14, 'name': 'Tampa Bay Lightning', 'division': 'Atlantic', 'abbreviation': 'TBL'},
      {'id': 10, 'name': 'Toronto Maple Leafs', 'division': 'Atlantic', 'abbreviation': 'TOR'},
      {'id': 12, 'name': 'Carolina Hurricanes', 'division': 'Metropolitan', 'abbreviation': 'CAR'},
      {'id': 29, 'name': 'Columbus Blue Jackets', 'division': 'Metropolitan', 'abbreviation': 'CBJ'},
      {'id': 1, 'name': 'New Jersey Devils', 'division': 'Metropolitan', 'abbreviation': 'NJD'},
      {'id': 2, 'name': 'New York Islanders', 'division': 'Metropolitan', 'abbreviation': 'NYI'},
      {'id': 3, 'name': 'New York Rangers', 'division': 'Metropolitan', 'abbreviation': 'NYR'},
      {'id': 4, 'name': 'Philadelphia Flyers', 'division': 'Metropolitan', 'abbreviation': 'PHI'},
      {'id': 5, 'name': 'Pittsburgh Penguins', 'division': 'Metropolitan', 'abbreviation': 'PIT'},
      {'id': 15, 'name': 'Washington Capitals', 'division': 'Metropolitan', 'abbreviation': 'WSH'},
      {'id': 16, 'name': 'Chicago Blackhawks', 'division': 'Central', 'abbreviation': 'CHI'},
      {'id': 21, 'name': 'Colorado Avalanche', 'division': 'Central', 'abbreviation': 'COL'},
      {'id': 25, 'name': 'Dallas Stars', 'division': 'Central', 'abbreviation': 'DAL'},
      {'id': 30, 'name': 'Minnesota Wild', 'division': 'Central', 'abbreviation': 'MIN'},
      {'id': 18, 'name': 'Nashville Predators', 'division': 'Central', 'abbreviation': 'NSH'},
      {'id': 19, 'name': 'St. Louis Blues', 'division': 'Central', 'abbreviation': 'STL'},
      {'id': 52, 'name': 'Winnipeg Jets', 'division': 'Central', 'abbreviation': 'WPG'},
      {'id': 24, 'name': 'Anaheim Ducks', 'division': 'Pacific', 'abbreviation': 'ANA'},
      {'id': 20, 'name': 'Calgary Flames', 'division': 'Pacific', 'abbreviation': 'CGY'},
      {'id': 22, 'name': 'Edmonton Oilers', 'division': 'Pacific', 'abbreviation': 'EDM'},
      {'id': 26, 'name': 'Los Angeles Kings', 'division': 'Pacific', 'abbreviation': 'LAK'},
      {'id': 28, 'name': 'San Jose Sharks', 'division': 'Pacific', 'abbreviation': 'SJS'},
      {'id': 55, 'name': 'Seattle Kraken', 'division': 'Pacific', 'abbreviation': 'SEA'},
      {'id': 23, 'name': 'Vancouver Canucks', 'division': 'Pacific', 'abbreviation': 'VAN'},
      {'id': 54, 'name': 'Vegas Golden Knights', 'division': 'Pacific', 'abbreviation': 'VGK'},
      {'id': 59, 'name': 'Utah Hockey Club', 'division': 'Central', 'abbreviation': 'UTA'},
    ];
  }

  /// Універсальний метод _get
  Future<Map<String, dynamic>> _get(String endpoint) async {
    await _checkConnection();
    try {
      final response = await http.get(Uri.parse('$_baseUrl$endpoint'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains("No internet")) rethrow;
      throw Exception('Network error: $e');
    }
  }
}