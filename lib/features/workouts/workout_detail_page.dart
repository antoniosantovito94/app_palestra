import 'package:flutter/material.dart';

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
                isAdvanced ? 'Aggiungi esercizio (Avanzato)' : 'Aggiungi esercizio',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Nome esercizio'),
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

                    const SizedBox(height: 8),

                    if (isAdvanced) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Peso per serie'),
                        subtitle: const Text('Se attivo, imposti un peso per ogni serie'),
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
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      name: name,
                      sets: sets,
                      reps: reps,
                      weightKg: perSetWeight ? perSetWeights.first : weightKg,
                      weightsKg: perSetWeight ? List<double>.from(perSetWeights) : null,
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

    setState(() {
      store.addExercise(widget.planId, result);
    });
  }

  String _weightText(WorkoutExercise ex) {
    if (ex.hasPerSetWeights) {
      final w = ex.weightsKg!
          .map((v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1))
          .join(', ');
      return 'kg: [$w]';
    } else {
      final w = ex.weightKg % 1 == 0 ? ex.weightKg.toInt().toString() : ex.weightKg.toStringAsFixed(1);
      return '$w kg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = store.getById(widget.planId);

    if (plan == null) {
      return const Scaffold(
        body: Center(child: Text('Scheda non trovata')),
      );
    }

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
          const SizedBox(height: 16),
          if (plan.exercises.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nessun esercizio. Premi + per aggiungerne uno.'),
              ),
            )
          else
            ...plan.exercises.map((ex) {
              final weightText = _weightText(ex);

              return Card(
                child: ListTile(
                  title: Text(ex.name),
                  subtitle: Text('${ex.sets} serie • ${ex.reps} reps • $weightText'),
                ),
              );
            }),
        ],
      ),
    );
  }
}