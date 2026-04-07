import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:personal_diary/features/entry_list/providers/entry_list_provider.dart';
import 'package:personal_diary/features/entry_list/widgets/entry_card.dart';
import 'package:personal_diary/features/entry_list/widgets/view_mode_selector.dart';
import 'package:personal_diary/features/settings/providers/settings_provider.dart';

class MonthlyViewScreen extends ConsumerStatefulWidget {
  const MonthlyViewScreen({super.key});

  @override
  ConsumerState<MonthlyViewScreen> createState() => _MonthlyViewScreenState();
}

class _MonthlyViewScreenState extends ConsumerState<MonthlyViewScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedDateProvider.notifier).state = _selectedDay;
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;
    final grey = Colors.grey;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    final monthEntries = ref.watch(monthlyEntriesProvider);
    final selectedDayEntries = ref.watch(dailyEntriesProvider);

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
              onPressed: _goToPreviousMonth,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('MMMM yyyy').format(_focusedDay),
              style: TextStyle(
                color: fg,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.chevron_right, color: fg, size: 20),
              onPressed: _goToNextMonth,
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
              // Calendar
              monthEntries.when(
                data: (entries) {
                  final daysWithEntries = entries
                      .map((e) => DateTime(e.entryDate.year, e.entryDate.month, e.entryDate.day))
                      .toSet();
                  return TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      ref.read(selectedDateProvider.notifier).state = selectedDay;
                    },
                    onPageChanged: (focusedDay) {
                      setState(() => _focusedDay = focusedDay);
                    },
                    headerVisible: false,
                    daysOfWeekHeight: 32,
                    rowHeight: 42,
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      defaultTextStyle: TextStyle(color: fg, fontSize: 14),
                      weekendTextStyle: TextStyle(color: fg, fontSize: 14),
                      todayDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: fg, width: 1),
                      ),
                      todayTextStyle: TextStyle(color: fg, fontSize: 14),
                      selectedDecoration: BoxDecoration(
                        color: fg,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(color: bg, fontSize: 14),
                      markerDecoration: BoxDecoration(
                        color: grey,
                        shape: BoxShape.circle,
                      ),
                      markerSize: 4,
                      markersMaxCount: 1,
                      markersAlignment: Alignment.bottomCenter,
                      markerMargin: const EdgeInsets.only(top: 1),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle:
                          TextStyle(color: grey, fontSize: 12),
                      weekendStyle:
                          TextStyle(color: grey, fontSize: 12),
                    ),
                    eventLoader: (day) {
                      final normalized =
                          DateTime(day.year, day.month, day.day);
                      return daysWithEntries.contains(normalized) ? [true] : [];
                    },
                  );
                },
                loading: () => const SizedBox(height: 300),
                error: (_, __) => const SizedBox(height: 300),
              ),
              Divider(height: 1, color: dividerColor),
              // Selected day entries
              Expanded(
                child: selectedDayEntries.when(
                  data: (entries) {
                    if (entries.isEmpty) {
                      return Center(
                        child: Text(
                          'No entries',
                          style: TextStyle(color: grey, fontSize: 14),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: dividerColor,
                          indent: 24,
                          endIndent: 24),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return EntryCard(
                          id: entry.id.toString(),
                          title: entry.title,
                          content: entry.content,
                          dateTime: entry.entryDate,
                          isVoiceTranscribed: entry.isVoiceTranscribed,
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
