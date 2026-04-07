import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Quote {
  final String text;
  final String author;

  const Quote({required this.text, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['q'] as String? ?? json['text'] as String? ?? '',
      author: json['a'] as String? ?? json['author'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() => {'text': text, 'author': author};
}

class QuoteService {
  static const _cacheKeyQuote = 'cached_quote';
  static const _cacheKeyDate = 'cached_quote_date';
  static const _apiUrl = 'https://zenquotes.io/api/today';

  static const List<Quote> _fallbackQuotes = [
    Quote(text: 'The unexamined life is not worth living.', author: 'Socrates'),
    Quote(text: 'In the middle of difficulty lies opportunity.', author: 'Albert Einstein'),
    Quote(text: 'To thine own self be true.', author: 'William Shakespeare'),
    Quote(text: 'The only way to do great work is to love what you do.', author: 'Steve Jobs'),
    Quote(text: 'Be the change that you wish to see in the world.', author: 'Mahatma Gandhi'),
    Quote(text: 'What we think, we become.', author: 'Buddha'),
    Quote(text: 'Faith is taking the first step even when you don\'t see the whole staircase.', author: 'Martin Luther King Jr.'),
    Quote(text: 'The Lord is my shepherd; I shall not want.', author: 'Psalm 23:1'),
    Quote(text: 'Knowing yourself is the beginning of all wisdom.', author: 'Aristotle'),
    Quote(text: 'Turn your wounds into wisdom.', author: 'Oprah Winfrey'),
    Quote(text: 'It does not do to dwell on dreams and forget to live.', author: 'J.K. Rowling'),
    Quote(text: 'The best time to plant a tree was 20 years ago. The second best time is now.', author: 'Chinese Proverb'),
    Quote(text: 'With God all things are possible.', author: 'Matthew 19:26'),
    Quote(text: 'Happiness is not something ready-made. It comes from your own actions.', author: 'Dalai Lama'),
    Quote(text: 'We are what we repeatedly do. Excellence, then, is not an act, but a habit.', author: 'Aristotle'),
    Quote(text: 'I have not failed. I\'ve just found 10,000 ways that won\'t work.', author: 'Thomas Edison'),
    Quote(text: 'The journey of a thousand miles begins with a single step.', author: 'Lao Tzu'),
    Quote(text: 'For I know the plans I have for you, declares the Lord.', author: 'Jeremiah 29:11'),
    Quote(text: 'You must be the change you wish to see in the world.', author: 'Mahatma Gandhi'),
    Quote(text: 'It is during our darkest moments that we must focus to see the light.', author: 'Aristotle'),
  ];

  final SharedPreferences _prefs;

  QuoteService(this._prefs);

  Future<Quote> getDailyQuote() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final cachedDate = _prefs.getString(_cacheKeyDate);

    if (cachedDate == today) {
      final cachedJson = _prefs.getString(_cacheKeyQuote);
      if (cachedJson != null) {
        return Quote.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
      }
    }

    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final quote = Quote.fromJson(data[0] as Map<String, dynamic>);
          await _prefs.setString(_cacheKeyQuote, jsonEncode(quote.toJson()));
          await _prefs.setString(_cacheKeyDate, today);
          return quote;
        }
      }
    } catch (_) {
      // Fall through to fallback quotes
    }

    return _getRandomFallbackQuote();
  }

  Quote _getRandomFallbackQuote() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _fallbackQuotes[dayOfYear % _fallbackQuotes.length];
  }
}
