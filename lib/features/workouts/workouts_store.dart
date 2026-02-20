import 'models/workout_models.dart';

class WorkoutsStore {
  WorkoutsStore._();

  static final WorkoutsStore instance = WorkoutsStore._();

  final List<WorkoutPlan> _plans = [
    
  ];

  List<WorkoutPlan> get plans => List.unmodifiable(_plans);

  WorkoutPlan? getById(String id) {
    for (final p in _plans) {
      if (p.id == id) return p;
    }
    return null;
  }

  void addPlan(String name) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _plans.add(WorkoutPlan(id: id, name: name));
  }

  void addExercise(String planId, WorkoutExercise ex) {
    final idx = _plans.indexWhere((p) => p.id == planId);
    if (idx == -1) return;

    final plan = _plans[idx];
    final updated = plan.copyWith(exercises: [...plan.exercises, ex]);
    _plans[idx] = updated;
  }
}