import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/workout_models.dart';
import '../progress/progress_store.dart';
import '../progress/models/session_models.dart';

class WorkoutsStore extends ChangeNotifier {
  WorkoutsStore._();
  static final WorkoutsStore instance = WorkoutsStore._();

  final _sb = Supabase.instance.client;

  final List<WorkoutPlan> _plans = [];
  List<WorkoutPlan> get plans => List.unmodifiable(_plans);

  RealtimeChannel? _progressChannel;
  bool _realtimeStarted = false;

  WorkoutPlan? getById(String id) {
    for (final p in _plans) {
      if (p.id == id) return p;
    }
    return null;
  }

  String _requireUserId() {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception('Utente non loggato');
    return user.id;
  }

  Future<void> loadPlans() async {
    final userId = _requireUserId();

    final plansRows = await _sb
        .from('plans')
        .select('id, name, created_at')
        .eq('user_id', userId)
        .order('created_at');

    if (plansRows.isEmpty) {
      _plans.clear();
      notifyListeners();
      return;
    }

    final planIds = plansRows.map((r) => r['id'] as String).toList();

    final exRows = await _sb
    .from('exercises')
    .select('id, plan_id, name, sets, reps, weight_kg, weights_kg, rest_seconds, order_index, created_at')
    .eq('user_id', userId)
    .inFilter('plan_id', planIds)
    .order('order_index', ascending: true)
    .order('created_at', ascending: true);

    final exByPlan = <String, List<WorkoutExercise>>{};
    final allExerciseIds = <String>[];

    for (final r in exRows) {
      final planId = r['plan_id'] as String;
      final weights = r['weights_kg'];

      final ex = WorkoutExercise(
        id: r['id'] as String,
        name: r['name'] as String,
        sets: (r['sets'] as num).toInt(),
        reps: (r['reps'] as num).toInt(),
        weightKg: (r['weight_kg'] as num).toDouble(),
        weightsKg: weights == null
            ? null
            : List<double>.from(
                (weights as List).map((e) => (e as num).toDouble()),
              ),
        restSeconds: (r['rest_seconds'] as num?)?.toInt() ?? 90,
        orderIndex: (r['order_index'] as num?)?.toInt() ?? 0,
      );

      allExerciseIds.add(ex.id);

      exByPlan.putIfAbsent(planId, () => []).add(ex);
    }

    // carico progress
    final progressByPlan = <String, Map<String, ExerciseProgress>>{};
    if (allExerciseIds.isNotEmpty) {
      final progressRows = await _sb
          .from('exercise_progress')
          .select('plan_id, exercise_id, set_done')
          .eq('user_id', userId)
          .inFilter('plan_id', planIds)
          .inFilter('exercise_id', allExerciseIds);

      for (final r in progressRows) {
        final planId = r['plan_id'] as String;
        final exId = r['exercise_id'] as String;
        final arr = (r['set_done'] as List).map((e) => e as bool).toList();

        progressByPlan.putIfAbsent(planId, () => {})[exId] = ExerciseProgress(
          exerciseId: exId,
          planId: planId,
          setDone: arr,
        );
      }
    }

    // build piani
    _plans
      ..clear()
      ..addAll(
        plansRows.map((p) {
          final id = p['id'] as String;
          return WorkoutPlan(
            id: id,
            name: p['name'] as String,
            exercises: exByPlan[id] ?? const [],
            progressByExerciseId: progressByPlan[id] ?? const {},
          );
        }),
      );

    // garantisco che ogni esercizio abbia progress (anche se non presente in DB)
    for (int i = 0; i < _plans.length; i++) {
      final plan = _plans[i];
      final newMap = Map<String, ExerciseProgress>.from(
        plan.progressByExerciseId,
      );

      for (final ex in plan.exercises) {
        newMap.putIfAbsent(
          ex.id,
          () => ExerciseProgress(
            exerciseId: ex.id,
            planId: plan.id,
            setDone: List<bool>.filled(ex.sets, false),
          ),
        );

        // se sets cambiati rispetto a DB, riallineo lunghezza
        final current = newMap[ex.id]!;
        if (current.setDone.length != ex.sets) {
          final resized = _resizeBoolList(current.setDone, ex.sets);
          newMap[ex.id] = current.copyWith(setDone: resized);
          // non faccio update qui automaticamente: lo facciamo quando serve,
          // o puoi decidere di salvarlo subito.
        }
      }

      _plans[i] = plan.copyWith(progressByExerciseId: newMap);
    }

    if (!_realtimeStarted) {
      _startRealtime();
    }

    notifyListeners();
  }

  List<bool> _resizeBoolList(List<bool> current, int targetLen) {
    if (targetLen <= 0) return const [];
    if (current.length == targetLen) return current;
    if (current.length > targetLen) return current.sublist(0, targetLen);
    return [
      ...current,
      ...List<bool>.filled(targetLen - current.length, false),
    ];
  }

  void _startRealtime() {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return;

    _progressChannel?.unsubscribe();

    _progressChannel = _sb.channel('exercise_progress_changes');

    _progressChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'exercise_progress',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isEmpty) return;

            final planId = record['plan_id'] as String?;
            final exId = record['exercise_id'] as String?;
            final setDoneRaw = record['set_done'];

            if (planId == null || exId == null || setDoneRaw == null) return;

            final setDone = (setDoneRaw as List).map((e) => e as bool).toList();

            final pIdx = _plans.indexWhere((p) => p.id == planId);
            if (pIdx == -1) return;

            final plan = _plans[pIdx];
            final map = Map<String, ExerciseProgress>.from(
              plan.progressByExerciseId,
            );
            map[exId] = ExerciseProgress(
              exerciseId: exId,
              planId: planId,
              setDone: setDone,
            );
            _plans[pIdx] = plan.copyWith(progressByExerciseId: map);
            notifyListeners();
          },
        )
        .subscribe();

    _realtimeStarted = true;
  }

  Future<WorkoutPlan> createPlan(String name) async {
    final userId = _requireUserId();

    final inserted = await _sb
        .from('plans')
        .insert({'user_id': userId, 'name': name})
        .select('id, name')
        .single();

    final plan = WorkoutPlan(
      id: inserted['id'] as String,
      name: inserted['name'] as String,
      exercises: const [],
      progressByExerciseId: const {},
    );

    _plans.add(plan);
    notifyListeners();
    return plan;
  }

  Future<WorkoutExercise> createExercise({
    required String planId,
    required WorkoutExercise draft,
  }) async {
    final userId = _requireUserId();

final planIdx = _plans.indexWhere((p) => p.id == planId);
final nextOrder = planIdx == -1 ? 0 : _plans[planIdx].exercises.length;

final inserted = await _sb
    .from('exercises')
    .insert({
      'user_id': userId,
      'plan_id': planId,
      'name': draft.name,
      'sets': draft.sets,
      'reps': draft.reps,
      'weight_kg': draft.weightKg,
      'weights_kg': (draft.weightsKg == null || draft.weightsKg!.isEmpty) ? null : draft.weightsKg,
      'rest_seconds': draft.restSeconds,
      'order_index': nextOrder,
    })
    .select('id, name, sets, reps, weight_kg, weights_kg, rest_seconds, order_index')
    .single();

  final ex = WorkoutExercise(
  id: inserted['id'] as String,
  name: inserted['name'] as String,
  sets: (inserted['sets'] as num).toInt(),
  reps: (inserted['reps'] as num).toInt(),
  weightKg: (inserted['weight_kg'] as num).toDouble(),
  weightsKg: inserted['weights_kg'] == null
      ? null
      : List<double>.from((inserted['weights_kg'] as List).map((e) => (e as num).toDouble())),
  orderIndex: (inserted['order_index'] as num?)?.toInt() ?? nextOrder,
  restSeconds: (inserted['rest_seconds'] as num?)?.toInt() ?? 90,
);

    // crea progress iniziale (tutte false)
    await _sb.from('exercise_progress').upsert(
      {
        'user_id': userId,
        'plan_id': planId,
        'exercise_id': ex.id,
        'set_done': List<bool>.filled(ex.sets, false),
      },
      onConflict: 'user_id,plan_id,exercise_id',
    );

    final idx = _plans.indexWhere((p) => p.id == planId);
    if (idx != -1) {
      final plan = _plans[idx];

      final newProgress = Map<String, ExerciseProgress>.from(
        plan.progressByExerciseId,
      );
      newProgress[ex.id] = ExerciseProgress(
        exerciseId: ex.id,
        planId: planId,
        setDone: List<bool>.filled(ex.sets, false),
      );

      _plans[idx] = plan.copyWith(
        exercises: [...plan.exercises, ex],
        progressByExerciseId: newProgress,
      );
    }

    notifyListeners();
    return ex;
  }

  Future<void> deletePlan(String planId) async {
    final userId = _requireUserId();

    await _sb.from('plans').delete().eq('id', planId).eq('user_id', userId);

    _plans.removeWhere((p) => p.id == planId);
    notifyListeners();
  }

  Future<WorkoutPlan> renamePlan(String planId, String newName) async {
    final userId = _requireUserId();

    final updated = await _sb
        .from('plans')
        .update({'name': newName})
        .eq('id', planId)
        .eq('user_id', userId)
        .select('id, name')
        .single();

    final idx = _plans.indexWhere((p) => p.id == planId);
    if (idx != -1) {
      final old = _plans[idx];
      _plans[idx] = old.copyWith(name: updated['name'] as String);
    }

    notifyListeners();
    return _plans.firstWhere((p) => p.id == planId);
  }

  Future<void> deleteExercise(String planId, String exerciseId) async {
    final userId = _requireUserId();

    await _sb
        .from('exercises')
        .delete()
        .eq('id', exerciseId)
        .eq('user_id', userId);

    final idx = _plans.indexWhere((p) => p.id == planId);
    if (idx != -1) {
      final plan = _plans[idx];

      final newProgress = Map<String, ExerciseProgress>.from(
        plan.progressByExerciseId,
      );
      newProgress.remove(exerciseId);

      _plans[idx] = plan.copyWith(
        exercises: plan.exercises.where((e) => e.id != exerciseId).toList(),
        progressByExerciseId: newProgress,
      );
    }

    notifyListeners();
  }

  Future<WorkoutExercise> updateExercise({
    required String planId,
    required WorkoutExercise updatedEx,
  }) async {
    final userId = _requireUserId();

    final row = await _sb
        .from('exercises')
        .update({
          'name': updatedEx.name,
          'sets': updatedEx.sets,
          'reps': updatedEx.reps,
          'weight_kg': updatedEx.weightKg,
          'weights_kg':
              (updatedEx.weightsKg == null || updatedEx.weightsKg!.isEmpty)
              ? null
              : updatedEx.weightsKg,
          'rest_seconds': updatedEx.restSeconds,
        })
        .eq('id', updatedEx.id)
        .eq('user_id', userId)
        .select('id, name, sets, reps, weight_kg, weights_kg, rest_seconds, order_index')
        .single();

    final ex = WorkoutExercise(
      id: row['id'] as String,
      name: row['name'] as String,
      sets: (row['sets'] as num).toInt(),
      reps: (row['reps'] as num).toInt(),
      weightKg: (row['weight_kg'] as num).toDouble(),
      weightsKg: row['weights_kg'] == null
          ? null
          : List<double>.from(
              (row['weights_kg'] as List).map((e) => (e as num).toDouble()),
            ),
      restSeconds: (row['rest_seconds'] as num?)?.toInt() ?? 90,
      orderIndex: (row['order_index'] as num?)?.toInt() ?? 0,
    );

    final planIdx = _plans.indexWhere((p) => p.id == planId);
    if (planIdx != -1) {
      final plan = _plans[planIdx];
      final exIdx = plan.exercises.indexWhere((e) => e.id == ex.id);
      if (exIdx != -1) {
        final newList = [...plan.exercises];
        newList[exIdx] = ex;

        // riallineo progress alle nuove serie
        final newProgress = Map<String, ExerciseProgress>.from(
          plan.progressByExerciseId,
        );
        final current =
            newProgress[ex.id] ??
            ExerciseProgress(
              exerciseId: ex.id,
              planId: planId,
              setDone: List<bool>.filled(ex.sets, false),
            );

        final resized = _resizeBoolList(current.setDone, ex.sets);
        newProgress[ex.id] = current.copyWith(setDone: resized);

        _plans[planIdx] = plan.copyWith(
          exercises: newList,
          progressByExerciseId: newProgress,
        );

        // salvo subito anche in DB il resize (consigliato)
        await _sb
            .from('exercise_progress')
            .update({'set_done': resized})
            .eq('user_id', userId)
            .eq('plan_id', planId)
            .eq('exercise_id', ex.id);
      }
    }

    notifyListeners();
    return ex;
  }


Future<void> reorderExercises({
  required String planId,
  required List<WorkoutExercise> ordered,
}) async {
  final userId = _requireUserId();

  final planIdx = _plans.indexWhere((p) => p.id == planId);
  if (planIdx == -1) return;

  final plan = _plans[planIdx];

  // optimistic
  final updated = <WorkoutExercise>[];
  for (int i = 0; i < ordered.length; i++) {
    updated.add(ordered[i].copyWith(orderIndex: i));
  }
  _plans[planIdx] = plan.copyWith(exercises: updated);
  notifyListeners();

  // aggiorna order_index per ogni esercizio in parallelo (niente RPC custom)
  try {
    await Future.wait([
      for (int i = 0; i < updated.length; i++)
        _sb
            .from('exercises')
            .update({'order_index': i})
            .eq('id', updated[i].id)
            .eq('user_id', userId),
    ]);
  } catch (_) {
    // rollback in memoria se il salvataggio fallisce
    _plans[planIdx] = plan;
    notifyListeners();
    rethrow;
  }
}

  ExerciseProgress progressOf(String planId, WorkoutExercise ex) {
    final plan = getById(planId);
    final existing = plan?.progressByExerciseId[ex.id];
    if (existing != null && existing.setDone.length == ex.sets) return existing;

    // fallback
    return ExerciseProgress(
      exerciseId: ex.id,
      planId: planId,
      setDone: List<bool>.filled(ex.sets, false),
    );
  }

  Future<void> toggleSetDone({
    required String planId,
    required WorkoutExercise ex,
    required int setIndex,
    required bool done,
  }) async {
    final userId = _requireUserId();

    // optimistic UI update
    final pIdx = _plans.indexWhere((p) => p.id == planId);
    if (pIdx == -1) return;

    final plan = _plans[pIdx];
    final map = Map<String, ExerciseProgress>.from(plan.progressByExerciseId);
    final current = progressOf(planId, ex);
    final next = List<bool>.from(current.setDone);
    if (setIndex < 0 || setIndex >= next.length) return;

    next[setIndex] = done;

    map[ex.id] = current.copyWith(setDone: next);
    _plans[pIdx] = plan.copyWith(progressByExerciseId: map);
    notifyListeners();

    // persist
    await _sb
        .from('exercise_progress')
        .update({'set_done': next})
        .eq('user_id', userId)
        .eq('plan_id', planId)
        .eq('exercise_id', ex.id);

    // auto-save sessione se piano completato al 100%
    if (workoutCompletionRatio(planId) == 1.0) {
      final plan = getById(planId);
      if (plan != null) {
        final exerciseSnapshots = plan.exercises.map((e) {
          final pr = progressOf(planId, e);
          return SessionExercise(
            name: e.name,
            sets: e.sets,
            reps: e.reps,
            weightKg: e.weightKg,
            setsDone: pr.doneCount,
          );
        }).toList();

        ProgressStore.instance.saveSession(
          planId: planId,
          planName: plan.name,
          exercises: exerciseSnapshots,
        );
      }
    }
  }

  Future<void> resetProgress(String planId) async {
    final userId = _requireUserId();
    final idx = _plans.indexWhere((p) => p.id == planId);
    if (idx == -1) return;

    final plan = _plans[idx];
    final resetMap = <String, ExerciseProgress>{};

    for (final ex in plan.exercises) {
      final empty = List<bool>.filled(ex.sets, false);
      resetMap[ex.id] = ExerciseProgress(
        exerciseId: ex.id,
        planId: planId,
        setDone: empty,
      );
      await _sb
          .from('exercise_progress')
          .update({'set_done': empty})
          .eq('user_id', userId)
          .eq('plan_id', planId)
          .eq('exercise_id', ex.id);
    }

    _plans[idx] = plan.copyWith(progressByExerciseId: resetMap);
    notifyListeners();
  }

  // util: percent workout
  double workoutCompletionRatio(String planId) {
    final plan = getById(planId);
    if (plan == null || plan.exercises.isEmpty) return 0;

    int done = 0;
    int total = 0;

    for (final ex in plan.exercises) {
      final pr = progressOf(planId, ex);
      done += pr.doneCount;
      total += pr.total;
    }

    if (total == 0) return 0;
    return done / total;
  }
}
