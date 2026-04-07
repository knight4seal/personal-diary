import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_diary/features/entry_list/providers/entry_list_provider.dart';
import 'package:personal_diary/features/settings/providers/settings_provider.dart';

class ViewModeSelector extends ConsumerWidget {
  const ViewModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(viewModeProvider);
    final isDark = ref.watch(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final grey = Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildModeButton('D', ViewMode.daily, currentMode, fg, grey, ref,
              context),
          const SizedBox(width: 24),
          _buildModeButton('W', ViewMode.weekly, currentMode, fg, grey, ref,
              context),
          const SizedBox(width: 24),
          _buildModeButton('M', ViewMode.monthly, currentMode, fg, grey, ref,
              context),
          const SizedBox(width: 24),
          _buildModeButton('Y', ViewMode.yearly, currentMode, fg, grey, ref,
              context),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    String label,
    ViewMode mode,
    ViewMode currentMode,
    Color fg,
    Color grey,
    WidgetRef ref,
    BuildContext context,
  ) {
    final isActive = mode == currentMode;

    return GestureDetector(
      onTap: () {
        ref.read(viewModeProvider.notifier).state = mode;
        switch (mode) {
          case ViewMode.daily:
            context.go('/daily');
            break;
          case ViewMode.weekly:
            context.go('/weekly');
            break;
          case ViewMode.monthly:
            context.go('/monthly');
            break;
          case ViewMode.yearly:
            context.go('/yearly');
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? fg : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? fg : grey,
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
