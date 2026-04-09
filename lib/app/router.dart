import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_diary/features/auth/providers/auth_provider.dart';
import 'package:personal_diary/features/auth/screens/lock_screen.dart';
import 'package:personal_diary/features/entry_editor/screens/entry_editor_screen.dart';
import 'package:personal_diary/features/entry_list/screens/daily_view_screen.dart';
import 'package:personal_diary/features/entry_list/screens/weekly_view_screen.dart';
import 'package:personal_diary/features/entry_list/screens/monthly_view_screen.dart';
import 'package:personal_diary/features/entry_list/screens/yearly_view_screen.dart';
import 'package:personal_diary/features/search/screens/search_screen.dart';
import 'package:personal_diary/features/settings/screens/settings_screen.dart';
import 'package:personal_diary/features/selfie/screens/selfie_timeline_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/lock',
    redirect: (context, state) {
      final isLockScreen = state.matchedLocation == '/lock';
      final isUnlocked = authState == AuthState.unlocked;

      if (isUnlocked && isLockScreen) {
        return '/daily';
      }

      if (!isUnlocked && !isLockScreen) {
        return '/lock';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LockScreen(),
      ),
      GoRoute(
        path: '/daily',
        builder: (context, state) => const DailyViewScreen(),
      ),
      GoRoute(
        path: '/weekly',
        builder: (context, state) => const WeeklyViewScreen(),
      ),
      GoRoute(
        path: '/monthly',
        builder: (context, state) => const MonthlyViewScreen(),
      ),
      GoRoute(
        path: '/yearly',
        builder: (context, state) => const YearlyViewScreen(),
      ),
      GoRoute(
        path: '/entry/new',
        builder: (context, state) => const EntryEditorScreen(),
      ),
      GoRoute(
        path: '/entry/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EntryEditorScreen(entryId: id);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/selfie-timeline',
        builder: (context, state) => const SelfieTimelineScreen(),
      ),
    ],
  );
});
