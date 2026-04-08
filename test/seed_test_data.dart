import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:personal_diary/data/database/app_database.dart';
import 'package:personal_diary/data/repositories/diary_repository.dart';

/// Generates 6 months of realistic diary test data.
/// Run with: dart test test/seed_test_data.dart
void main() async {
  final db = AppDatabase(NativeDatabase.memory());
  final repo = DiaryRepository(db);

  print('Generating 6 months of diary test data...\n');

  final entries = _generateEntries();
  int count = 0;

  for (final entry in entries) {
    await repo.createEntry(
      entryDate: entry.date,
      title: entry.title,
      content: entry.content,
      isVoiceTranscribed: entry.isVoice,
    );
    count++;
  }

  // Verify
  final allEntries =
      await db.select(db.diaryEntries).get();
  final months = <String>{};
  for (final e in allEntries) {
    months.add('${e.entryDate.year}-${e.entryDate.month.toString().padLeft(2, '0')}');
  }

  print('Done! Generated:');
  print('  $count entries');
  print('  ${months.length} months covered');
  print('  Date range: ${months.reduce((a, b) => a.compareTo(b) < 0 ? a : b)} '
      'to ${months.reduce((a, b) => a.compareTo(b) > 0 ? a : b)}');

  // Test queries
  print('\nRunning verification queries...');

  // Daily
  final today = DateTime(2026, 4, 7);
  final dailyEntries = await db.getEntriesForDate(today);
  print('  Daily (Apr 7): ${dailyEntries.length} entries');

  // Monthly counts
  final monthlyCounts = await repo.getEntryCountsByMonth(2026);
  print('  Monthly counts 2026: $monthlyCounts');

  // Search
  final searchResults = await repo.searchEntries('walk');
  print('  Search "walk": ${searchResults.length} results');

  // Export
  final json = await repo.exportToJson();
  print('  Export JSON: ${json.length} characters');

  // 72h edit check
  final firstEntry = allEntries.first;
  print('  First entry editable: ${repo.isEditable(firstEntry)}');

  print('\n✓ All verification queries passed.');

  await db.close();
}

List<_TestEntry> _generateEntries() {
  final entries = <_TestEntry>[];
  final now = DateTime(2026, 4, 8);

  // Generate entries from October 2025 to April 2026
  var date = DateTime(2025, 10, 1);
  while (date.isBefore(now)) {
    // Skip some days randomly (simulate not writing every day)
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final shouldWrite = (dayOfYear * 7 + 3) % 5 != 0; // ~80% of days

    if (shouldWrite) {
      // Morning entry
      final morningEntries = _morningEntries;
      final idx = dayOfYear % morningEntries.length;
      entries.add(_TestEntry(
        date: DateTime(date.year, date.month, date.day, 8, 30),
        title: morningEntries[idx].title,
        content: morningEntries[idx].content,
        isVoice: dayOfYear % 4 == 0, // 25% are voice transcribed
      ));

      // Some days have afternoon entries too
      if (dayOfYear % 3 == 0) {
        final afternoonEntries = _afternoonEntries;
        final aIdx = dayOfYear % afternoonEntries.length;
        entries.add(_TestEntry(
          date: DateTime(date.year, date.month, date.day, 15, 0),
          title: afternoonEntries[aIdx].title,
          content: afternoonEntries[aIdx].content,
          isVoice: dayOfYear % 6 == 0,
        ));
      }

      // Evening reflection on some days
      if (dayOfYear % 5 == 0) {
        final eveningEntries = _eveningEntries;
        final eIdx = dayOfYear % eveningEntries.length;
        entries.add(_TestEntry(
          date: DateTime(date.year, date.month, date.day, 21, 30),
          title: null, // Evening entries often have no title
          content: eveningEntries[eIdx],
          isVoice: false,
        ));
      }
    }

    date = date.add(const Duration(days: 1));
  }

  return entries;
}

class _TestEntry {
  final DateTime date;
  final String? title;
  final String content;
  final bool isVoice;

  _TestEntry({
    required this.date,
    this.title,
    required this.content,
    this.isVoice = false,
  });
}

class _TitleContent {
  final String? title;
  final String content;
  _TitleContent(this.title, this.content);
}

final _morningEntries = [
  _TitleContent('Morning Walk', 'Went for a walk by the river today. The air was crisp and fresh. Saw a family of ducks swimming near the bridge. Need to remember to call mom later about the weekend plans.'),
  _TitleContent('Early Start', 'Woke up before the alarm today. Made coffee and sat on the porch watching the sunrise. There is something deeply peaceful about those quiet moments before the world wakes up.'),
  _TitleContent('Rainy Morning', 'It rained all morning. Stayed inside and read a few chapters of the book I started last week. The sound of rain on the roof is incredibly soothing.'),
  _TitleContent('Gym Session', 'Hit the gym early. Did 30 minutes of cardio and some weight training. Feeling energized for the rest of the day. Need to keep this routine going.'),
  _TitleContent('Breakfast Ideas', 'Tried making overnight oats for the first time. Mixed oats with yogurt, honey, and blueberries. Left it in the fridge last night. It turned out surprisingly good.'),
  _TitleContent('Garden Time', 'Spent the morning in the garden. The tomatoes are starting to grow nicely. Planted some new herbs — basil and rosemary. The garden is becoming my favorite place to think.'),
  _TitleContent('Morning Meditation', 'Did a 20-minute guided meditation this morning. Focused on breathing and letting go of yesterday\'s stress. It really helps set the tone for the day.'),
  _TitleContent('Coffee Shop Visit', 'Went to the new coffee shop downtown. They have a great minimalist vibe — black and white interior, good music. Had a pour-over and journaled for an hour.'),
  _TitleContent('Weekend Plans', 'Planning a hike for this weekend. Looking at trails near the lake. Should be a good 3-hour hike with beautiful views at the summit.'),
  _TitleContent('Morning Reflection', 'Thinking about the conversation with Sarah yesterday. She made a good point about taking things one step at a time. I tend to overthink and plan too far ahead.'),
];

final _afternoonEntries = [
  _TitleContent('Work Update', 'Had a productive meeting with the team about the new project. Everyone seems excited about the direction we are heading. Need to prepare the presentation for Friday.'),
  _TitleContent('Lunch Break', 'Had lunch at the park. Brought a sandwich and an apple. Watched people walking their dogs. Sometimes the simplest moments are the most enjoyable.'),
  _TitleContent('Library Visit', 'Stopped by the library to return some books. Picked up two new ones — a biography and a novel. The library is such an underrated place.'),
  _TitleContent('Errands Done', 'Finally got all the errands done. Groceries, dry cleaning, and picked up the package from the post office. Feels good to check things off the list.'),
  _TitleContent('Phone Call', 'Had a long phone call with an old friend from college. We caught up on everything. It is amazing how some friendships never fade no matter how much time passes.'),
  _TitleContent('Cooking Experiment', 'Tried a new recipe for Thai curry. Used coconut milk, lemongrass, and fresh vegetables. It turned out really well. Will definitely make this again.'),
  _TitleContent('Afternoon Walk', 'Took a 30-minute walk after lunch. The weather was perfect — sunny with a light breeze. Noticed the cherry blossoms are starting to bloom.'),
];

final _eveningEntries = [
  'Today was a good day. Got a lot done at work and managed to squeeze in some exercise. Feeling grateful for the small wins.',
  'Quiet evening at home. Made tea, read a few pages, and went to bed early. Sometimes doing nothing is exactly what you need.',
  'Reflected on the past week. There were some challenges but also some really great moments. I am learning to appreciate the journey more than the destination.',
  'Watched the sunset from the balcony tonight. The sky turned orange, then pink, then deep purple. Nature puts on the best show.',
  'Feeling a bit tired today. Need to get more sleep this week. Going to set a reminder to wind down by 9 PM.',
  'Had a wonderful dinner with the family. We laughed, shared stories, and enjoyed each other\'s company. These are the moments that matter most.',
  'Thinking about goals for next month. Want to read more, exercise consistently, and spend less time on screens. Small steps, big changes.',
  'Today reminded me why I started this journal. Writing things down helps me process my thoughts and appreciate the little things in life.',
];
