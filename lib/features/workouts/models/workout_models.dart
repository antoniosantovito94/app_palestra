class WorkoutPlan {
  final String id;
  final String name;
  final List<WorkoutExercise> exercises;

  const WorkoutPlan({
    required this.id,
    required this.name,
    this.exercises = const [],
  });

  WorkoutPlan copyWith({
    String? id,
    String? name,
    List<WorkoutExercise>? exercises,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
    );
  }
}

class WorkoutExercise {
  final String id;
  final String name;
  final int sets;
  final int reps;

  /// Se usi peso unico, usa weightKg
  final double weightKg;

  /// Se usi peso per serie, qui dentro metti un valore per ogni serie
  /// (lunghezza == sets). Se vuoto/null -> non usato.
  final List<double>? weightsKg;

  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weightKg,
    this.weightsKg,
  });

  bool get hasPerSetWeights => weightsKg != null && weightsKg!.isNotEmpty;
}