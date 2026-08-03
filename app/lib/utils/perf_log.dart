/// Lightweight, logging-only performance instrumentation (Phase 3 — no
/// external monitoring service). Timings are pushed to `dart:developer`'s
/// Timeline (visible in DevTools' "Timeline" view) and, in debug builds
/// only, echoed to the console so they show up in `flutter run`'s output
/// without needing DevTools attached.
library;

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class PerfLog {
  static Future<T> timeAsync<T>(String label, Future<T> Function() action) async {
    final sw = Stopwatch()..start();
    final task = developer.TimelineTask();
    task.start(label);
    try {
      return await action();
    } finally {
      task.finish();
      sw.stop();
      if (kDebugMode) {
        debugPrint('[perf] $label: ${sw.elapsedMilliseconds}ms');
      }
    }
  }

  static T time<T>(String label, T Function() action) {
    final sw = Stopwatch()..start();
    final task = developer.TimelineTask();
    task.start(label);
    try {
      return action();
    } finally {
      task.finish();
      sw.stop();
      if (kDebugMode) {
        debugPrint('[perf] $label: ${sw.elapsedMilliseconds}ms');
      }
    }
  }
}
