import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'models.dart';

class Reminders {
  Reminders._();
  static final Reminders instance = Reminders._();
  final plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;
  static const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'karya_reminders',
      'Kārya reminders',
      channelDescription: 'Upcoming homework and habits',
      importance: Importance.defaultImportance,
    ),
  );
  Future<void> initialize() async {
    tz.initializeTimeZones();
    await updateLocalTimezone();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('notification_icon'),
      ),
    );
    ready = true;
  }

  Future<void> updateLocalTimezone() async {
    try {
      tz.setLocalLocation(
        tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier),
      );
    } catch (_) {
      /* Device-zone resolution is best effort. */
    }
  }

  Future<bool> requestPermission() async {
    if (!ready) return false;
    final ok = await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return ok ?? false;
  }

  Future<bool> enabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications') ?? false;
  }

  /// Synchronizes only app-owned notifications. Reboot restoration is handled by
  /// plugin broadcast receivers declared in AndroidManifest.xml.
  Future<void> sync(AppData data) async {
    if (!ready) return;
    await plugin.cancelAllPendingNotifications();
    if (!await enabled()) return;
    await updateLocalTimezone();
    final now = tz.TZDateTime.now(tz.local);
    for (final task in data.tasks) {
      if (task.completed || task.reminderAt == null) continue;
      final date = DateTime.tryParse(task.reminderAt!);
      if (date == null) continue;
      final at = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        date.hour,
        date.minute,
      );
      if (at.isBefore(now)) continue;
      await plugin.zonedSchedule(
        id: task.id,
        title: 'Homework reminder',
        body: task.title,
        scheduledDate: at,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'task:${task.id}',
      );
    }
    for (final habit in data.habits.where(
      (h) => !h.archived && h.reminder != null,
    )) {
      final parts = habit.reminder!.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;
      for (var weekday = 1; weekday <= 7; weekday++) {
        // Only future scheduled days. Repeat weekly. Historical schedule
        // revisions do not alter what is due in the future.
        final localNow = DateTime.now();
        final date = DateTime(
          localNow.year,
          localNow.month,
          localNow.day + (weekday - localNow.weekday + 7) % 7,
        );
        var candidate = tz.TZDateTime(
          tz.local,
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
        if (!candidate.isAfter(now))
          candidate = tz.TZDateTime(
            tz.local,
            date.year,
            date.month,
            date.day + 7,
            hour,
            minute,
          );
        if (!habit.scheduledOn(candidate)) continue;
        await plugin.zonedSchedule(
          id: 1000000 + habit.id * 7 + weekday,
          title: 'Time for your habit',
          body: habit.name,
          scheduledDate: candidate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'habit:${habit.id}',
        );
      }
    }
  }
}
