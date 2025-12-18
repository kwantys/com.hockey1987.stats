import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../shared/services/logger.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final notifications = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await notifications.initialize(const InitializationSettings(android: androidSettings));

    final String title = inputData?['title'] ?? 'NHL Game Alert';
    final String body = inputData?['body'] ?? 'Match is starting!';

    await notifications.show(
      inputData?['id'] ?? 0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'game_notifications',
          'Game Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
    return true;
  });
}

class NotificationService {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
    AppLogger.i('Notification Service (WorkManager) initialized');
  }

  static Future<void> scheduleMatchAlert({
    required int gameId,
    required String teamNames,
    required DateTime startTime,
  }) async {
    final delay = startTime.difference(DateTime.now());

    if (delay.isNegative) return;

    await Workmanager().registerOneOffTask(
      'match_$gameId',
      'show_notification',
      initialDelay: delay,
      inputData: {
        'id': gameId,
        'title': 'Puck Drop! 🏒',
        'body': '$teamNames is starting now.',
      },
    );
    AppLogger.d('Scheduled alert for $gameId in ${delay.inMinutes} mins');
  }

  static Future<void> cancelMatchAlert(int gameId) async {
    try {
      // Скасовуємо завдання початку матчу
      await Workmanager().cancelByUniqueName('match_$gameId');
      // Скасовуємо завдання фінального рахунку
      await Workmanager().cancelByUniqueName('match_${gameId + 1000000}');

      AppLogger.d('🗑️ All alerts cancelled for game: $gameId');
    } catch (e, stack) {
      AppLogger.e('Failed to cancel alerts', e, stack);
    }
  }
}