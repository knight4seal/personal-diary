import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_diary/data/database/app_database.dart';
import 'package:personal_diary/features/entry_list/providers/entry_list_provider.dart';
import 'package:personal_diary/features/settings/providers/settings_provider.dart';

final searchEntriesProvider = FutureProvider.family<List<DiaryEntry>, String>((ref, query) {
  final repo = ref.watch(diaryRepositoryProvider);
  return repo.searchEntries(query);
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;
    final grey = Colors.grey;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    final searchResults = _query.isNotEmpty
        ? ref.watch(searchEntriesProvider(_query))
        : null;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: fg),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          style: TextStyle(color: fg, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search entries...',
            hintStyle: TextStyle(color: grey, fontSize: 16),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, color: grey, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
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
          child: _buildBody(searchResults, fg, bg, grey, dividerColor),
        ),
      ),
    );
  }

  Widget _buildBody(
    AsyncValue? searchResults,
    Color fg,
    Color bg,
    Color grey,
    Color dividerColor,
  ) {
    if (_query.isEmpty) {
      return Center(
        child: Text(
          'Search your diary',
          style: TextStyle(color: grey, fontSize: 16),
        ),
      );
    }

    if (searchResults == null) return const SizedBox.shrink();

    return searchResults.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Text(
              'No results for "$_query"',
              style: TextStyle(color: grey, fontSize: 16),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: results.length,
          separatorBuilder: (_, __) => Divider(
              height: 1, color: dividerColor, indent: 24, endIndent: 24),
          itemBuilder: (context, index) {
            final entry = results[index];
            return GestureDetector(
              onTap: () => context.push('/entry/${entry.id}'),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(entry.entryDate),
                      style: TextStyle(color: grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    if (entry.title != null && entry.title!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _buildHighlightedText(
                          entry.title!,
                          _query,
                          TextStyle(
                            color: fg,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          TextStyle(
                            color: fg,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    _buildHighlightedText(
                      entry.content.length > 200
                          ? '${entry.content.substring(0, 200)}...'
                          : entry.content,
                      _query,
                      TextStyle(color: fg, fontSize: 14, height: 1.4),
                      TextStyle(
                        color: fg,
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.bold,
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
        child: CircularProgressIndicator(color: fg, strokeWidth: 1),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: grey)),
      ),
    );
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle normalStyle,
    TextStyle highlightStyle,
  ) {
    if (query.isEmpty) return Text(text, style: normalStyle);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: normalStyle));
        break;
      }
      if (index > start) {
        spans.add(
            TextSpan(text: text.substring(start, index), style: normalStyle));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: highlightStyle,
      ));
      start = index + query.length;
    }

    return RichText(text: TextSpan(children: spans));
  }
}
