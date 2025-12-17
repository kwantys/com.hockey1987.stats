import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game.dart';

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

  /// Отримати standings (таблиця)
  Future<Map<String, dynamic>> getStandings() async {
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
      return await getStandings();
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
}