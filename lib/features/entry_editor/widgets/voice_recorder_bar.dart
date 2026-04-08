import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceRecorderBar extends StatefulWidget {
  /// Called with (title, body, audioFilePath).
  /// Speak the title, pause 3 seconds, then speak the body.
  final void Function(String? title, String body, String? audioFilePath)
      onTranscriptionComplete;

  const VoiceRecorderBar({
    super.key,
    required this.onTranscriptionComplete,
  });

  @override
  State<VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

enum RecorderState { idle, recording, transcribing }

enum _CapturePhase { title, pauseDetected, body }

class _VoiceRecorderBarState extends State<VoiceRecorderBar> {
  RecorderState _state = RecorderState.idle;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  final AudioRecorder _recorder = AudioRecorder();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;

  // Language: 'en-US' for English, 'ko-KR' for Korean
  String _selectedLocale = 'en-US';

  // Title/body splitting via 3-second pause
  _CapturePhase _phase = _CapturePhase.title;
  String _titleText = '';
  String _bodyText = '';
  String _currentWords = '';
  Timer? _pauseTimer;
  DateTime? _lastWordTime;

  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pauseTimer?.cancel();
    _recorder.dispose();
    _speech.stop();
    super.dispose();
  }

  void _onSpeechResult(dynamic result) {
    final words = result.recognizedWords.trim();
    if (words.isEmpty) return;

    _lastWordTime = DateTime.now();

    setState(() {
      _currentWords = words;

      if (_phase == _CapturePhase.title) {
        _titleText = words;
      } else if (_phase == _CapturePhase.body) {
        // In body phase, the recognizer gives us cumulative text.
        // Body text = everything after the title portion.
        if (words.length > _titleText.length) {
          _bodyText = words.substring(_titleText.length).trim();
        } else {
          _bodyText = words;
        }
      }
    });

    // Reset the pause detection timer
    _pauseTimer?.cancel();
    if (_phase == _CapturePhase.title) {
      _pauseTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _phase == _CapturePhase.title && _titleText.isNotEmpty) {
          setState(() {
            _phase = _CapturePhase.pauseDetected;
          });
          // Brief visual feedback, then switch to body phase
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _phase = _CapturePhase.body;
              });
            }
          });
        }
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        debugPrint('Microphone permission denied');
        return;
      }

      _titleText = '';
      _bodyText = '';
      _currentWords = '';
      _phase = _CapturePhase.title;
      _audioPath = null;
      _lastWordTime = null;

      if (_speechAvailable) {
        await _speech.listen(
          onResult: _onSpeechResult,
          listenMode: stt.ListenMode.dictation,
          localeId: _selectedLocale,
          cancelOnError: false,
          partialResults: true,
        );
      }

      setState(() {
        _state = RecorderState.recording;
        _elapsed = Duration.zero;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
      });
    } catch (e) {
      debugPrint('Recording error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;
    _pauseTimer?.cancel();
    _pauseTimer = null;

    setState(() => _state = RecorderState.transcribing);

    try {
      try { await _recorder.stop(); } catch (_) {}
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 500));

      final title = _ensurePunctuation(_titleText.trim());
      final body = _ensurePunctuation(_bodyText.trim());
      final path = kIsWeb ? null : _audioPath;

      if (title.isEmpty && body.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No speech detected. Try again.')),
          );
        }
      } else if (_phase == _CapturePhase.title) {
        // Never paused — all text goes to body, no title
        widget.onTranscriptionComplete(null, title, path);
      } else {
        // Paused — title and body are separated
        widget.onTranscriptionComplete(
          title.isNotEmpty ? title : null,
          body.isNotEmpty ? body : title,
          path,
        );
      }
    } catch (e) {
      debugPrint('Stop recording error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _state = RecorderState.idle;
          _elapsed = Duration.zero;
          _phase = _CapturePhase.title;
        });
      }
    }
  }

  /// Converts spoken punctuation commands into actual punctuation marks,
  /// capitalizes after periods, and ensures text ends with a period.
  /// Supports both English and Korean spoken commands.
  String _ensurePunctuation(String text) {
    if (text.isEmpty) return text;

    var result = text;

    // English spoken punctuation
    result = result.replaceAllMapped(
      RegExp(r'\s+period\b', caseSensitive: false), (m) => '.');
    result = result.replaceAllMapped(
      RegExp(r'\s+full stop\b', caseSensitive: false), (m) => '.');
    result = result.replaceAllMapped(
      RegExp(r'\s+comma\b', caseSensitive: false), (m) => ',');
    result = result.replaceAllMapped(
      RegExp(r'\s+question mark\b', caseSensitive: false), (m) => '?');
    result = result.replaceAllMapped(
      RegExp(r'\s+exclamation mark\b', caseSensitive: false), (m) => '!');
    result = result.replaceAllMapped(
      RegExp(r'\s+exclamation point\b', caseSensitive: false), (m) => '!');
    result = result.replaceAllMapped(
      RegExp(r'\s+new line\b', caseSensitive: false), (m) => '\n');
    result = result.replaceAllMapped(
      RegExp(r'\s+new paragraph\b', caseSensitive: false), (m) => '\n\n');
    result = result.replaceAllMapped(
      RegExp(r'^period\b', caseSensitive: false), (m) => '.');

    // Korean spoken punctuation (마침표=period, 쉼표=comma, 물음표=?, 느낌표=!)
    result = result.replaceAll(' 마침표', '.');
    result = result.replaceAll(' 점', '.');
    result = result.replaceAll(' 쉼표', ',');
    result = result.replaceAll(' 물음표', '?');
    result = result.replaceAll(' 느낌표', '!');
    result = result.replaceAll(' 줄바꿈', '\n');
    result = result.replaceAll(' 새 줄', '\n');
    result = result.replaceAll(' 새 문단', '\n\n');
    // Handle at start of text
    if (result.startsWith('마침표')) result = '.${result.substring(3)}';
    if (result.startsWith('점')) result = '.${result.substring(1)}';

    // Capitalize first letter (only for Latin characters)
    result = result.trim();
    if (result.isNotEmpty && RegExp(r'[a-z]').hasMatch(result[0])) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    // Capitalize letter after each period/question/exclamation (Latin only)
    result = result.replaceAllMapped(
      RegExp(r'([.!?])\s+([a-z])'),
      (m) => '${m.group(1)} ${m.group(2)!.toUpperCase()}',
    );

    // If text doesn't end with punctuation, add a period
    if (result.isNotEmpty) {
      final lastChar = result[result.length - 1];
      if (lastChar != '.' && lastChar != '!' && lastChar != '?' && lastChar != ',') {
        result = '$result.';
      }
    }

    return result;
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _phaseLabel {
    final isKorean = _selectedLocale == 'ko-KR';
    switch (_phase) {
      case _CapturePhase.title:
        return isKorean ? '제목 말하는 중...' : 'Speaking title...';
      case _CapturePhase.pauseDetected:
        return isKorean ? '제목 저장됨! 이제 본문을 말하세요...' : 'Title captured! Now speak body...';
      case _CapturePhase.body:
        return isKorean ? '본문 말하는 중...' : 'Speaking body...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;
    final grey = Colors.grey;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live preview during recording
            if (_state == RecorderState.recording) ...[
              // Phase indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  _phaseLabel,
                  style: TextStyle(
                    color: _phase == _CapturePhase.pauseDetected
                        ? fg
                        : grey,
                    fontSize: 11,
                    fontWeight: _phase == _CapturePhase.pauseDetected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              // Title preview
              if (_titleText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title: ',
                        style: TextStyle(
                          color: grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _titleText,
                          style: TextStyle(
                            color: fg,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              // Body preview
              if (_bodyText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Body: ',
                        style: TextStyle(
                          color: grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _bodyText,
                          style: TextStyle(
                            color: grey,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
            ],
            // Hint when idle
            if (_state == RecorderState.idle) ...[
              // Language toggle
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _selectedLocale = 'en-US'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedLocale == 'en-US' ? fg : grey,
                            width: _selectedLocale == 'en-US' ? 1.5 : 0.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'EN',
                          style: TextStyle(
                            color: _selectedLocale == 'en-US' ? fg : grey,
                            fontSize: 12,
                            fontWeight: _selectedLocale == 'en-US'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _selectedLocale = 'ko-KR'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedLocale == 'ko-KR' ? fg : grey,
                            width: _selectedLocale == 'ko-KR' ? 1.5 : 0.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '한국어',
                          style: TextStyle(
                            color: _selectedLocale == 'ko-KR' ? fg : grey,
                            fontSize: 12,
                            fontWeight: _selectedLocale == 'ko-KR'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _selectedLocale == 'ko-KR'
                      ? '제목 말하기 → 3초 멈춤 → 본문 말하기'
                      : 'Say title → pause 3s → say body',
                  style: TextStyle(color: grey, fontSize: 11),
                ),
              ),
            ],
            _buildControls(fg, grey),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(Color fg, Color grey) {
    switch (_state) {
      case RecorderState.idle:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _startRecording,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic_none, color: fg, size: 20),
                  const SizedBox(width: 8),
                  Text('Record', style: TextStyle(color: fg, fontSize: 14)),
                ],
              ),
            ),
          ],
        );

      case RecorderState.recording:
        return Row(
          children: [
            ...List.generate(5, (i) {
              final heights = [8.0, 14.0, 20.0, 12.0, 16.0];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 3,
                  height: heights[i],
                  decoration: BoxDecoration(
                    color: fg,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              );
            }),
            const SizedBox(width: 12),
            Text(
              _formatDuration(_elapsed),
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _stopRecording,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: fg,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Stop', style: TextStyle(color: fg, fontSize: 14)),
                ],
              ),
            ),
          ],
        );

      case RecorderState.transcribing:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: grey),
            ),
            const SizedBox(width: 12),
            Text(
              'Transcribing...',
              style: TextStyle(color: grey, fontSize: 14),
            ),
          ],
        );
    }
  }
}
