import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_diary/features/auth/providers/auth_provider.dart';
import 'package:personal_diary/features/settings/providers/settings_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final List<int> _pin = [];
  String? _error;
  bool _isAuthenticating = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Map keyboard keys to PIN digits
  static final _keyToDigit = {
    LogicalKeyboardKey.digit0: 0,
    LogicalKeyboardKey.digit1: 1,
    LogicalKeyboardKey.digit2: 2,
    LogicalKeyboardKey.digit3: 3,
    LogicalKeyboardKey.digit4: 4,
    LogicalKeyboardKey.digit5: 5,
    LogicalKeyboardKey.digit6: 6,
    LogicalKeyboardKey.digit7: 7,
    LogicalKeyboardKey.digit8: 8,
    LogicalKeyboardKey.digit9: 9,
    LogicalKeyboardKey.numpad0: 0,
    LogicalKeyboardKey.numpad1: 1,
    LogicalKeyboardKey.numpad2: 2,
    LogicalKeyboardKey.numpad3: 3,
    LogicalKeyboardKey.numpad4: 4,
    LogicalKeyboardKey.numpad5: 5,
    LogicalKeyboardKey.numpad6: 6,
    LogicalKeyboardKey.numpad7: 7,
    LogicalKeyboardKey.numpad8: 8,
    LogicalKeyboardKey.numpad9: 9,
  };

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Number keys
    final digit = _keyToDigit[event.logicalKey];
    if (digit != null) {
      _onPinDigit(digit);
      return KeyEventResult.handled;
    }

    // Backspace/Delete
    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      _onPinDelete();
      return KeyEventResult.handled;
    }

    // Enter to unlock with biometrics
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _unlockWithBiometrics();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _unlockWithBiometrics() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final success = await ref.read(authProvider.notifier).checkBiometric();
      if (success && mounted) {
        context.go('/daily');
      } else if (mounted) {
        setState(() => _error = 'Authentication failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Authentication error');
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _onPinDigit(int digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin.add(digit);
      _error = null;
    });

    if (_pin.length == 4) {
      _submitPin();
    }
  }

  void _onPinDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin.removeLast();
      _error = null;
    });
  }

  Future<void> _submitPin() async {
    // Simple PIN unlock - unlock directly
    ref.read(authProvider.notifier).unlock();
    if (mounted) {
      context.go('/daily');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;
    final grey = Colors.grey;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round,
                color: fg),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Text(
                  'Diary',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 48,
                    fontWeight: FontWeight.normal,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 64),
                // PIN dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final filled = index < _pin.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? fg : Colors.transparent,
                          border: Border.all(color: fg, width: 1.5),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(color: grey, fontSize: 14),
                  ),
                const SizedBox(height: 32),
                // Number pad
                _buildNumberPad(fg, bg),
                const SizedBox(height: 32),
                // Biometrics button
                TextButton.icon(
                  onPressed: _isAuthenticating ? null : _unlockWithBiometrics,
                  icon: Icon(Icons.fingerprint, color: fg, size: 24),
                  label: Text(
                    'Unlock with Biometrics',
                    style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildNumberPad(Color fg, Color bg) {
    final rows = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
      [-1, 0, -2], // -1 = empty, -2 = delete
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((digit) {
              if (digit == -1) {
                return const SizedBox(width: 72, height: 56);
              }
              if (digit == -2) {
                return SizedBox(
                  width: 72,
                  height: 56,
                  child: TextButton(
                    onPressed: _onPinDelete,
                    child: Icon(Icons.backspace_outlined, color: fg, size: 20),
                  ),
                );
              }
              return SizedBox(
                width: 72,
                height: 56,
                child: TextButton(
                  onPressed: () => _onPinDigit(digit),
                  child: Text(
                    '$digit',
                    style: TextStyle(
                      color: fg,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
