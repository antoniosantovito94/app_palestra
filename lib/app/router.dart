import 'package:go_router/go_router.dart';

import '../shared/widgets/app_shell.dart';

import '../features/workouts/workouts_page.dart';
import '../features/workouts/workout_detail_page.dart';

import '../features/exercises/exercises_page.dart';
import '../features/progress/progress_page.dart';
import '../features/settings/settings_page.dart';


final GoRouter appRouter = GoRouter(
  initialLocation: '/workouts',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/workouts',
          builder: (context, state) => const WorkoutsPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return WorkoutDetailPage(planId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/exercises',
          builder: (context, state) => const ExercisesPage(),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const ProgressPage(),
        ),
        GoRoute(
  path: '/settings',
  builder: (context, state) => const SettingsPage(),
),
      ],
    ),
  ],
);