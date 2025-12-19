import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервіс для кешування даних команд з TTL (Time To Live)
class TeamCacheService {
  static const String _cachePrefix = 'team_cache_';
  static const String _timestampPrefix = 'team_timestamp_';
  static const Duration _cacheDuration = Duration(hours: 3); // TTL = 3 години

  /// Зберегти дані команди в кеш
  static Future<void> cacheTeamData({
    required int teamId,
    required Map<String, dynamic> teamInfo,
    required Map<String, dynamic> roster,
    required Map<String, dynamic> schedule,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Зберігаємо дані
      await prefs.setString(
        '${_cachePrefix}info_$teamId',
        json.encode(teamInfo),
      );
      await prefs.setString(
        '${_cachePrefix}roster_$teamId',
        json.encode(roster),
      );
      await prefs.setString(
        '${_cachePrefix}schedule_$teamId',
        json.encode(schedule),
      );

      // Зберігаємо timestamp
      await prefs.setInt(
        '${_timestampPrefix}$teamId',
        timestamp,
      );

      print('💾 Team $teamId cached at ${DateTime.now()}');
    } catch (e) {
      print('⚠️ Error caching team data: $e');
    }
  }

  /// Отримати дані команди з кешу (якщо актуальні)
  static Future<Map<String, dynamic>?> getCachedTeamData(int teamId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Перевіряємо timestamp
      final timestamp = prefs.getInt('${_timestampPrefix}$teamId');
      if (timestamp == null) {
        print('📭 No cache for team $teamId');
        return null;
      }

      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      final cacheAgeDuration = Duration(milliseconds: cacheAge);

      // Якщо кеш застарілий - видаляємо його
      if (cacheAgeDuration > _cacheDuration) {
        print('⏰ Cache expired for team $teamId (age: ${cacheAgeDuration.inHours}h)');
        await clearTeamCache(teamId);
        return null;
      }

      // Завантажуємо дані з кешу
      final teamInfoJson = prefs.getString('${_cachePrefix}info_$teamId');
      final rosterJson = prefs.getString('${_cachePrefix}roster_$teamId');
      final scheduleJson = prefs.getString('${_cachePrefix}schedule_$teamId');

      if (teamInfoJson == null || rosterJson == null || scheduleJson == null) {
        print('❌ Incomplete cache for team $teamId');
        return null;
      }

      print('✅ Cache hit for team $teamId (age: ${cacheAgeDuration.inMinutes}min)');

      return {
        'teamInfo': json.decode(teamInfoJson),
        'roster': json.decode(rosterJson),
        'schedule': json.decode(scheduleJson),
      };
    } catch (e) {
      print('⚠️ Error reading cache: $e');
      return null;
    }
  }

  /// Видалити кеш команди
  static Future<void> clearTeamCache(int teamId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cachePrefix}info_$teamId');
      await prefs.remove('${_cachePrefix}roster_$teamId');
      await prefs.remove('${_cachePrefix}schedule_$teamId');
      await prefs.remove('${_timestampPrefix}$teamId');
      print('🗑️ Cache cleared for team $teamId');
    } catch (e) {
      print('⚠️ Error clearing cache: $e');
    }
  }

  /// Видалити весь кеш (для налаштувань)
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (var key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
          await prefs.remove(key);
        }
      }

      print('🗑️ All team cache cleared');
    } catch (e) {
      print('⚠️ Error clearing all cache: $e');
    }
  }

  /// Перевірити чи є валідний кеш
  static Future<bool> hasValidCache(int teamId) async {
    final cachedData = await getCachedTeamData(teamId);
    return cachedData != null;
  }

  /// Отримати вік кешу
  static Future<Duration?> getCacheAge(int teamId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('${_timestampPrefix}$teamId');

      if (timestamp == null) return null;

      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      return Duration(milliseconds: age);
    } catch (e) {
      return null;
    }
  }
}