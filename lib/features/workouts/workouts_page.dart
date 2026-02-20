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
      floatingActionButton: FloatingActionButton(
        onPressed: _addPlanDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final p = plans[i];
          return Card(
            child: ListTile(
              title: Text(p.name),
              subtitle: Text('${p.exercises.length} esercizi'),
              trailing: PopupMenuButton<String>(
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
                        content: const Text(
                          'Verranno eliminati anche gli esercizi.',
                        ),
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
                child: const Icon(Icons.more_vert),
              ),
              onTap: () => context.go('/workouts/${p.id}'),
            ),
          );
        },
      ),
    );
  }



  
}




