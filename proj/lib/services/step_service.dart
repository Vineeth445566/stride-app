import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/date_utils.dart';
import 'step_database.dart';

/// Counts steps with the phone's hardware step-counter sensor.
/// No GPS, no network needed — counting works fully offline.
///
/// The hardware sensor reports a cumulative count since device boot.
/// We anchor a per-day baseline and diff against it, so the count survives
/// app kills and device reboots.
class StepService extends ChangeNotifier {
  // ---- settings (persisted) ----
  int goal = 10000;
  double heightCm = 170;
  double weightKg = 70;
  bool metric = true;
  int sensitivity = 1; // display debounce, in steps: 1 = responsive … 5 = steady
  String themeId = 'forest';
  Set<String> unlockedThemes = {'forest'};

  // ---- live state ----
  int todaySteps = 0;
  int displayedSteps = 0;
  bool isTracking = false;
  bool ready = false;
  String? error;

  final StepDatabase _db = StepDatabase();
  SharedPreferences? _prefs;
  StreamSubscription<StepCount>? _sub;

  String _dayKey = '';
  int _baseline = -1; // cumulative hardware value at the start of the day
  int? _resumeOffset; // exact step total to restore after a pause
  int _hour = -1;
  int _hourStartSteps = 0;
  DateTime _lastWrite = DateTime.fromMillisecondsSinceEpoch(0);
  bool _disposed = false;

  // ---- derived metrics ----
  double get strideM => (heightCm / 100) * 0.415;
  double get distanceKm => todaySteps * strideM / 1000;
  double get distanceDisplay => metric ? distanceKm : distanceKm * 0.621371;
  String get distanceUnit => metric ? 'km' : 'mi';
  double get calories => todaySteps * 0.045 * (weightKg / 70);
  double get durationMin => todaySteps / 105; // ~105 steps/min walking cadence
  double get progress => goal <= 0 ? 0 : (todaySteps / goal).clamp(0.0, 1.0);
  bool get goalReached => goal > 0 && todaySteps >= goal;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _db.init();

    goal = _prefs!.getInt('goal') ?? 10000;
    heightCm = _prefs!.getDouble('heightCm') ?? 170;
    weightKg = _prefs!.getDouble('weightKg') ?? 70;
    metric = _prefs!.getBool('metric') ?? true;
    sensitivity = _prefs!.getInt('sensitivity') ?? 1;
    themeId = _prefs!.getString('themeId') ?? 'forest';
    unlockedThemes = (_prefs!.getStringList('unlockedThemes') ?? ['forest']).toSet();

    _dayKey = dayKeyOf(DateTime.now());
    _baseline = _prefs!.getInt('baseline_$_dayKey') ?? -1;
    todaySteps = _prefs!.getInt('steps_$_dayKey') ?? 0;
    displayedSteps = _prefs!.getInt('displayed_$_dayKey') ?? todaySteps;
    _hour = DateTime.now().hour;
    _hourStartSteps = todaySteps;
    isTracking = _prefs!.getBool('isTracking') ?? true;

    ready = true;
    _notify();

    final status = await Permission.activityRecognition.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      error = 'Activity-recognition permission was denied, so steps cannot be '
          'counted. Please enable it in the system settings.';
      _notify();
      return;
    }
    if (isTracking) {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    await _sub?.cancel();
    try {
      _sub = Pedometer.stepCountStream.listen(
        _onStepEvent,
        onError: _onStepError,
        cancelOnError: false,
      );
    } catch (_) {
      error = 'This device has no hardware step-counter sensor.';
      _notify();
    }
  }

  void _onStepError(Object e) {
    error = 'Step sensor error: $e';
    _notify();
  }

  Future<void> _onStepEvent(StepCount event) async {
    final now = DateTime.now();
    final key = dayKeyOf(now);
    if (key != _dayKey) {
      await _rolloverDay(key);
    }
    if (_resumeOffset != null) {
      // First event after resume: re-anchor so steps taken while paused are skipped.
      _baseline = event.steps - _resumeOffset!;
      _resumeOffset = null;
      await _prefs!.setInt('baseline_$_dayKey', _baseline);
    } else if (_baseline < 0) {
      _baseline = event.steps - todaySteps;
      await _prefs!.setInt('baseline_$_dayKey', _baseline);
    }
    var raw = event.steps - _baseline;
    if (raw < 0) {
      // Sensor counter reset (device reboot): re-anchor instead of losing the day.
      _baseline = event.steps;
      raw = 0;
      await _prefs!.setInt('baseline_$_dayKey', _baseline);
    }
    todaySteps = raw;

    // Sensitivity = display debounce; persisted math always stays exact.
    final pending = todaySteps - displayedSteps;
    if (pending >= sensitivity) {
      displayedSteps += (pending ~/ sensitivity) * sensitivity;
    }

    if (now.hour != _hour) {
      _hour = now.hour;
      _hourStartSteps = todaySteps;
    }
    if (now.difference(_lastWrite) > const Duration(seconds: 5)) {
      _lastWrite = now;
      await _persist();
    }
    _notify();
  }

  Future<void> _rolloverDay(String newKey) async {
    await _persist(); // finalize the old day with exact values
    _dayKey = newKey;
    todaySteps = 0;
    displayedSteps = 0;
    _baseline = -1;
    _resumeOffset = null;
    _hour = DateTime.now().hour;
    _hourStartSteps = 0;
    await _prefs!.setInt('steps_$_dayKey', 0);
    await _prefs!.setInt('displayed_$_dayKey', 0);
    await _prefs!.remove('baseline_$_dayKey');
  }

  Future<void> _persist() async {
    await _prefs!.setInt('steps_$_dayKey', todaySteps);
    await _prefs!.setInt('displayed_$_dayKey', displayedSteps);
    await _db.upsertDay(_dayKey, todaySteps, calories, distanceKm, durationMin);
    await _db.upsertHour(_dayKey, _hour, todaySteps - _hourStartSteps);
  }

  /// Called when the app goes to background so nothing is lost on kill.
  Future<void> persistNow() => _persist();

  /// Pause = e.g. driving. Steps taken while paused are not counted.
  Future<void> setTracking(bool on) async {
    if (on == isTracking) return;
    isTracking = on;
    await _prefs!.setBool('isTracking', on);
    if (on) {
      _resumeOffset = todaySteps;
      await _startListening();
    } else {
      await _sub?.cancel();
      _sub = null;
      _resumeOffset = null;
      displayedSteps = todaySteps; // settle any debounced remainder
      await _persist();
    }
    _notify();
  }

  // ---- settings ----
  Future<void> setGoal(int v) async {
    goal = v.clamp(1000, 100000);
    await _prefs!.setInt('goal', goal);
    await _persist();
    _notify();
  }

  Future<void> setHeight(double v) async {
    heightCm = v.clamp(100, 230);
    await _prefs!.setDouble('heightCm', heightCm);
    await _persist();
    _notify();
  }

  Future<void> setWeight(double v) async {
    weightKg = v.clamp(30, 250);
    await _prefs!.setDouble('weightKg', weightKg);
    await _persist();
    _notify();
  }

  Future<void> setMetric(bool v) async {
    metric = v;
    await _prefs!.setBool('metric', v);
    _notify();
  }

  Future<void> setSensitivity(int v) async {
    sensitivity = v;
    await _prefs!.setInt('sensitivity', v);
    _notify();
  }

  Future<void> setTheme(String id) async {
    if (!unlockedThemes.contains(id)) return;
    themeId = id;
    await _prefs!.setString('themeId', id);
    _notify();
  }

  Future<void> unlockTheme(String id) async {
    unlockedThemes.add(id);
    await _prefs!.setStringList('unlockedThemes', unlockedThemes.toList());
    _notify();
  }

  // ---- history queries ----
  Future<List<Map<String, Object?>>> lastNDays(int n) async {
    final today = DateTime.now();
    final start = today.subtract(Duration(days: n - 1));
    final rows = await _db.daysBetween(dayKeyOf(start), dayKeyOf(today));
    final byDate = {for (final r in rows) r['date'] as String: r};
    return List.generate(n, (i) {
      final key = dayKeyOf(start.add(Duration(days: i)));
      final r = byDate[key];
      return {
        'date': key,
        // Today always uses the live counter (DB lags by a few seconds).
        'steps': key == _dayKey ? todaySteps : ((r?['steps'] as int?) ?? 0),
      };
    });
  }

  Future<List<Map<String, Object?>>> last12Months() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 11, 1);
    final rows = await _db.daysBetween(dayKeyOf(start), dayKeyOf(now));
    final sums = List<int>.filled(12, 0);
    for (final r in rows) {
      final d = dateOfKey(r['date'] as String);
      final idx = (d.year - start.year) * 12 + (d.month - start.month);
      if (idx < 0 || idx >= 12) continue;
      // Today always uses the live counter to avoid double counting.
      final key = r['date'] as String;
      sums[idx] += key == _dayKey ? todaySteps : ((r['steps'] as int?) ?? 0);
    }
    return List.generate(12, (i) {
      final d = DateTime(start.year, start.month + i, 1);
      return {'label': monthShort(d), 'steps': sums[i]};
    });
  }

  Future<List<int>> todayHours() async {
    final rows = await _db.hoursOf(_dayKey);
    final hours = List<int>.filled(24, 0);
    for (final r in rows) {
      hours[(r['hour'] as int?) ?? 0] = (r['steps'] as int?) ?? 0;
    }
    if (_hour >= 0 && _hour < 24) {
      hours[_hour] = todaySteps - _hourStartSteps;
    }
    return hours;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
