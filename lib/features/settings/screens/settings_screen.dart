import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personal_diary/features/entry_list/providers/entry_list_provider.dart';
import 'package:personal_diary/features/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;
    final grey = Colors.grey;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final autoLockMinutes = ref.watch(autoLockTimeoutProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: fg),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            color: fg,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round,
                color: fg),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            children: [
              // Biometric lock
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Biometric Lock',
                        style: TextStyle(color: fg, fontSize: 16),
                      ),
                    ),
                    Switch.adaptive(
                      value: biometricEnabled,
                      onChanged: (value) {
                        ref
                            .read(biometricEnabledProvider.notifier)
                            .setEnabled(value);
                      },
                      activeColor: fg,
                      inactiveThumbColor: grey,
                      inactiveTrackColor:
                          grey.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              Divider(color: dividerColor, indent: 24, endIndent: 24),
              // Auto-lock timeout
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Auto-lock timeout',
                        style: TextStyle(color: fg, fontSize: 16),
                      ),
                    ),
                    DropdownButton<int>(
                      value: autoLockMinutes,
                      dropdownColor: bg,
                      underline: Container(
                        height: 1,
                        color: dividerColor,
                      ),
                      style: TextStyle(color: fg, fontSize: 14),
                      items: const [1, 2, 5, 10, 15].map((minutes) {
                        return DropdownMenuItem(
                          value: minutes,
                          child: Text('$minutes min'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(autoLockTimeoutProvider.notifier)
                              .setTimeout(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Divider(color: dividerColor, indent: 24, endIndent: 24),
              const SizedBox(height: 16),
              // Export
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: OutlinedButton(
                  onPressed: () => _exportDiary(context, ref, fg, bg),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: fg,
                    side: BorderSide(color: fg),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    'Export Diary',
                    style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // About
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: TextStyle(
                        color: fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Personal Diary',
                      style: TextStyle(
                        color: fg,
                        fontSize: 16,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(color: grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A simple, private diary app. Your entries are encrypted and stored locally on your device.',
                      style: TextStyle(
                        color: grey,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportDiary(
      BuildContext context, WidgetRef ref, Color fg, Color bg) async {
    try {
      final repo = ref.read(diaryRepositoryProvider);
      final jsonString = await repo.exportToJson();

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/diary_export.json');
      await file.writeAsString(jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}
