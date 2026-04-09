import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_diary/core/extensions/date_extensions.dart';
import 'package:personal_diary/features/entry_list/providers/entry_list_provider.dart';
import 'package:personal_diary/features/entry_list/widgets/entry_card.dart';
import 'package:personal_diary/features/entry_list/widgets/view_mode_selector.dart';
import 'package:personal_diary/features/settings/providers/settings_provider.dart';
import 'package:personal_diary/services/quote_service.dart';
import 'package:personal_diary/features/selfie/widgets/selfie_thumbnail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyViewScreen extends ConsumerStatefulWidget {
  const DailyViewScreen({super.key});

  @override
  ConsumerState<DailyViewScreen> createState() => _DailyViewScreenState();
}

class _DailyViewScreenState extends ConsumerState<DailyViewScreen> {
  late DateTime _selectedDate;
  String? _quote;
  String? _quoteAuthor;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quoteService = QuoteService(prefs);
      final result = await quoteService.getDailyQuote();
      if (mounted) {
        setState(() {
          _quote = result.text;
          _quoteAuthor = result.author;
        });
      }
    } catch (_) {}
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    ref.read(selectedDateProvider.notifier).state = _selectedDate;
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    ref.read(selectedDateProvider.notifier).state = _selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;
    final grey = Colors.grey;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    final entries = ref.watch(dailyEntriesProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.search, color: fg),
          onPressed: () => context.push('/search'),
        ),
        leadingWidth: 48,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelfieThumbnail(date: _selectedDate, size: 32),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.chevron_left, color: fg, size: 20),
              onPressed: _goToPreviousDay,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _selectedDate.formattedDate,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.chevron_right, color: fg, size: 20),
              onPressed: _goToNextDay,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round,
                color: fg),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: fg),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              const ViewModeSelector(),
              Divider(height: 1, color: dividerColor),
              // Daily quote
              if (_quote != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        '"$_quote"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontStyle: FontStyle.italic,
                          color: grey,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      if (_quoteAuthor != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '— $_quoteAuthor',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Divider(height: 1, color: dividerColor),
              // Entries list
              Expanded(
                child: entries.when(
                  data: (entryList) {
                    if (entryList.isEmpty) {
                      return Center(
                        child: Text(
                          'No entries yet',
                          style: TextStyle(color: grey, fontSize: 16),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: entryList.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: dividerColor, indent: 24, endIndent: 24),
                      itemBuilder: (context, index) {
                        final entry = entryList[index];
                        return Dismissible(
                          key: Key(entry.id.toString()),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: bg,
                                title: Text('Delete Entry', style: TextStyle(color: fg)),
                                content: Text('Are you sure?', style: TextStyle(color: fg)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text('Cancel', style: TextStyle(color: grey)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text('Delete', style: TextStyle(color: fg)),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) {
                            ref.read(diaryRepositoryProvider).deleteEntry(entry.id);
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: Icon(Icons.delete_outline, color: grey),
                          ),
                          child: EntryCard(
                            id: entry.id.toString(),
                            title: entry.title,
                            content: entry.content,
                            dateTime: entry.entryDate,
                            isVoiceTranscribed: entry.isVoiceTranscribed,
                            lastEditedAt: entry.lastEditedAt,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(color: fg, strokeWidth: 1),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e', style: TextStyle(color: grey)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: fg,
        onPressed: () => context.push('/entry/new'),
        child: Icon(Icons.add, color: bg),
      ),
    );
  }
}
