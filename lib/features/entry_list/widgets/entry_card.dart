import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_diary/features/entry_list/providers/entry_list_provider.dart';
import 'package:personal_diary/features/settings/providers/settings_provider.dart';

class EntryCard extends ConsumerWidget {
  final String id;
  final String? title;
  final String content;
  final DateTime dateTime;
  final bool isVoiceTranscribed;

  const EntryCard({
    super.key,
    required this.id,
    this.title,
    required this.content,
    required this.dateTime,
    this.isVoiceTranscribed = false,
  });

  void _showOptions(BuildContext context, WidgetRef ref) {
    final isDark = ref.read(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;
    final grey = Colors.grey;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: fg),
              title: Text('Edit', style: TextStyle(color: fg)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/entry/edit/$id');
              },
            ),
            Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),
            ListTile(
              leading: Icon(Icons.delete_outline, color: grey),
              title: Text('Delete', style: TextStyle(color: grey)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    backgroundColor: bg,
                    title: Text('Delete Entry', style: TextStyle(color: fg)),
                    content: Text(
                      'This entry will be permanently deleted.',
                      style: TextStyle(color: grey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2, false),
                        child: Text('Cancel', style: TextStyle(color: grey)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2, true),
                        child: Text('Delete', style: TextStyle(color: fg)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref
                      .read(diaryRepositoryProvider)
                      .deleteEntry(int.parse(id));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final grey = Colors.grey;

    final h = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final m = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'p' : 'a';
    final timeString = '$h:$m$ampm';

    return GestureDetector(
      onTap: () => context.push('/entry/edit/$id'),
      onLongPress: () => _showOptions(context, ref),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null && title!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  title!,
                  style: TextStyle(
                    color: fg,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              content,
              style: TextStyle(
                color: fg,
                fontSize: 16,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isVoiceTranscribed)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.mic, size: 14, color: grey),
                  ),
                Text(
                  timeString,
                  style: TextStyle(color: grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
