import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/admin_screen.dart';
import 'screens/counselor_screen.dart';
import 'screens/parent_screen.dart';
import 'screens/parent_view_screen.dart';
import 'screens/results_screen.dart';
import 'screens/site/audience_pages.dart';
import 'screens/site/careers_pages.dart';
import 'screens/site/home_page.dart';
import 'screens/site/how_it_works_page.dart';
import 'screens/student_screen.dart';
import 'widgets/interactions.dart';

/// App pages fade in while rising 12px. Skipped when the OS asks for reduced motion.
Page<void> _appPage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: AnimatedBuilder(
            animation: curved,
            builder: (context, child) => Transform.translate(offset: Offset(0, 12 * (1 - curved.value)), child: child),
            child: child,
          ),
        );
      },
    );

/// Marketing page: spectrum curtain transition.
GoRoute _site(String path, Widget Function(GoRouterState state) build) =>
    GoRoute(path: path, pageBuilder: (context, state) => curtainPage(state, build(state)));

/// App page: fade and rise.
GoRoute _app(String path, Widget Function(GoRouterState state) build) =>
    GoRoute(path: path, pageBuilder: (context, state) => _appPage(state, build(state)));

final appRouter = GoRouter(
  routes: [
    // Marketing site
    _site('/', (s) => const HomePage()),
    _site('/how-it-works', (s) => const HowItWorksPage()),
    _site('/careers', (s) => const CareersPage()),
    _site('/careers/:id', (s) => CareerDetailPage(id: s.pathParameters['id'] ?? '')),
    _site('/parents', (s) => const ParentsPage()),
    _site('/schools', (s) => const SchoolsPage()),
    _site('/about', (s) => const AboutPage()),
    // Old routes now live on the About page.
    GoRoute(path: '/methodology', redirect: (context, state) => '/about'),
    GoRoute(path: '/data-sources', redirect: (context, state) => '/about'),
    // App
    _app('/student', (s) => const StudentScreen()),
    _app('/parent', (s) => ParentScreen(initialCode: s.uri.queryParameters['code'])),
    _app('/results', (s) => const ResultsScreen()),
    _app('/parent-view', (s) => const ParentViewScreen()),
    _app('/counselor', (s) => const CounselorScreen()),
    _app('/admin', (s) => const AdminScreen()),
  ],
);
