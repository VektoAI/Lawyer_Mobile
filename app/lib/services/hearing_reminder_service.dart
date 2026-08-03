library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/vault_store.dart';
import '../utils/dates.dart';

/// Local hearing reminders — evening (tomorrow) and morning (today). Opt-in.
class HearingReminderService {
  HearingReminderService._();
  static final instance = HearingReminderService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  var _inited = false;

  static const _enabledKey = 'munshi_notify_enabled';

  Future<void> init() async {
    if (_inited) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _inited = true;
  }

  Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool on) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_enabledKey, on);
    if (on) await requestPermission();
  }

  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  Future<void> refreshFromVault(VaultStore vault) async {
    if (!await isEnabled() || !vault.isUnlocked) return;
    await init();
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    final tomorrow = tomorrowIso;
    final today = todayIso;
    final tomorrowCases = vault.listCases().where((c) => c.nextDate == tomorrow).toList();
    final todayCases = vault.listCases().where((c) => c.nextDate == today).toList();

    if (tomorrowCases.isNotEmpty) {
      var evening = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19, 0);
      // If tonight's 7 PM slot already passed, pushing a full day forward
      // would land this reminder at 7 PM on the hearing day itself — after
      // the hearing already happened, making it useless. Fire promptly
      // instead so a "tomorrow" heads-up set up late in the evening still
      // arrives before the hearing.
      if (evening.isBefore(now)) evening = now.add(const Duration(minutes: 1));
      await _schedule(
        id: 1,
        when: evening,
        title: 'Tomorrow: ${tomorrowCases.length} hearing(s)',
        body: tomorrowCases.take(3).map((c) => '${c.caseNo} · ${c.parties.split(' ').take(3).join(' ')}').join('\n'),
      );
    }
    if (todayCases.isNotEmpty) {
      var morning = tz.TZDateTime(tz.local, now.year, now.month, now.day, 7, 30);
      // Same reasoning as above: waiting a full day would show a stale
      // "Today: hearing" reminder tomorrow, a day after it actually happened.
      if (morning.isBefore(now)) morning = now.add(const Duration(minutes: 1));
      await _schedule(
        id: 2,
        when: morning,
        title: 'Today: ${todayCases.length} hearing(s)',
        body: todayCases.take(3).map((c) => '${c.caseNo} · ${c.parties.split(' ').take(3).join(' ')}').join('\n'),
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hearing_alerts',
          'Hearing reminders',
          channelDescription: 'Evening before and morning of hearing day',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
