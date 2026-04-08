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
    Quote(text: 'The wound is the place where the light enters you.', author: 'Rumi'),
    Quote(text: 'Knowing yourself is the beginning of all wisdom.', author: 'Aristotle'),
    Quote(text: 'Turn your wounds into wisdom.', author: 'Oprah Winfrey'),
    Quote(text: 'It does not do to dwell on dreams and forget to live.', author: 'J.K. Rowling'),
    Quote(text: 'The best time to plant a tree was 20 years ago. The second best time is now.', author: 'Chinese Proverb'),
    Quote(text: 'What you seek is seeking you.', author: 'Rumi'),
    Quote(text: 'Happiness is not something ready-made. It comes from your own actions.', author: 'Dalai Lama'),
    Quote(text: 'We are what we repeatedly do. Excellence, then, is not an act, but a habit.', author: 'Aristotle'),
    Quote(text: 'I have not failed. I\'ve just found 10,000 ways that won\'t work.', author: 'Thomas Edison'),
    Quote(text: 'The journey of a thousand miles begins with a single step.', author: 'Lao Tzu'),
    Quote(text: 'When you let go of who you are, you become who you might be.', author: 'Rumi'),
    Quote(text: 'Nature does not hurry, yet everything is accomplished.', author: 'Lao Tzu'),
    Quote(text: 'It is during our darkest moments that we must focus to see the light.', author: 'Aristotle'),
    Quote(text: 'Yesterday I was clever, so I wanted to change the world. Today I am wise, so I am changing myself.', author: 'Rumi'),
    Quote(text: 'Silence is a source of great strength.', author: 'Lao Tzu'),
    Quote(text: 'Let yourself be silently drawn by the strange pull of what you really love.', author: 'Rumi'),
    Quote(text: 'He who knows others is wise. He who knows himself is enlightened.', author: 'Lao Tzu'),
  ];

  // Korean quotes — alternates with English quotes (odd days = English, even days = Korean)
  static const List<Quote> _koreanQuotes = [
    Quote(text: '천 리 길도 한 걸음부터.', author: '한국 속담'),
    Quote(text: '고생 끝에 낙이 온다.', author: '한국 속담'),
    Quote(text: '낙숫물이 돌을 뚫는다.', author: '한국 속담'),
    Quote(text: '시작이 반이다.', author: '한국 속담'),
    Quote(text: '호랑이도 제 말 하면 온다.', author: '한국 속담'),
    Quote(text: '가는 말이 고와야 오는 말이 곱다.', author: '한국 속담'),
    Quote(text: '콩 심은 데 콩 나고 팥 심은 데 팥 난다.', author: '한국 속담'),
    Quote(text: '뜻이 있는 곳에 길이 있다.', author: '한국 속담'),
    Quote(text: '백문이 불여일견.', author: '한국 속담'),
    Quote(text: '세 살 버릇 여든까지 간다.', author: '한국 속담'),
    Quote(text: '아는 것이 힘이다.', author: '한국 속담'),
    Quote(text: '배움에는 끝이 없다.', author: '한국 속담'),
    Quote(text: '오늘 걷지 않으면 내일은 뛰어야 한다.', author: '한국 속담'),
    Quote(text: '꿈을 꾸지 않으면 이룰 수도 없다.', author: '한국 속담'),
    Quote(text: '지혜는 경험에서 나온다.', author: '한국 속담'),
    Quote(text: '참을 인 자 셋이면 살인도 면한다.', author: '한국 속담'),
    Quote(text: '하늘은 스스로 돕는 자를 돕는다.', author: '한국 속담'),
    Quote(text: '말 한마디에 천 냥 빚을 갚는다.', author: '한국 속담'),
    Quote(text: '바다를 메우려면 돌부터 던져라.', author: '한국 속담'),
    Quote(text: '행복은 습관이다. 그것을 몸에 지녀라.', author: '허버드'),
    Quote(text: '삶이 있는 한 희망은 있다.', author: '키케로'),
    Quote(text: '오직 나 자신만이 내 인생을 바꿀 수 있다.', author: '캐롤 버넷'),
    Quote(text: '작은 기회로부터 종종 위대한 업적이 시작된다.', author: '데모스테네스'),
    Quote(text: '매일 조금씩 나아지면 결국 큰 변화가 온다.', author: '존 우든'),
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
    // Alternate: odd days = English, even days = Korean
    if (dayOfYear % 2 == 0) {
      return _koreanQuotes[dayOfYear ~/ 2 % _koreanQuotes.length];
    } else {
      return _fallbackQuotes[dayOfYear ~/ 2 % _fallbackQuotes.length];
    }
  }
}
