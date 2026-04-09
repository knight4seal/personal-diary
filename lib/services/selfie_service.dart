import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Manages daily selfie photos stored locally.
/// Photos are saved as `selfies/YYYY-MM-DD.jpg` in the app documents directory.
class SelfieService {
  static const _selfieDir = 'selfies';

  /// Returns the path for today's (or a specific date's) selfie.
  Future<String> _selfiePathForDate(DateTime date) async {
    if (kIsWeb) return '';
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, _selfieDir));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return p.join(dir.path, '$dateStr.jpg');
  }

  /// Check if a selfie exists for a given date.
  Future<bool> hasSelfie(DateTime date) async {
    if (kIsWeb) return false;
    final path = await _selfiePathForDate(date);
    return File(path).existsSync();
  }

  /// Get the file path of a selfie for a date (null if doesn't exist).
  Future<String?> getSelfie(DateTime date) async {
    if (kIsWeb) return null;
    final path = await _selfiePathForDate(date);
    if (File(path).existsSync()) return path;
    return null;
  }

  /// Save selfie bytes for a given date. Returns the saved path.
  Future<String?> saveSelfie(DateTime date, List<int> imageBytes) async {
    if (kIsWeb) return null;
    final path = await _selfiePathForDate(date);
    await File(path).writeAsBytes(imageBytes);
    return path;
  }

  /// Delete selfie for a given date.
  Future<void> deleteSelfie(DateTime date) async {
    if (kIsWeb) return;
    final path = await _selfiePathForDate(date);
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Get all selfie dates (sorted newest first).
  Future<List<DateTime>> getAllSelfieDates() async {
    if (kIsWeb) return [];
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, _selfieDir));
    if (!dir.existsSync()) return [];

    final dates = <DateTime>[];
    for (final entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith('.jpg')) {
        final name = p.basenameWithoutExtension(entity.path);
        try {
          final parts = name.split('-');
          if (parts.length == 3) {
            dates.add(DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            ));
          }
        } catch (_) {}
      }
    }
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  /// Get count of all selfies.
  Future<int> getSelfieCount() async {
    final dates = await getAllSelfieDates();
    return dates.length;
  }
}
