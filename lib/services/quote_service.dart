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

  // Korean quotes — translated wisdom from world thinkers (no folklore/proverbs)
  static const List<Quote> _koreanQuotes = [
    Quote(text: '상처는 빛이 들어오는 곳이다.', author: '루미'),
    Quote(text: '당신이 찾는 것이 당신을 찾고 있다.', author: '루미'),
    Quote(text: '자신을 놓아버리면 될 수 있는 사람이 된다.', author: '루미'),
    Quote(text: '진정으로 사랑하는 것에 조용히 이끌려라.', author: '루미'),
    Quote(text: '어제 나는 똑똒했다. 그래서 세상을 바꾸려 했다. 오늘 나는 지혜롭다. 그래서 나를 바꾸고 있다.', author: '루미'),
    Quote(text: '천 리 길도 한 걸음부터 시작된다.', author: '노자'),
    Quote(text: '자연은 서두르지 않지만 모든 것을 이룬다.', author: '노자'),
    Quote(text: '침묵은 큰 힘의 원천이다.', author: '노자'),
    Quote(text: '남을 아는 것은 지혜이고, 자신을 아는 것은 깨달음이다.', author: '노자'),
    Quote(text: '행복은 만들어진 것이 아니다. 자신의 행동에서 온다.', author: '달라이 라마'),
    Quote(text: '우리가 생각하는 대로 우리는 된다.', author: '부처'),
    Quote(text: '성찰하지 않는 삶은 살 가치가 없다.', author: '소크라테스'),
    Quote(text: '어려움 속에 기회가 있다.', author: '알베르트 아인슈타인'),
    Quote(text: '위대한 일을 하는 유일한 방법은 하는 일을 사랑하는 것이다.', author: '스티브 잡스'),
    Quote(text: '세상에서 보고 싶은 변화가 되어라.', author: '마하트마 간디'),
    Quote(text: '자기 자신을 아는 것이 모든 지혜의 시작이다.', author: '아리스토텔레스'),
    Quote(text: '가장 어두운 순간에 빛을 볼 수 있도록 집중해야 한다.', author: '아리스토텔레스'),
    Quote(text: '나는 실패한 적이 없다. 안 되는 방법을 만 가지 찾았을 뿐이다.', author: '토마스 에디슨'),
    Quote(text: '꿈에 머물러 사는 것을 잊지 마라.', author: 'J.K. 롤링'),
    Quote(text: '나무를 심기 가장 좋은 때는 20년 전이었다. 두 번째로 좋은 때는 지금이다.', author: '중국 격언'),
    Quote(text: '매일 조금씩 나아지면 결국 큰 변화가 온다.', author: '존 우든'),
    Quote(text: '삶이 있는 한 희망은 있다.', author: '키케로'),
    Quote(text: '오직 나 자신만이 내 인생을 바꿀 수 있다.', author: '캐롤 버넷'),
    Quote(text: '작은 기회로부터 종종 위대한 업적이 시작된다.', author: '데모스테네스'),
    // Korean authors
    Quote(text: '나의 소원은 대한의 완전한 자주독립이오.', author: '김구'),
    Quote(text: '죽는 날까지 하늘을 우러러 한 점 부끄럼이 없기를.', author: '윤동주'),
    Quote(text: '님은 갔습니다. 아아, 사랑하는 나의 님은 갔습니다.', author: '한용운'),
    Quote(text: '나 보기가 역겨워 가실 때에는 죽어도 아니 눈물 흘리오리다.', author: '김소월'),
    Quote(text: '모든 인간은 자기 운명의 건축가이다.', author: '정주영'),
    Quote(text: '해보기나 했어? 해보고 나서 안 된다고 해라.', author: '정주영'),
    Quote(text: '이 세상에서 가장 아름다운 것은 마음이 고운 것이다.', author: '법정 스님'),
    Quote(text: '무소유란 아무것도 갖지 않는 것이 아니라 불필요한 것을 갖지 않는 것이다.', author: '법정 스님'),
    Quote(text: '오늘 내가 흘린 땀은 내일의 나를 만든다.', author: '이순신'),
    Quote(text: '사람이 먼저다.', author: '노무현'),
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
