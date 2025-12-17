import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/game.dart';
import '../models/team_standing.dart';

/// Сервіс для роботи з новим NHL API v2
class NHLApiService {
  static const String _baseUrl = 'https://api-web.nhle.com/v1';

  /// Отримати розклад ігор на конкретну дату
  /// Формат дати: YYYY-MM-DD (наприклад: 2024-12-16)
  Future<List<Game>> getScheduleByDate(String date) async {
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
      throw Exception('Error fetching schedule: $e');
    }
  }

  /// Отримати поточний розклад (сьогодні)
  Future<List<Game>> getScheduleNow() async {
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
      throw Exception('Error fetching schedule: $e');
    }
  }

  /// Отримати поточні рахунки
  Future<Map<String, dynamic>> getScoresNow() async {
    try {
      final url = Uri.parse('$_baseUrl/score/now');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load scores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching scores: $e');
    }
  }

  /// Отримати standings RAW data (таблиця) - повертає Map
  /// Використовується для інших цілей
  Future<Map<String, dynamic>> getStandingsRaw() async {
    try {
      final url = Uri.parse('$_baseUrl/standings/now');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load standings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching standings: $e');
    }
  }

  /// Отримати детальну інформацію про гру (landing)
  Future<Map<String, dynamic>> getGameDetails(int gamePk) async {
    try {
      final url = Uri.parse('$_baseUrl/gamecenter/$gamePk/landing');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load game details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching game details: $e');
    }
  }

  /// Отримати play-by-play для гри (детальні події)
  Future<Map<String, dynamic>> getGamePlayByPlay(int gamePk) async {
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
      throw Exception('Error fetching play-by-play: $e');
    }
  }

  /// Отримати boxscore для гри (детальна статистика)
  Future<Map<String, dynamic>> getGameBoxscore(int gamePk) async {
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
      throw Exception('Error fetching boxscore: $e');
    }
  }

  /// Отримати список команд
  Future<Map<String, dynamic>> getTeams() async {
    try {
      // У новому API немає окремого endpoint для teams
      // Можна отримати з standings
      return await getStandingsRaw(); // ЗМІНЕНО: використовуємо getStandingsRaw
    } catch (e) {
      throw Exception('Error fetching teams: $e');
    }
  }

  /// Отримати статистику гравця (season stats)
  Future<Map<String, dynamic>> getPlayerStats(int playerId) async {
    try {
      final url = Uri.parse('$_baseUrl/player/$playerId/landing');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load player stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching player stats: $e');
    }
  }

  /// Отримати standings як список TeamStanding об'єктів
  /// Використовується в StandingsScreen
  Future<List<TeamStanding>> getStandings() async {
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

        // 🔍 DEBUG: Подивитись на перший team
        if (standings.isNotEmpty) {
          print('=== FIRST TEAM DEBUG ===');
          print('Keys: ${standings[0].keys}');
          print('teamId: ${standings[0]['teamId']}');
          print('teamCommonName: ${standings[0]['teamCommonName']}');
          print('teamAbbrev: ${standings[0]['teamAbbrev']}');
          print('divisionName: ${standings[0]['divisionName']}');
          print('conferenceName: ${standings[0]['conferenceName']}');
          print('=======================');
        }

        return standings
            .map((json) => TeamStanding.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load standings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getStandings: $e');
      throw Exception('Error fetching standings: $e');
    }
  }
  /// Отримати інформацію про команду
  Future<Map<String, dynamic>> getTeamInfo(int teamId) async {
    try {
      // NHL API не має окремого endpoint для team info
      // Можна використати standings та знайти потрібну команду
      final standings = await getStandingsRaw();
      final teams = standings['standings'] as List? ?? [];

      for (var team in teams) {
        if (team['teamId'] == teamId) {
          return team;
        }
      }

      throw Exception('Team not found');
    } catch (e) {
      print('Error in getTeamInfo: $e');
      throw Exception('Error fetching team info: $e');
    }
  }

  Future<Map<String, dynamic>> getTeamRoster(int teamId) async {
    try {
      print('🏒 Loading roster for team $teamId');

      // Спробувати новий API спочатку
      final teamInfo = await getTeamInfo(teamId);
      final teamAbbrevData = teamInfo['teamAbbrev'];
      final teamAbbrev = teamAbbrevData is Map
          ? (teamAbbrevData['default'] ?? '')
          : teamAbbrevData.toString();

      print('   Team abbrev: $teamAbbrev');

      // ВАРІАНТ 1: Новий NHL API - roster endpoint
      try {
        final url = Uri.parse('$_baseUrl/roster/$teamAbbrev/20252026');
        print('   Trying new API: $url');

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('   ✅ New API worked! Keys: ${data.keys}');

          // Витягнути гравців
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

      // ВАРІАНТ 2: Старий NHL Stats API
      try {
        final oldApiUrl = 'https://statsapi.web.nhl.com/api/v1/teams/$teamId/roster';
        final url = Uri.parse(oldApiUrl);
        print('   Trying old Stats API: $url');

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('   ✅ Old API worked! Keys: ${data.keys}');

          final rosterData = data['roster'] as List? ?? [];
          print('   Found ${rosterData.length} players');

          if (rosterData.isNotEmpty) {
            // Розділити по позиціях
            final forwards = <Map<String, dynamic>>[];
            final defensemen = <Map<String, dynamic>>[];
            final goalies = <Map<String, dynamic>>[];

            for (var player in rosterData) {
              final person = player['person'] ?? {};
              final position = player['position'] ?? {};
              final posCode = position['abbreviation'] ?? position['code'] ?? '';

              // Конвертувати в формат який очікує Player.fromJson
              final playerData = {
                'playerId': person['id'],
                'firstName': person['firstName'] ?? '',
                'lastName': person['lastName'] ?? '',
                'fullName': person['fullName'] ?? '',
                'sweaterNumber': player['jerseyNumber'] ?? 0,
                'positionCode': posCode,
                'shootsCatches': person['shootsCatches'] ?? '',
                // Статистика буде 0 бо старий API не дає її в roster
                'gamesPlayed': 0,
                'goals': 0,
                'assists': 0,
                'points': 0,
              };

              if (posCode == 'C' || posCode == 'L' || posCode == 'R' ||
                  posCode == 'LW' || posCode == 'RW') {
                forwards.add(playerData);
              } else if (posCode == 'D') {
                defensemen.add(playerData);
              } else if (posCode == 'G') {
                goalies.add(playerData);
              }
            }

            print('   Parsed: ${forwards.length}F, ${defensemen.length}D, ${goalies.length}G');

            return {
              'forwards': forwards,
              'defensemen': defensemen,
              'goalies': goalies,
            };
          }
        }
      } catch (e) {
        print('   ❌ Old API failed: $e');
      }

      print('   ⚠️ All endpoints failed, returning empty roster');
      return {
        'forwards': [],
        'defensemen': [],
        'goalies': [],
      };

    } catch (e) {
      print('❌ Error in getTeamRoster: $e');
      return {
        'forwards': [],
        'defensemen': [],
        'goalies': [],
      };
    }
  }

  Future<Map<String, dynamic>> getTeamSchedule(int teamId) async {
    try {
      print('Loading schedule for team $teamId');

      final now = DateTime.now();
      final allGames = <Map<String, dynamic>>[];

      // Шукати ігри на наступні 60 днів
      for (int i = 0; i < 60; i++) {
        final date = now.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        try {
          print('Checking date: $dateStr');
          final games = await getScheduleByDate(dateStr);

          // Фільтрувати games для цієї команди
          for (var game in games) {
            final isTeamGame = game.homeTeamId == teamId || game.awayTeamId == teamId;
            final isFutureGame = game.status == 'FUT' || game.status == 'PREVIEW';

            if (isTeamGame && isFutureGame) {
              print('Found game for team: ${game.gameId} on ${game.dateTime}');

              // Визначити opponent
              final isHome = game.homeTeamId == teamId;
              final opponentId = isHome ? game.awayTeamId : game.homeTeamId;
              final opponentName = isHome ? game.awayTeamName : game.homeTeamName;

              allGames.add({
                'id': game.gameId,
                'startTimeUTC': game.dateTime.toIso8601String(),
                'gameDate': game.dateTime.toIso8601String(),
                'gameState': game.status,
                'homeTeam': {
                  'id': game.homeTeamId,
                  'name': {'default': game.homeTeamName},
                  'abbrev': {'default': _extractAbbrev(game.homeTeamName)},
                },
                'awayTeam': {
                  'id': game.awayTeamId,
                  'name': {'default': game.awayTeamName},
                  'abbrev': {'default': _extractAbbrev(game.awayTeamName)},
                },
                'venue': {
                  'default': game.venue ?? '',
                },
              });

              // Якщо знайшли 5 ігор - достатньо
              if (allGames.length >= 5) {
                break;
              }
            }
          }

          // Якщо знайшли 5 ігор - виходимо
          if (allGames.length >= 5) {
            break;
          }
        } catch (e) {
          print('Error checking date $dateStr: $e');
          continue;
        }
      }

      print('Found ${allGames.length} future games for team $teamId');

      return {'games': allGames};
    } catch (e) {
      print('Error in getTeamSchedule: $e');
      return {'games': []};
    }
  }

  /// Допоміжний метод для витягування абревіатури з назви
  String _extractAbbrev(String teamName) {
    // Простий спосіб - взяти останнє слово
    final words = teamName.split(' ');
    if (words.isNotEmpty) {
      return words.last.substring(0, 3).toUpperCase();
    }
    return teamName.substring(0, 3).toUpperCase();
  }

  /// Отримати статистику команди
  Future<Map<String, dynamic>> getTeamStats(int teamId) async {
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
      throw Exception('Error fetching team stats: $e');
    }
  }
}