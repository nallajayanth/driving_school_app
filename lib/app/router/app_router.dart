import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/exam_history/domain/exam_attempt.dart';
import '../../features/exam_history/presentation/exam_history_screen.dart';
import '../../features/learning/presentation/learning_screen.dart';
import '../../features/learning/presentation/question_detail_screen.dart';
import '../../features/navigation/presentation/main_scaffold_shell.dart';
import '../../features/preliminary_check/presentation/exam_result_screen.dart';
import '../../features/preliminary_check/presentation/exam_session_screen.dart';
import '../../features/preliminary_check/presentation/preliminary_check_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _dashboardNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'dashboardNav');
final GlobalKey<NavigatorState> _learningNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'learningNav');
final GlobalKey<NavigatorState> _preliminaryNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'preliminaryNav');
final GlobalKey<NavigatorState> _progressNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'progressNav');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffoldShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _learningNavigatorKey,
            routes: [
              GoRoute(
                path: '/learning',
                name: 'learning',
                builder: (context, state) => const LearningScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _preliminaryNavigatorKey,
            routes: [
              GoRoute(
                path: '/preliminary-check',
                name: 'preliminary-check',
                builder: (context, state) => const PreliminaryCheckScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _progressNavigatorKey,
            routes: [
              GoRoute(
                path: '/progress',
                name: 'progress',
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/exam-history',
        name: 'exam-history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExamHistoryScreen(),
      ),
      GoRoute(
        path: '/exam-session',
        name: 'exam-session',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExamSessionScreen(),
      ),
      GoRoute(
        path: '/exam-result',
        name: 'exam-result',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final attempt = state.extra is ExamAttempt
              ? state.extra as ExamAttempt
              : ExamAttempt(
                  id: 'fallback_attempt',
                  dateTime: DateTime.now(),
                  selectedClasses: const ['GW'],
                  totalQuestions: 0,
                  pointsScored: 0,
                  scorePercentage: 0.0,
                  isPassed: false,
                  statusLabel: 'Demonstration',
                );
          return ExamResultScreen(attempt: attempt);
        },
      ),
      GoRoute(
        path: '/learning/question/:questionNumber',
        name: 'question-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final numberStr = state.pathParameters['questionNumber'] ?? '0';
          final questionNumber = int.tryParse(numberStr) ?? 0;
          return QuestionDetailScreen(questionNumber: questionNumber);
        },
      ),
    ],
  );
});
