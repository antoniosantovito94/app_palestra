import 'package:flutter/material.dart';
import 'progress_store.dart';
import 'models/session_models.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final store = ProgressStore.instance;
  String? _selectedPlan;
  String? _selectedExercise;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await store.loadSessions();
    if (!mounted) return;
    setState(() {});
  }

  String _formatDate(DateTime dt) {
    const weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    const months = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic',
    ];
    return '${weekdays[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}';
  }

  String _formatKg(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  // ── Titolo ────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Text(
                        'Progressi',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Stats ─────────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildStats(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),

                  if (store.sessions.isEmpty && store.loaded) ...[
                    SliverToBoxAdapter(child: _buildEmpty(context)),
                  ] else ...[
                    // ── Progressione pesi ─────────────────────────────
                    if (store.allExerciseNames.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(context, 'Progressione pesi',
                            Icons.trending_up_rounded),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      SliverToBoxAdapter(
                          child: _buildWeightProgression(context)),
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    ],

                    // ── Storico sessioni ──────────────────────────────
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(
                          context, 'Storico sessioni', Icons.history_rounded),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) =>
                            _buildSessionCard(context, store.sessions[i]),
                        childCount: store.sessions.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Sezione title ─────────────────────────────────────────────────────────

  Widget _buildSectionTitle(BuildContext ctx, String title, IconData icon) {
    final cs = Theme.of(ctx).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(ctx)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Widget _buildStats(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final streak = store.streak;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Hero streak card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Streak attuale',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                            ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$streak',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: cs.onPrimaryContainer,
                                  ),
                            ),
                            TextSpan(
                              text: '  giorni',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: cs.onPrimaryContainer
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 56,
                  color: streak > 0
                      ? Colors.deepOrange.shade400
                      : cs.onPrimaryContainer.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 2 mini stats
          Row(
            children: [
              _MiniStat(
                icon: Icons.fitness_center_rounded,
                label: 'Sessioni totali',
                value: '${store.totalSessions}',
              ),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.date_range_rounded,
                label: 'Questa settimana',
                value: '${store.thisWeekSessions}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Progressione pesi ─────────────────────────────────────────────────────

  Widget _buildWeightProgression(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final planNames = store.planNames;

    // Inizializza / correggi selezione scheda
    _selectedPlan ??= planNames.first;
    if (!planNames.contains(_selectedPlan)) _selectedPlan = planNames.first;

    final exercises = store.exerciseNamesForPlan(_selectedPlan!);

    // Inizializza / correggi selezione esercizio
    if (exercises.isEmpty) {
      _selectedExercise = null;
    } else {
      if (_selectedExercise == null || !exercises.contains(_selectedExercise)) {
        _selectedExercise = exercises.first;
      }
    }

    final history = _selectedExercise == null
        ? <({DateTime date, double weightKg, int setsDone, int sets})>[]
        : store.weightHistory(_selectedPlan!, _selectedExercise!);

    final maxWeight = history.isEmpty
        ? 0.0
        : history.map((h) => h.weightKg).reduce((a, b) => a > b ? a : b);
    final minWeight = history.isEmpty
        ? 0.0
        : history.map((h) => h.weightKg).reduce((a, b) => a < b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip selector SCHEDA
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: planNames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final isSelected = planNames[i] == _selectedPlan;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedPlan = planNames[i];
                  _selectedExercise = null; // reset esercizio
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.secondaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(
                            color: cs.secondary.withValues(alpha: 0.5))
                        : null,
                  ),
                  child: Text(
                    planNames[i],
                    style: TextStyle(
                      color: isSelected
                          ? cs.onSecondaryContainer
                          : cs.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Chip selector ESERCIZIO
        if (exercises.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: exercises.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final isSelected = exercises[i] == _selectedExercise;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedExercise = exercises[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      exercises[i],
                      style: TextStyle(
                        color: isSelected
                            ? cs.onPrimary
                            : cs.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 14),

        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Nessuna sessione con questo esercizio.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final h = history[i];
                final isPR = h.weightKg == maxWeight;
                final prev = i > 0 ? history[i - 1].weightKg : null;
                final diff = prev == null ? null : h.weightKg - prev;
                final relRatio = maxWeight == minWeight
                    ? 1.0
                    : (h.weightKg - minWeight) / (maxWeight - minWeight);

                return _WeightCard(
                  date: _formatDate(h.date),
                  weightText: '${_formatKg(h.weightKg)} kg',
                  diff: diff,
                  isPR: isPR,
                  relRatio: relRatio,
                  cs: cs,
                );
              },
            ),
          ),
      ],
    );
  }

  // ── Storico sessioni ──────────────────────────────────────────────────────

  Widget _buildSessionCard(BuildContext context, WorkoutSession session) {
    final cs = Theme.of(context).colorScheme;
    final completionRatio = session.exercises.isEmpty
        ? 0.0
        : session.exercises.where((e) => e.isComplete).length /
            session.exercises.length;
    final isComplete = session.isFullyComplete;
    final accentColor = isComplete ? cs.tertiary : cs.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.hardEdge,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
          childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          leading: Container(
            width: 5,
            height: double.infinity,
            color: accentColor,
          ),
          title: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.planName,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(session.completedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: completionRatio,
                          minHeight: 4,
                          backgroundColor:
                              accentColor.withValues(alpha: 0.15),
                          valueColor:
                              AlwaysStoppedAnimation(accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(completionRatio * 100).round()}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: isComplete
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '✓',
                    style: TextStyle(
                      color: cs.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                )
              : null,
          children: session.exercises.map((ex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(
                    ex.isComplete
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 17,
                    color: ex.isComplete ? cs.tertiary : cs.outlineVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ex.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_formatKg(ex.weightKg)} kg',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${ex.setsDone}/${ex.sets}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmpty(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.show_chart_rounded, size: 36, color: cs.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessuna sessione ancora',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa tutti gli esercizi di una scheda per registrare la tua prima sessione.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini stat card ────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weight card ───────────────────────────────────────────────────────────────

class _WeightCard extends StatelessWidget {
  final String date;
  final String weightText;
  final double? diff;
  final bool isPR;
  final double relRatio;
  final ColorScheme cs;

  const _WeightCard({
    required this.date,
    required this.weightText,
    required this.diff,
    required this.isPR,
    required this.relRatio,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    Color? diffColor;
    IconData? diffIcon;
    String diffText = '';

    if (diff != null && diff != 0) {
      if (diff! > 0) {
        diffColor = Colors.green.shade600;
        diffIcon = Icons.arrow_upward_rounded;
        diffText = '+${diff!.toStringAsFixed(diff! % 1 == 0 ? 0 : 1)}';
      } else {
        diffColor = Colors.red.shade400;
        diffIcon = Icons.arrow_downward_rounded;
        diffText = diff!.toStringAsFixed(diff! % 1 == 0 ? 0 : 1);
      }
    }

    final bgColor =
        isPR ? cs.primaryContainer : cs.surfaceContainerHighest.withValues(alpha: 0.5);
    final borderColor =
        isPR ? cs.primary.withValues(alpha: 0.4) : cs.outlineVariant;

    return Container(
      width: 120,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PR badge o spazio vuoto
          if (isPR)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'PR',
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            const SizedBox(height: 18),
          const Spacer(),
          // Peso
          Text(
            weightText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isPR ? cs.onPrimaryContainer : null,
                ),
          ),
          const SizedBox(height: 2),
          // Diff
          if (diff != null && diff != 0)
            Row(
              children: [
                Icon(diffIcon, size: 11, color: diffColor),
                Text(
                  diffText,
                  style: TextStyle(
                    fontSize: 11,
                    color: diffColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 13),
          const SizedBox(height: 6),
          // Barra relativa al PR
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: relRatio,
              minHeight: 3,
              backgroundColor: cs.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(
                isPR ? cs.primary : cs.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Data
          Text(
            date,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isPR
                      ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                      : cs.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
