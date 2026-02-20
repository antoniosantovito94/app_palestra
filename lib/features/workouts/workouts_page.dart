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

    setState(() {
      store.addPlan(name);
    });
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
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/workouts/${p.id}'),
            ),
          );
        },
      ),
    );
  }
}