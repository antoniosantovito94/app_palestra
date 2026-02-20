import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import 'models/workout_models.dart';
import 'workouts_store.dart';
import '../../app/app_settings.dart';

class WorkoutDetailPage extends StatefulWidget {
  final String planId;
  const WorkoutDetailPage({super.key, required this.planId});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  final store = WorkoutsStore.instance;

  Future<void> _addExerciseDialog() async {
    final nameCtrl = TextEditingController();

    int sets = 3;
    int reps = 10;
    int restSeconds = 90;

    double weightKg = 20.0;
    bool perSetWeight = false;

    List<double> perSetWeights = List.filled(sets, weightKg);

    String formatKg(double v) {
      final isInt = v % 1 == 0;
      return isInt ? v.toInt().toString() : v.toStringAsFixed(1);
    }

    void syncPerSetWeightsWithSets() {
      if (perSetWeights.length == sets) return;

      if (perSetWeights.length < sets) {
        final last = perSetWeights.isNotEmpty ? perSetWeights.last : weightKg;
        perSetWeights = [
          ...perSetWeights,
          ...List.filled(sets - perSetWeights.length, last),
        ];
      } else {
        perSetWeights = perSetWeights.sublist(0, sets);
      }
    }

    final result = await showDialog<WorkoutExercise>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final isAdvanced = appSettings.advancedMode;

            Widget numberStepper({
              required String label,
              required String valueText,
              required VoidCallback onMinus,
              required VoidCallback onPlus,
            }) {
              return Row(
                children: [
                  Expanded(child: Text(label)),
                  IconButton(
                    onPressed: onMinus,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 70,
                    child: Center(
                      child: Text(
                        valueText,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onPlus,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              );
            }

            Widget weightRow({
              required String label,
              required double value,
              required VoidCallback onMinus,
              required VoidCallback onPlus,
            }) {
              return Row(
                children: [
                  Expanded(child: Text(label)),
                  IconButton(
                    onPressed: onMinus,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text(
                        '${formatKg(value)} kg',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onPlus,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              );
            }

            syncPerSetWeightsWithSets();

            return AlertDialog(
              title: Text(
                isAdvanced
                    ? 'Aggiungi esercizio (Avanzato)'
                    : 'Aggiungi esercizio',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nome esercizio',
                      ),
                    ),
                    const SizedBox(height: 16),

                    numberStepper(
                      label: 'Serie',
                      valueText: '$sets',
                      onMinus: () => setLocalState(() {
                        if (sets > 1) sets--;
                        syncPerSetWeightsWithSets();
                      }),
                      onPlus: () => setLocalState(() {
                        sets++;
                        syncPerSetWeightsWithSets();
                      }),
                    ),

                    numberStepper(
                      label: 'Ripetizioni',
                      valueText: '$reps',
                      onMinus: () => setLocalState(() {
                        if (reps > 1) reps--;
                      }),
                      onPlus: () => setLocalState(() {
                        reps++;
                      }),
                    ),

                    numberStepper(
                      label: 'Recupero (sec)',
                      valueText: '$restSeconds',
                      onMinus: () => setLocalState(() {
                        restSeconds = (restSeconds - 5).clamp(0, 600);
                      }),
                      onPlus: () => setLocalState(() {
                        restSeconds = (restSeconds + 5).clamp(0, 600);
                      }),
                    ),

                    const SizedBox(height: 8),

                    if (isAdvanced) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Peso per serie'),
                        subtitle: const Text(
                          'Se attivo, imposti un peso per ogni serie',
                        ),
                        value: perSetWeight,
                        onChanged: (v) => setLocalState(() {
                          perSetWeight = v;
                          if (perSetWeight) {
                            perSetWeights = List.filled(sets, weightKg);
                          }
                        }),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (!perSetWeight) ...[
                      weightRow(
                        label: 'Peso (kg)',
                        value: weightKg,
                        onMinus: () => setLocalState(() {
                          weightKg -= 0.5;
                          if (weightKg < 0) weightKg = 0;
                        }),
                        onPlus: () => setLocalState(() {
                          weightKg += 0.5;
                        }),
                      ),
                    ] else ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pesi per serie',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (int i = 0; i < sets; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: weightRow(
                            label: 'Serie ${i + 1}',
                            value: perSetWeights[i],
                            onMinus: () => setLocalState(() {
                              perSetWeights[i] -= 0.5;
                              if (perSetWeights[i] < 0) perSetWeights[i] = 0;
                            }),
                            onPlus: () => setLocalState(() {
                              perSetWeights[i] += 0.5;
                            }),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final ex = WorkoutExercise(
                      id: 'draft',
                      name: name,
                      sets: sets,
                      reps: reps,
                      weightKg: perSetWeight ? perSetWeights.first : weightKg,
                      weightsKg: perSetWeight
                          ? List<double>.from(perSetWeights)
                          : null,
                      restSeconds: restSeconds,
                    );

                    Navigator.of(context).pop(ex);
                  },
                  child: const Text('Aggiungi'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    await store.createExercise(planId: widget.planId, draft: result);
  }

  _StatusUI _statusUi(BuildContext context, ExerciseStatus s) {
    final cs = Theme.of(context).colorScheme;

    switch (s) {
      case ExerciseStatus.notStarted:
        return _StatusUI(
          icon: Icons.radio_button_unchecked,
          iconColor: cs.onSurfaceVariant,
          bgColor: cs.surface,
          borderColor: cs.outlineVariant,
        );
      case ExerciseStatus.inProgress:
        return _StatusUI(
          icon: Icons.timelapse,
          iconColor: cs.primary,
          bgColor: cs.primaryContainer.withOpacity(0.25),
          borderColor: cs.primary.withOpacity(0.35),
        );
      case ExerciseStatus.completed:
        return _StatusUI(
          icon: Icons.check_circle,
          iconColor: cs.tertiary,
          bgColor: cs.tertiaryContainer.withOpacity(0.25),
          borderColor: cs.tertiary.withOpacity(0.35),
        );
    }
  }

  Future<WorkoutExercise?> _editExerciseDialog(WorkoutExercise initial) async {
    final nameCtrl = TextEditingController(text: initial.name);

    int sets = initial.sets;
    int reps = initial.reps;
    int restSeconds = initial.restSeconds;

    // se aveva pesi per serie -> partiamo da quelli
    bool perSetWeight = initial.hasPerSetWeights;

    double weightKg = initial.weightKg;

    List<double> perSetWeights = perSetWeight
        ? List<double>.from(initial.weightsKg!)
        : List.filled(sets, weightKg);

    String formatKg(double v) {
      final isInt = v % 1 == 0;
      return isInt ? v.toInt().toString() : v.toStringAsFixed(1);
    }

    void syncPerSetWeightsWithSets() {
      if (perSetWeights.length == sets) return;

      if (perSetWeights.length < sets) {
        final last = perSetWeights.isNotEmpty ? perSetWeights.last : weightKg;
        perSetWeights = [
          ...perSetWeights,
          ...List.filled(sets - perSetWeights.length, last),
        ];
      } else {
        perSetWeights = perSetWeights.sublist(0, sets);
      }
    }

    return showDialog<WorkoutExercise>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final isAdvanced = appSettings.advancedMode;

            Widget numberStepper({
              required String label,
              required String valueText,
              required VoidCallback onMinus,
              required VoidCallback onPlus,
            }) {
              return Row(
                children: [
                  Expanded(child: Text(label)),
                  IconButton(
                    onPressed: onMinus,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 70,
                    child: Center(
                      child: Text(
                        valueText,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onPlus,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              );
            }

            Widget weightRow({
              required String label,
              required double value,
              required VoidCallback onMinus,
              required VoidCallback onPlus,
            }) {
              return Row(
                children: [
                  Expanded(child: Text(label)),
                  IconButton(
                    onPressed: onMinus,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text(
                        '${formatKg(value)} kg',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onPlus,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              );
            }

            syncPerSetWeightsWithSets();

            return AlertDialog(
              title: Text(
                isAdvanced
                    ? 'Modifica esercizio (Avanzato)'
                    : 'Modifica esercizio',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nome esercizio',
                      ),
                    ),
                    const SizedBox(height: 16),

                    numberStepper(
                      label: 'Serie',
                      valueText: '$sets',
                      onMinus: () => setLocalState(() {
                        if (sets > 1) sets--;
                        syncPerSetWeightsWithSets();
                      }),
                      onPlus: () => setLocalState(() {
                        sets++;
                        syncPerSetWeightsWithSets();
                      }),
                    ),

                    numberStepper(
                      label: 'Ripetizioni',
                      valueText: '$reps',
                      onMinus: () => setLocalState(() {
                        if (reps > 1) reps--;
                      }),
                      onPlus: () => setLocalState(() {
                        reps++;
                      }),
                    ),

                    numberStepper(
                      label: 'Recupero (sec)',
                      valueText: '$restSeconds',
                      onMinus: () => setLocalState(() {
                        restSeconds = (restSeconds - 5).clamp(0, 600);
                      }),
                      onPlus: () => setLocalState(() {
                        restSeconds = (restSeconds + 5).clamp(0, 600);
                      }),
                    ),

                    const SizedBox(height: 8),

                    if (isAdvanced) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Peso per serie'),
                        subtitle: const Text(
                          'Se attivo, imposti un peso per ogni serie',
                        ),
                        value: perSetWeight,
                        onChanged: (v) => setLocalState(() {
                          perSetWeight = v;
                          if (perSetWeight) {
                            // se passo a "per serie", inizializzo da peso unico
                            perSetWeights = List.filled(sets, weightKg);
                          } else {
                            // se torno a peso unico, prendo il primo come default
                            weightKg = perSetWeights.isNotEmpty
                                ? perSetWeights.first
                                : weightKg;
                          }
                        }),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (!perSetWeight) ...[
                      weightRow(
                        label: 'Peso (kg)',
                        value: weightKg,
                        onMinus: () => setLocalState(() {
                          weightKg -= 0.5;
                          if (weightKg < 0) weightKg = 0;
                        }),
                        onPlus: () => setLocalState(() {
                          weightKg += 0.5;
                        }),
                      ),
                    ] else ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pesi per serie',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (int i = 0; i < sets; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: weightRow(
                            label: 'Serie ${i + 1}',
                            value: perSetWeights[i],
                            onMinus: () => setLocalState(() {
                              perSetWeights[i] -= 0.5;
                              if (perSetWeights[i] < 0) perSetWeights[i] = 0;
                            }),
                            onPlus: () => setLocalState(() {
                              perSetWeights[i] += 0.5;
                            }),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final updated = WorkoutExercise(
                      id: initial.id,
                      name: name,
                      sets: sets,
                      reps: reps,
                      weightKg: perSetWeight
                          ? (perSetWeights.isNotEmpty
                                ? perSetWeights.first
                                : weightKg)
                          : weightKg,
                      weightsKg: perSetWeight
                          ? List<double>.from(perSetWeights)
                          : null,
                      restSeconds: restSeconds,
                    );

                    Navigator.of(context).pop(updated);
                  },
                  child: const Text('Salva'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _weightText(WorkoutExercise ex) {
    if (ex.hasPerSetWeights) {
      final w = ex.weightsKg!
          .map((v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1))
          .join(', ');
      return 'kg: [$w]';
    } else {
      final w = ex.weightKg % 1 == 0
          ? ex.weightKg.toInt().toString()
          : ex.weightKg.toStringAsFixed(1);
      return '$w kg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final plan = store.getById(widget.planId);

        if (plan == null) {
          return const Scaffold(
            body: Center(child: Text('Scheda non trovata')),
          );
        }

        // ✅ QUI (prima del return Scaffold)
        final ratio = store.workoutCompletionRatio(widget.planId);
        final pct = (ratio * 100).round();

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: _addExerciseDialog,
            child: const Icon(Icons.add),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                plan.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${plan.exercises.length} esercizi',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),

              // ✅ progress workout
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bar_chart),
                          const SizedBox(width: 8),
                          Text(
                            'Completamento allenamento: $pct%',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        builder: (context, value, _) =>
                            LinearProgressIndicator(value: value),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              if (plan.exercises.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Nessun esercizio. Premi + per aggiungerne uno.',
                    ),
                  ),
                )
              else
                ...plan.exercises.map((ex) {
                  final weightText = _weightText(ex);

                  final pr = store.progressOf(widget.planId, ex);
                  final statusUi = _statusUi(context, pr.status);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: statusUi.bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusUi.borderColor),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      childrenPadding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                        bottom: 8,
                      ),
                      leading: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          statusUi.icon,
                          key: ValueKey(pr.status),
                          color: statusUi.iconColor,
                        ),
                      ),
                      title: Text(ex.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${ex.sets} serie • ${ex.reps} reps • $weightText',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: pr.ratio,
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${pr.doneCount}/${pr.total}',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 18),
                              const SizedBox(width: 6),
                              Text('Recupero: ${ex.restSeconds}s'),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) =>
                                      _RestTimerDialog(seconds: ex.restSeconds),
                                ),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Avvia'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await store.deleteExercise(widget.planId, ex.id);
                          }

                          if (value == 'edit') {
                            final updated = await _editExerciseDialog(ex);
                            if (updated == null) return;

                            await store.updateExercise(
                              planId: widget.planId,
                              updatedEx: updated,
                            );
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Modifica')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Elimina'),
                          ),
                        ],
                        child: const Icon(Icons.more_vert),
                      ),
                      children: [
                        for (int i = 0; i < ex.sets; i++)
                          _SetRow(
                            index: i,
                            ex: ex,
                            done: pr.setDone[i],
                            onChanged: (v) => store.toggleSetDone(
                              planId: widget.planId,
                              ex: ex,
                              setIndex: i,
                              done: v ?? false,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _StatusUI {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;

  _StatusUI({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
  });
}

class _SetRow extends StatelessWidget {
  final int index;
  final WorkoutExercise ex;
  final bool done;
  final ValueChanged<bool?> onChanged;

  const _SetRow({
    required this.index,
    required this.ex,
    required this.done,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final perSetWeight = ex.hasPerSetWeights;
    final w = perSetWeight ? ex.weightsKg![index] : ex.weightKg;

    String formatKg(double v) =>
        (v % 1 == 0) ? v.toInt().toString() : v.toStringAsFixed(1);

    return Card(
      child: CheckboxListTile(
        value: done,
        onChanged: onChanged,
        title: Text('Serie ${index + 1}'),
        subtitle: Text('${ex.reps} reps • ${formatKg(w)} kg'),
      ),
    );
  }
}

class _RestTimerDialog extends StatefulWidget {
  final int seconds;
  const _RestTimerDialog({required this.seconds});

  @override
  State<_RestTimerDialog> createState() => _RestTimerDialogState();
}

class _RestTimerDialogState extends State<_RestTimerDialog> {
  late int left;
  Timer? _t;

  final AudioPlayer _player = AudioPlayer();
  bool _notified = false;

  Future<void> _notifyDone() async {
    if (_notified) return;
    _notified = true;

    // suono
    try {
      await _player.play(AssetSource('sounds/timer_done.mp3'));
    } catch (_) {}

    // vibrazione (se disponibile)
    try {
      final hasVibration = await Vibration.hasVibrator() ?? false;
      if (hasVibration) {
        Vibration.vibrate(duration: 500);
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    left = widget.seconds;
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        left--;
        if (left <= 0) {
          left = 0;
          _t?.cancel();
          _notifyDone();
        }
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _player.dispose();
    super.dispose();
  }

  String mmss(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.seconds == 0 ? 1.0 : left / widget.seconds;

    return AlertDialog(
      title: const Text('Recupero'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mmss(left), style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: ratio),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            left = widget.seconds;
            _notified = false;
          }),
          child: const Text('Reset'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
    );
  }
}
