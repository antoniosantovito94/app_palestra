import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/workout_models.dart';
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _exercisePreview(List<WorkoutExercise> exercises) {
    if (exercises.isEmpty) return 'Nessun esercizio aggiunto';
    final names = exercises.take(2).map((e) => e.name).join(' · ');
    final extra = exercises.length - 2;
    return extra > 0 ? '$names  +$extra altri' : names;
  }

  int _totalSets(List<WorkoutExercise> exercises) =>
      exercises.fold(0, (sum, e) => sum + e.sets);

  // ── Dialogs ───────────────────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
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
            child: plans.isEmpty ? _buildEmptyState() : _buildList(plans),
          ),
        );
      },
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nessuna scheda',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea la tua prima scheda e inizia ad aggiungere esercizi.',
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _addPlanDialog,
              icon: const Icon(Icons.add),
              label: const Text('Crea scheda'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lista schede ──────────────────────────────────────────────────────────

  Widget _buildList(List<WorkoutPlan> plans) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _PlanCard(
        plan: plans[i],
        ratio: store.workoutCompletionRatio(plans[i].id),
        exercisePreview: _exercisePreview(plans[i].exercises),
        totalSets: _totalSets(plans[i].exercises),
        onTap: () => context.go('/workouts/${plans[i].id}'),
        onRename: () => _renamePlanDialog(plans[i]),
        onDelete: () => _deletePlanDialog(plans[i]),
      ),
    );
  }

  Future<void> _renamePlanDialog(WorkoutPlan plan) async {
    final ctrl = TextEditingController(text: plan.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rinomina scheda'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    final name = (newName ?? '').trim();
    if (name.isEmpty) return;

    await store.renamePlan(plan.id, name);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deletePlanDialog(WorkoutPlan plan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare scheda?'),
        content: const Text('Verranno eliminati anche tutti gli esercizi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await store.deletePlan(plan.id);
    if (!mounted) return;
    setState(() {});
  }
}

// ── _PlanCard ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final WorkoutPlan plan;
  final double ratio;
  final String exercisePreview;
  final int totalSets;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _PlanCard({
    required this.plan,
    required this.ratio,
    required this.exercisePreview,
    required this.totalSets,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasExercises = plan.exercises.isNotEmpty;
    final isComplete = ratio == 1.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isComplete
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icona
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isComplete
                      ? colorScheme.primaryContainer
                      : colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isComplete
                      ? Icons.check_circle_rounded
                      : Icons.assignment_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),

              // Contenuto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome
                    Text(
                      plan.name,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),

                    // Preview esercizi
                    Text(
                      exercisePreview,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Metadati
                    if (hasExercises)
                      Text(
                        '${plan.exercises.length} esercizi  ·  $totalSets serie',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                    // Progress bar
                    if (hasExercises) ...[
                      const SizedBox(height: 12),
                      _ProgressRow(
                        ratio: ratio,
                        isComplete: isComplete,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                    ],
                  ],
                ),
              ),

              // Menu
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'rename') onRename();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rinomina')),
                  PopupMenuItem(value: 'delete', child: Text('Elimina')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _ProgressRow ──────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final double ratio;
  final bool isComplete;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ProgressRow({
    required this.ratio,
    required this.isComplete,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete
                    ? colorScheme.primary
                    : colorScheme.primary.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        isComplete
            ? Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: colorScheme.primary,
              )
            : Text(
                '${(ratio * 100).round()}%',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ],
    );
  }
}
