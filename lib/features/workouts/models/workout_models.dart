enum ExerciseStatus { notStarted, inProgress, completed }

class ExerciseProgress {
  final String exerciseId;
  final String planId;
  final List<bool> setDone;

  const ExerciseProgress({
    required this.exerciseId,
    required this.planId,
    required this.setDone,
  });

  int get doneCount => setDone.where((v) => v).length;
  int get total => setDone.length;

  double get ratio => total == 0 ? 0 : doneCount / total;

  ExerciseStatus get status {
    if (total == 0 || doneCount == 0) return ExerciseStatus.notStarted;
    if (doneCount == total) return ExerciseStatus.completed;
    return ExerciseStatus.inProgress;
  }

  ExerciseProgress copyWith({List<bool>? setDone}) {
    return ExerciseProgress(
      exerciseId: exerciseId,
      planId: planId,
      setDone: setDone ?? this.setDone,
    );
  }
}

class WorkoutPlan {
  final String id;
  final String name;
  final List<WorkoutExercise> exercises;

  /// progress per exerciseId
  final Map<String, ExerciseProgress> progressByExerciseId;

  const WorkoutPlan({
    required this.id,
    required this.name,
    this.exercises = const [],
    this.progressByExerciseId = const {},
  });

  WorkoutPlan copyWith({
    String? id,
    String? name,
    List<WorkoutExercise>? exercises,
    Map<String, ExerciseProgress>? progressByExerciseId,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      progressByExerciseId: progressByExerciseId ?? this.progressByExerciseId,
    );
  }
}

class WorkoutExercise {
  final String id;
  final String name;
  final int sets;
  final int reps;
  final double weightKg;
  final List<double>? weightsKg;

  /// ordine UI/DB dentro la scheda
  final int orderIndex;

  /// tempo recupero tra le serie (in secondi)
  final int restSeconds;

  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weightKg,
    this.weightsKg,
    this.orderIndex = 0,
    this.restSeconds = 60,
  });

  bool get hasPerSetWeights => weightsKg != null && weightsKg!.isNotEmpty;

  WorkoutExercise copyWith({int? orderIndex}) {
    return WorkoutExercise(
      id: id,
      name: name,
      sets: sets,
      reps: reps,
      weightKg: weightKg,
      weightsKg: weightsKg,
      orderIndex: orderIndex ?? this.orderIndex,
      restSeconds: restSeconds,
    );
  }
}