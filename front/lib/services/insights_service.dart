import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/team_insight.dart';
import '../models/team_models.dart';
import '../models/game.dart';
import 'nhl_api_service.dart';

/// Сервіс для розрахунку аналітичних інсайтів команд
class InsightsService {
  static const String _cacheKey = 'insights_cache';
  static const Duration _cacheExpiry = Duration(hours: 6);

  final NHLApiService _apiService = NHLApiService();

  /// Завантажити hot streaks (з кешем)
  Future<List<TeamInsight>> getHotStreaks({int gamesRange = 10}) async {
    try {
      // Спробувати завантажити з кешу
      final cached = await _loadFromCache();

      if (cached != null && cached.isNotEmpty) {
        print('📊 Loaded ${cached.length} insights from cache');
        return _filterByRange(cached, gamesRange);
      }

      // Якщо кешу немає або застарів - рахуємо з нуля
      print('📊 Calculating fresh insights...');
      final insights = await _calculateAllInsights();

      // Зберігаємо в кеш
      await _saveToCache(insights);

      return _filterByRange(insights, gamesRange);
    } catch (e) {
      print('Error loading hot streaks: $e');
      return [];
    }
  }

  /// Отримати інсайти для конкретної команди
  Future<TeamInsight?> getTeamInsight(int teamId, {int gamesRange = 10}) async {
    try {
      final insights = await getHotStreaks(gamesRange: gamesRange);
      return insights.firstWhere((i) => i.teamId == teamId);
    } catch (e) {
      print('Error loading team insight: $e');
      return null;
    }
  }

  /// Отримати інсайти для обраних команд
  Future<List<TeamInsight>> getFavoritesInsights(List<int> favoriteTeamIds) async {
    try {
      final allInsights = await getHotStreaks(gamesRange: 10);
      return allInsights.where((i) => favoriteTeamIds.contains(i.teamId)).toList();
    } catch (e) {
      print('Error loading favorites insights: $e');
      return [];
    }
  }

  /// Очистити кеш (для ручного оновлення)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove('${_cacheKey}_timestamp');
      print('✅ Insights cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // === ПРИВАТНІ МЕТОДИ ===

  /// Розрахувати інсайти для всіх команд
  Future<List<TeamInsight>> _calculateAllInsights() async {
    print('📊 Starting insights calculation...');
    final insights = <TeamInsight>[];

    // Отримати список всіх команд
    final teams = await _apiService.getAllTeams();
    print('📋 Found ${teams.length} teams');

    // Завантажуємо всі завершені ігри за останні 45 днів одним разом
    final allRecentGames = await _loadAllRecentGames(45);

    if (allRecentGames.isEmpty) {
      print('⚠️ WARNING: No games loaded! Check API or date range.');
      // Повертаємо порожні інсайти для всіх команд
      for (var team in teams) {
        final teamId = team['id'] as int;
        insights.add(_createEmptyInsight(teamId, team));
      }
      return insights;
    }

    print('🎮 Processing ${teams.length} teams with ${allRecentGames.length} games...');

    for (var team in teams) {
      try {
        final teamId = team['id'] as int;
        final insight = await _calculateTeamInsightFromGames(teamId, team, allRecentGames);
        insights.add(insight);
      } catch (e) {
        print('❌ Error calculating insight for team ${team['name']}: $e');
        // Додаємо порожній інсайт замість пропуску
        final teamId = team['id'] as int;
        insights.add(_createEmptyInsight(teamId, team));
      }
    }

    print('✅ Calculated ${insights.length} team insights');
    return insights;
  }

  /// Завантажити всі завершені ігри за останні N днів
  Future<List<Game>> _loadAllRecentGames(int days) async {
    print('🔍 Loading recent games for last $days days...');
    final now = DateTime.now();
    final allGames = <Game>[];

    for (int i = 1; i <= days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      try {
        final games = await _apiService.getScheduleByDate(dateStr);

        for (var game in games) {
          if (game.isFinal == true) {
            allGames.add(game);
          }
        }
      } catch (e) {
        print('⚠️ Failed to load games for $dateStr: $e');
        // Продовжуємо навіть якщо одна дата не завантажилась
        continue;
      }
    }

    print('✅ Loaded ${allGames.length} total completed games');
    return allGames;
  }

  /// Розрахувати інсайт для команди з готового списку ігор
  Future<TeamInsight> _calculateTeamInsightFromGames(
      int teamId,
      Map<String, dynamic> teamData,
      List<Game> allGames,
      ) async {
    // Фільтруємо ігри цієї команди
    final teamGames = allGames
        .where((g) =>
    (g.homeTeamId != null && g.homeTeamId == teamId) ||
        (g.awayTeamId != null && g.awayTeamId == teamId))
        .take(20)
        .toList();

    if (teamGames.isEmpty) {
      print('No completed games found for team $teamId');
      return _createEmptyInsight(teamId, teamData);
    }

    print('Team $teamId: Found ${teamGames.length} completed games');

    // Рахуємо статистику
    int wins = 0, losses = 0, otLosses = 0;
    int totalGoalsFor = 0, totalGoalsAgainst = 0;

    final pointsPerGame = <double>[];
    final goalsFor = <int>[];
    final goalsAgainst = <int>[];
    final shotsFor = <int>[];
    final shotsAgainst = <int>[];

    int ppGoals = 0, ppOpportunities = 0;
    int pkGoalsAgainst = 0, pkOpportunities = 0;

    for (var game in teamGames) {
      // Перевірка на null для teamId
      if (game.homeTeamId == null || game.awayTeamId == null) continue;

      final isHome = game.homeTeamId == teamId;
      final teamScore = (isHome ? game.homeTeamScore : game.awayTeamScore) ?? 0;
      final oppScore = (isHome ? game.awayTeamScore : game.homeTeamScore) ?? 0;

      // Пропускаємо ігри без скору
      if (teamScore == 0 && oppScore == 0) continue;

      // W-L-OTL
      if (teamScore > oppScore) {
        wins++;
        // 2 points for win
        pointsPerGame.add(2.0);
      } else if (teamScore < oppScore) {
        // Перевіряємо чи це OT/SO програш (період > 3)
        if (game.period != null && game.period! > 3) {
          otLosses++;
          pointsPerGame.add(1.0); // 1 point for OT loss
        } else {
          losses++;
          pointsPerGame.add(0.0);
        }
      }

      totalGoalsFor += teamScore;
      totalGoalsAgainst += oppScore;

      goalsFor.add(teamScore);
      goalsAgainst.add(oppScore);

      shotsFor.add(teamScore * 3); // Mock data
      shotsAgainst.add(oppScore * 3);
    }

    final goalDiff = totalGoalsFor - totalGoalsAgainst;
    final streakLabel = _determineStreakLabel(wins, losses, otLosses);

    // PP% та PK%
    final ppPercent = ppOpportunities > 0
        ? (ppGoals / ppOpportunities * 100)
        : 20.0;
    final pkPercent = pkOpportunities > 0
        ? ((pkOpportunities - pkGoalsAgainst) / pkOpportunities * 100)
        : 80.0;

    return TeamInsight(
      teamId: teamId,
      teamName: teamData['name'] ?? 'Unknown',
      teamAbbrev: teamData['abbreviation'] ?? 'UNK',
      teamLogo: _getTeamLogo(teamData['abbreviation']),
      wins: wins,
      losses: losses,
      otLosses: otLosses,
      goalDifferential: goalDiff,
      streakLabel: streakLabel,
      pointsPerGame: pointsPerGame,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      shotsFor: shotsFor,
      shotsAgainst: shotsAgainst,
      powerPlayPercent: ppPercent,
      penaltyKillPercent: pkPercent,
    );
  }

  /// Отримати останні ігри команди
  Future<List<Game>> _getTeamRecentGames(int teamId, int count) async {
    try {
      final now = DateTime.now();
      final recentGames = <Game>[];

      print('Loading recent games for team $teamId...');

      // Шукаємо завершені ігри за останні 60 днів (у минулому)
      for (int i = 1; i <= 60 && recentGames.length < count; i++) {
        final date = now.subtract(Duration(days: i));
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        try {
          final games = await _apiService.getScheduleByDate(dateStr);

          // Фільтруємо ігри цієї команди
          for (var game in games) {
            final isTeamGame = game.homeTeamId == teamId || game.awayTeamId == teamId;

            if (isTeamGame && game.isFinal) {
              recentGames.add(game);
              print('Found completed game: ${game.awayTeamName} @ ${game.homeTeamName}, score: ${game.awayTeamScore}-${game.homeTeamScore}');

              if (recentGames.length >= count) break;
            }
          }
        } catch (e) {
          // Продовжуємо пошук навіть якщо одна дата не завантажилась
          continue;
        }
      }

      print('Loaded ${recentGames.length} completed games for team $teamId');
      return recentGames;
    } catch (e) {
      print('Error loading team games: $e');
      return [];
    }
  }

  /// Визначити streak label
  String _determineStreakLabel(int wins, int losses, int otLosses) {
    final total = wins + losses + otLosses;
    if (total == 0) return 'Unknown';

    final winRate = wins / total;

    if (winRate >= 0.7) return 'On fire';
    if (winRate >= 0.5) return 'Heating up';
    return 'Cooling down';
  }

  /// Створити порожній інсайт
  TeamInsight _createEmptyInsight(int teamId, Map<String, dynamic> teamData) {
    return TeamInsight(
      teamId: teamId,
      teamName: teamData['name'] ?? 'Unknown',
      teamAbbrev: teamData['abbreviation'] ?? 'UNK',
      teamLogo: _getTeamLogo(teamData['abbreviation']),
      wins: 0,
      losses: 0,
      otLosses: 0,
      goalDifferential: 0,
      streakLabel: 'Unknown',
      pointsPerGame: [],
      goalsFor: [],
      goalsAgainst: [],
      shotsFor: [],
      shotsAgainst: [],
      powerPlayPercent: 0.0,
      penaltyKillPercent: 0.0,
    );
  }

  /// Отримати лого команди
  String? _getTeamLogo(String? abbrev) {
    if (abbrev == null || abbrev.isEmpty) return null;
    return 'https://assets.nhle.com/logos/nhl/svg/${abbrev}_light.svg';
  }

  /// Фільтрувати інсайти по діапазону ігор
  List<TeamInsight> _filterByRange(List<TeamInsight> insights, int gamesRange) {
    // Фільтруємо дані по останніх N іграх
    return insights.map((insight) {
      // Якщо даних менше ніж потрібно, повертаємо оригінал
      if (insight.pointsPerGame.isEmpty || insight.pointsPerGame.length <= gamesRange) {
        return insight;
      }

      // Обрізаємо масиви до потрібної кількості ігор
      final filteredPointsPerGame = insight.pointsPerGame.take(gamesRange).toList();
      final filteredGoalsFor = insight.goalsFor.take(gamesRange).toList();
      final filteredGoalsAgainst = insight.goalsAgainst.take(gamesRange).toList();
      final filteredShotsFor = insight.shotsFor.take(gamesRange).toList();
      final filteredShotsAgainst = insight.shotsAgainst.take(gamesRange).toList();

      // Перевірка на порожні списки
      if (filteredPointsPerGame.isEmpty) {
        return insight;
      }

      // Перераховуємо статистику
      int wins = 0;
      int losses = 0;
      int otLosses = 0;

      for (var points in filteredPointsPerGame) {
        if (points >= 2.0) {
          wins++;
        } else if (points == 1.0) {
          otLosses++;
        } else {
          losses++;
        }
      }

      final goalDiff = filteredGoalsFor.isEmpty ? 0 :
      (filteredGoalsFor.fold<int>(0, (sum, g) => sum + g) -
          filteredGoalsAgainst.fold<int>(0, (sum, g) => sum + g));

      final streakLabel = _determineStreakLabel(wins, losses, otLosses);

      return TeamInsight(
        teamId: insight.teamId,
        teamName: insight.teamName,
        teamAbbrev: insight.teamAbbrev,
        teamLogo: insight.teamLogo,
        wins: wins,
        losses: losses,
        otLosses: otLosses,
        goalDifferential: goalDiff,
        streakLabel: streakLabel,
        pointsPerGame: filteredPointsPerGame,
        goalsFor: filteredGoalsFor,
        goalsAgainst: filteredGoalsAgainst,
        shotsFor: filteredShotsFor,
        shotsAgainst: filteredShotsAgainst,
        powerPlayPercent: insight.powerPlayPercent,
        penaltyKillPercent: insight.penaltyKillPercent,
      );
    }).toList();
  }

  /// Завантажити з кешу
  Future<List<TeamInsight>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Перевірити час останнього оновлення
      final timestamp = prefs.getInt('${_cacheKey}_timestamp');
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();

        if (now.difference(cacheTime) > _cacheExpiry) {
          print('⏰ Cache expired (${now.difference(cacheTime).inHours}h old)');
          return null;
        }
      }

      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) return null;

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((json) => TeamInsight.fromJson(json)).toList();
    } catch (e) {
      print('Error loading from cache: $e');
      return null;
    }
  }

  /// Зберегти в кеш
  Future<void> _saveToCache(List<TeamInsight> insights) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jsonList = insights.map((i) => i.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt('${_cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);

      print('💾 Saved ${insights.length} insights to cache');
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }
}