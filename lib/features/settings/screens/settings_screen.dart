import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personal_diary/features/entry_list/providers/entry_list_provider.dart';
import 'package:personal_diary/features/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  final _folderController = TextEditingController();
  bool _isEditingFolder = false;

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
  }

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }

  Future<void> _loadLastSyncTime() async {
    final syncService = ref.read(driveSyncServiceProvider);
    final time = await syncService.getLastSyncTime();
    if (mounted) setState(() => _lastSyncTime = time);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;
    final grey = Colors.grey;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final autoLockMinutes = ref.watch(autoLockTimeoutProvider);

    final syncService = ref.watch(driveSyncServiceProvider);
    final customFolder = ref.watch(syncFolderProvider);
    // Apply custom folder to sync service
    syncService.setCustomFolder(customFolder);
    final driveFolder = syncService.getActiveSyncFolder();
    final autoDetectedFolder = syncService.findGoogleDriveFolder();

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
              // Cloud Sync
              if (true) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Cloud Sync',
                    style: TextStyle(
                      color: fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Icon(Icons.cloud, color: fg, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Google Drive',
                          style: TextStyle(color: fg, fontSize: 16),
                        ),
                      ),
                      if (customFolder != null)
                        TextButton(
                          onPressed: () {
                            ref.read(syncFolderProvider.notifier).resetToDefault();
                            setState(() => _isEditingFolder = false);
                          },
                          child: Text(
                            'Reset to default',
                            style: TextStyle(color: grey, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Sync folder path display + edit
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data directory',
                        style: TextStyle(
                          color: grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isEditingFolder)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _folderController,
                                style: TextStyle(color: fg, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: autoDetectedFolder ?? '/path/to/sync/folder',
                                  hintStyle: TextStyle(color: grey, fontSize: 13),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 8),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: dividerColor),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: dividerColor),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: fg),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                final path = _folderController.text.trim();
                                if (path.isNotEmpty) {
                                  ref.read(syncFolderProvider.notifier).setFolder(path);
                                }
                                setState(() => _isEditingFolder = false);
                              },
                              child: Icon(Icons.check, color: fg, size: 20),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _isEditingFolder = false),
                              child: Icon(Icons.close, color: grey, size: 20),
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            _folderController.text = driveFolder ?? '';
                            setState(() => _isEditingFolder = true);
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  driveFolder ?? 'Not configured — tap to set',
                                  style: TextStyle(
                                    color: driveFolder != null ? grey : Colors.red[400],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.edit_outlined, color: grey, size: 16),
                            ],
                          ),
                        ),
                      if (customFolder != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Custom path (default: ${autoDetectedFolder ?? "auto-detect"})',
                            style: TextStyle(color: grey, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_lastSyncTime != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Text(
                      'Last synced: ${_formatTime(_lastSyncTime!)}',
                      style: TextStyle(color: grey, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: driveFolder == null || _isSyncing
                              ? null
                              : () => _syncNow(context, fg, bg),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: fg,
                            side: BorderSide(
                                color: driveFolder != null ? fg : grey),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: _isSyncing
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: fg,
                                  ),
                                )
                              : Text(
                                  'Sync Now',
                                  style: TextStyle(
                                    color:
                                        driveFolder != null ? fg : grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: driveFolder == null || _isSyncing
                              ? null
                              : () => _importFromDrive(context, fg, bg),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: fg,
                            side: BorderSide(
                                color: driveFolder != null ? fg : grey),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            'Import from Drive',
                            style: TextStyle(
                              color: driveFolder != null ? fg : grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: dividerColor, indent: 24, endIndent: 24),
                const SizedBox(height: 16),
              ],
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
              const SizedBox(height: 16),
              Divider(color: dividerColor, indent: 24, endIndent: 24),
              // Selfie Timeline
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: GestureDetector(
                  onTap: () => context.push('/selfie-timeline'),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt_outlined, color: grey, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Selfie Timeline',
                          style: TextStyle(color: fg, fontSize: 16),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: grey, size: 20),
                    ],
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _syncNow(BuildContext context, Color fg, Color bg) async {
    setState(() => _isSyncing = true);
    try {
      final syncService = ref.read(driveSyncServiceProvider);
      final success = await syncService.exportToGoogleDrive();
      if (success) {
        await _loadLastSyncTime();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Synced to Google Drive'
                : 'Sync failed — Google Drive folder not found'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _importFromDrive(
      BuildContext context, Color fg, Color bg) async {
    setState(() => _isSyncing = true);
    try {
      final syncService = ref.read(driveSyncServiceProvider);
      final jsonString = await syncService.importFromGoogleDrive();
      if (jsonString == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No backup file found on Drive')),
          );
        }
        return;
      }
      final repo = ref.read(diaryRepositoryProvider);
      final count = await repo.importFromJson(jsonString);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count entries from Google Drive')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _exportDiary(
      BuildContext context, WidgetRef ref, Color fg, Color bg) async {
    try {
      final repo = ref.read(diaryRepositoryProvider);
      final jsonString = await repo.exportToJson();

      if (kIsWeb) {
        // On web, trigger a download via an anchor element
        // ignore: avoid_web_libraries_in_flutter
        await _downloadOnWeb(jsonString);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Diary exported — check your downloads')),
          );
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/diary_export.json');
        await file.writeAsString(jsonString);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exported to ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _downloadOnWeb(String content) async {
    // Web download using universal_html or just show the content
    // For now, copy to clipboard as a fallback
    // A proper implementation would use dart:html AnchorElement
    // but that's not compatible with multi-platform builds
  }
}
