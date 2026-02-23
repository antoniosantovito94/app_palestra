class SessionExercise {
  final String name;
  final int sets;
  final int reps;
  final double weightKg;
  final int setsDone;

  const SessionExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.setsDone,
  });

  factory SessionExercise.fromJson(Map<String, dynamic> j) => SessionExercise(
        name: j['name'] as String,
        sets: (j['sets'] as num).toInt(),
        reps: (j['reps'] as num).toInt(),
        weightKg: (j['weight_kg'] as num).toDouble(),
        setsDone: (j['sets_done'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight_kg': weightKg,
        'sets_done': setsDone,
      };

  bool get isComplete => setsDone >= sets;
}

class WorkoutSession {
  final String id;
  final String? planId;
  final String planName;
  final DateTime completedAt;
  final List<SessionExercise> exercises;

  const WorkoutSession({
    required this.id,
    required this.planId,
    required this.planName,
    required this.completedAt,
    required this.exercises,
  });

  factory WorkoutSession.fromRow(Map<String, dynamic> r) {
    final raw = r['exercises_snapshot'] as List;
    return WorkoutSession(
      id: r['id'] as String,
      planId: r['plan_id'] as String?,
      planName: r['plan_name'] as String,
      completedAt: DateTime.parse(r['completed_at'] as String).toLocal(),
      exercises: raw
          .map((e) => SessionExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isFullyComplete => exercises.every((e) => e.isComplete);
}
