import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/session_models.dart';

class ProgressStore extends ChangeNotifier {
  ProgressStore._();
  static final ProgressStore instance = ProgressStore._();

  final _sb = Supabase.instance.client;

  final List<WorkoutSession> _sessions = [];
  List<WorkoutSession> get sessions => List.unmodifiable(_sessions);

  bool _loaded = false;
  bool get loaded => _loaded;

  String? _requireUserId() => _sb.auth.currentUser?.id;

  // ── Caricamento ──────────────────────────────────────────────────────────

  Future<void> loadSessions() async {
    final userId = _requireUserId();
    if (userId == null) return;

    try {
      final rows = await _sb
          .from('workout_sessions')
          .select('id, plan_id, plan_name, completed_at, exercises_snapshot')
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      _sessions
        ..clear()
        ..addAll(rows.map(WorkoutSession.fromRow));
    } catch (e) {
      debugPrint('[ProgressStore] loadSessions error: $e');
    }

    _loaded = true;
    notifyListeners();
  }

  // ── Salvataggio sessione ─────────────────────────────────────────────────

  Future<void> saveSession({
    required String? planId,
    required String planName,
    required List<SessionExercise> exercises,
  }) async {
    final userId = _requireUserId();
    if (userId == null) return;

    // deduplicazione: una sola sessione per piano per giorno di calendario
    final today = _dateOnly(DateTime.now());
    final alreadySaved = _sessions.any((s) =>
        s.planId == planId && _dateOnly(s.completedAt) == today);
    if (alreadySaved) return;

    final snapshot = exercises.map((e) => e.toJson()).toList();

    try {
      final row = await _sb
          .from('workout_sessions')
          .insert({
            'user_id': userId,
            'plan_id': planId,
            'plan_name': planName,
            'exercises_snapshot': snapshot,
          })
          .select('id, plan_id, plan_name, completed_at, exercises_snapshot')
          .single();

      _sessions.insert(0, WorkoutSession.fromRow(row));
      notifyListeners();
      debugPrint('[ProgressStore] Sessione salvata: $planName');
    } catch (e) {
      debugPrint('[ProgressStore] saveSession error: $e');
    }
  }

  // ── Stats ────────────────────────────────────────────────────────────────

  int get totalSessions => _sessions.length;

  int get thisWeekSessions {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _sessions.where((s) => s.completedAt.isAfter(cutoff)).length;
  }

  /// Giorni consecutivi (fino ad oggi) con almeno una sessione.
  int get streak {
    if (_sessions.isEmpty) return 0;

    final dates = _sessions
        .map((s) => _dateOnly(s.completedAt))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // discendente

    final today = _dateOnly(DateTime.now());
    // streak parte da oggi o da ieri (se non ancora allenato oggi)
    DateTime cursor = dates.first == today ? today : today.subtract(const Duration(days: 1));
    if (dates.first != cursor && dates.first != today) return 0;

    int count = 0;
    for (final d in dates) {
      if (d == cursor) {
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (d.isBefore(cursor)) {
        break;
      }
    }
    return count;
  }

  /// Nomi distinti di schede nello storico (ordine di apparizione, più recente prima).
  List<String> get planNames {
    final seen = <String>{};
    final result = <String>[];
    for (final s in _sessions) {
      if (seen.add(s.planName)) result.add(s.planName);
    }
    return result;
  }

  /// Esercizi distinti di una scheda specifica, ordinati alfabeticamente.
  List<String> exerciseNamesForPlan(String planName) {
    final names = <String>{};
    for (final s in _sessions) {
      if (s.planName == planName) {
        for (final e in s.exercises) {
          names.add(e.name);
        }
      }
    }
    return names.toList()..sort();
  }

  /// Storico pesi di un esercizio filtrato per scheda.
  List<({DateTime date, double weightKg, int setsDone, int sets})>
      weightHistory(String planName, String exerciseName) {
    final name = exerciseName.toLowerCase();
    final result = <({DateTime date, double weightKg, int setsDone, int sets})>[];

    for (final s in _sessions.reversed) {
      if (s.planName != planName) continue;
      for (final e in s.exercises) {
        if (e.name.toLowerCase() == name) {
          result.add((
            date: s.completedAt,
            weightKg: e.weightKg,
            setsDone: e.setsDone,
            sets: e.sets,
          ));
        }
      }
    }
    return result;
  }

  /// Tutti i nomi distinti di esercizi presenti nello storico.
  List<String> get allExerciseNames {
    final names = <String>{};
    for (final s in _sessions) {
      for (final e in s.exercises) {
        names.add(e.name);
      }
    }
    final list = names.toList()..sort();
    return list;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
