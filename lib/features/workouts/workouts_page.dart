import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'workouts_store.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  final store = WorkoutsStore.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await store.loadPlans();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _addPlanDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuova scheda'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome (es. Push, Full Body...)',
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Crea'),
          ),
        ],
      ),
    );

    final name = (result ?? '').trim();
    if (name.isEmpty) return;

    await store.createPlan(name);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final plans = store.plans;

return Scaffold(
  appBar: AppBar(
    title: const Text('Allenamenti'),
    centerTitle: false,
  ),
  floatingActionButton: FloatingActionButton.extended(
    onPressed: _addPlanDialog,
    icon: const Icon(Icons.add),
    label: const Text('Nuova scheda'),
  ),
  body: SafeArea(
    child: plans.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 42,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nessuna scheda',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Crea la tua prima scheda e aggiungi gli esercizi.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _addPlanDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Crea scheda'),
                    ),
                  ],
                ),
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final p = plans[i];

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.go('/workouts/${p.id}'),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.assignment_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: -6,
                                children: [
                                  Chip(
                                    label: Text('${p.exercises.length} esercizi'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'rename') {
                              final ctrl = TextEditingController(text: p.name);
                              final newName = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Rinomina scheda'),
                                  content: TextField(
                                    controller: ctrl,
                                    autofocus: true,
                                    decoration: const InputDecoration(labelText: 'Nome'),
                                    onSubmitted: (v) =>
                                        Navigator.of(context).pop(v.trim()),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(null),
                                      child: const Text('Annulla'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(ctrl.text.trim()),
                                      child: const Text('Salva'),
                                    ),
                                  ],
                                ),
                              );

                              final name = (newName ?? '').trim();
                              if (name.isEmpty) return;

                              await store.renamePlan(p.id, name);
                              if (!mounted) return;
                              setState(() {});
                            }

                            if (value == 'delete') {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Eliminare scheda?'),
                                  content: const Text('Verranno eliminati anche gli esercizi.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Annulla'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Elimina'),
                                    ),
                                  ],
                                ),
                              );

                              if (ok != true) return;

                              await store.deletePlan(p.id);
                              if (!mounted) return;
                              setState(() {});
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'rename', child: Text('Rinomina')),
                            PopupMenuItem(value: 'delete', child: Text('Elimina')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
  ),
);
  }



  
}




