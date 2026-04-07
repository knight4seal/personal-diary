import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_diary/features/entry_list/providers/entry_list_provider.dart';
import 'package:personal_diary/features/entry_list/widgets/view_mode_selector.dart';
import 'package:personal_diary/features/settings/providers/settings_provider.dart';

class YearlyViewScreen extends ConsumerStatefulWidget {
  const YearlyViewScreen({super.key});

  @override
  ConsumerState<YearlyViewScreen> createState() => _YearlyViewScreenState();
}

class _YearlyViewScreenState extends ConsumerState<YearlyViewScreen> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  void _goToPreviousYear() {
    setState(() => _year--);
    ref.read(selectedDateProvider.notifier).state = DateTime(_year);
  }

  void _goToNextYear() {
    setState(() => _year++);
    ref.read(selectedDateProvider.notifier).state = DateTime(_year);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;
    final grey = Colors.grey;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    final yearlyStats = ref.watch(yearlyCountsProvider);

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
              onPressed: _goToPreviousYear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Text(
              '$_year',
              style: TextStyle(
                color: fg,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.chevron_right, color: fg, size: 20),
              onPressed: _goToNextYear,
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
                child: yearlyStats.when(
                  data: (monthlyCounts) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: 12,
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: dividerColor,
                          indent: 24,
                          endIndent: 24),
                      itemBuilder: (context, index) {
                        final monthDate = DateTime(_year, index + 1);
                        final monthName =
                            DateFormat('MMMM').format(monthDate);
                        final count = monthlyCounts[index + 1] ?? 0;

                        return GestureDetector(
                          onTap: () {
                            ref.read(viewModeProvider.notifier).state =
                                ViewMode.monthly;
                            context.go('/monthly', extra: monthDate);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 18),
                            child: Row(
                              children: [
                                Text(
                                  monthName,
                                  style: TextStyle(
                                    color: fg,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  count > 0 ? '$count' : '—',
                                  style: TextStyle(
                                    color: count > 0 ? fg : grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }
}
