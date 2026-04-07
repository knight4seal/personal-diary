import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_diary/features/entry_list/providers/entry_list_provider.dart';
import 'package:personal_diary/features/entry_list/widgets/view_mode_selector.dart';
import 'package:personal_diary/features/settings/providers/settings_provider.dart';

class WeeklyViewScreen extends ConsumerStatefulWidget {
  const WeeklyViewScreen({super.key});

  @override
  ConsumerState<WeeklyViewScreen> createState() => _WeeklyViewScreenState();
}

class _WeeklyViewScreenState extends ConsumerState<WeeklyViewScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Start week on Monday
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  void _goToPreviousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
    ref.read(selectedDateProvider.notifier).state = _weekStart;
  }

  void _goToNextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
    ref.read(selectedDateProvider.notifier).state = _weekStart;
  }

  String _formatWeekRange() {
    final startFmt = DateFormat('MMM d').format(_weekStart);
    final endFmt = DateFormat('MMM d, yyyy').format(_weekEnd);
    return '$startFmt – $endFmt';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;
    final grey = Colors.grey;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    final weekEntries = ref.watch(weeklyEntriesProvider);

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: fg, size: 20),
              onPressed: _goToPreviousWeek,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Text(
              _formatWeekRange(),
              style: TextStyle(
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.chevron_right, color: fg, size: 20),
              onPressed: _goToNextWeek,
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
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              const ViewModeSelector(),
              Divider(height: 1, color: dividerColor),
              Expanded(
                child: weekEntries.when(
                  data: (allEntries) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final day =
                            _weekStart.add(Duration(days: index));
                        final dayLabel =
                            DateFormat('EEE, MMM d').format(day);
                        final dayEntries = allEntries
                            .where((e) =>
                                e.entryDate.year == day.year &&
                                e.entryDate.month == day.month &&
                                e.entryDate.day == day.day)
                            .toList();

                        return GestureDetector(
                          onTap: () {
                            ref.read(viewModeProvider.notifier).state =
                                ViewMode.daily;
                            context.go('/daily',
                                extra: day);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                child: Row(
                                  children: [
                                    Text(
                                      dayLabel,
                                      style: TextStyle(
                                        color: fg,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (dayEntries.length > 1) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: grey, width: 1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${dayEntries.length}',
                                          style: TextStyle(
                                              color: grey, fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (dayEntries.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 24, bottom: 12),
                                  child: Text(
                                    'No entries',
                                    style:
                                        TextStyle(color: grey, fontSize: 14),
                                  ),
                                )
                              else
                                ...dayEntries.map((entry) => Padding(
                                      padding: const EdgeInsets.only(
                                          left: 24, right: 24, bottom: 8),
                                      child: Text(
                                        entry.title?.isNotEmpty == true
                                            ? entry.title!
                                            : entry.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: fg, fontSize: 14, height: 1.4),
                                      ),
                                    )),
                              Divider(
                                  height: 1,
                                  color: dividerColor,
                                  indent: 24,
                                  endIndent: 24),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child:
                        CircularProgressIndicator(color: fg, strokeWidth: 1),
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
