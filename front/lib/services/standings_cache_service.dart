import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервіс для кешування турнірної таблиці (Standings)
class StandingsCacheService {
  static const String _cacheKey = 'standings_cache_data';
  static const String _timestampKey = 'standings_cache_timestamp';
  static const Duration _cacheDuration = Duration(hours: 6); // TTL = 6 годин

  /// Зберегти standings в кеш
  static Future<void> cacheStandings(Map<String, dynamic> standingsData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Зберігаємо дані
      await prefs.setString(_cacheKey, json.encode(standingsData));

      // Зберігаємо timestamp
      await prefs.setInt(_timestampKey, timestamp);

      print('💾 Standings cached at ${DateTime.now()}');
    } catch (e) {
      print('⚠️ Error caching standings: $e');
    }
  }

  /// Отримати standings з кешу (якщо актуальні)
  static Future<Map<String, dynamic>?> getCachedStandings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Перевіряємо timestamp
      final timestamp = prefs.getInt(_timestampKey);
      if (timestamp == null) {
        print('📭 No standings cache');
        return null;
      }

      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      final cacheAgeDuration = Duration(milliseconds: cacheAge);

      // Якщо кеш застарілий - видаляємо його
      if (cacheAgeDuration > _cacheDuration) {
        print('⏰ Standings cache expired (age: ${cacheAgeDuration.inHours}h)');
        await clearCache();
        return null;
      }

      // Завантажуємо дані з кешу
      final standingsJson = prefs.getString(_cacheKey);
      if (standingsJson == null) {
        print('❌ No standings data in cache');
        return null;
      }

      print('✅ Standings cache hit (age: ${cacheAgeDuration.inMinutes}min)');
      return json.decode(standingsJson);
    } catch (e) {
      print('⚠️ Error reading standings cache: $e');
      return null;
    }
  }

  /// Видалити кеш standings
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_timestampKey);
      print('🗑️ Standings cache cleared');
    } catch (e) {
      print('⚠️ Error clearing standings cache: $e');
    }
  }

  /// Перевірити чи є валідний кеш
  static Future<bool> hasValidCache() async {
    final cachedData = await getCachedStandings();
    return cachedData != null;
  }

  /// Отримати вік кешу
  static Future<Duration?> getCacheAge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey);

      if (timestamp == null) return null;

      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      return Duration(milliseconds: age);
    } catch (e) {
      return null;
    }
  }

  /// Отримати час останнього оновлення
  static Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey);

      if (timestamp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }
}