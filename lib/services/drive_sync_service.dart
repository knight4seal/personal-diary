import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:personal_diary/data/repositories/diary_repository.dart';

import 'drive_sync_io.dart' if (dart.library.html) 'drive_sync_stub.dart'
    as platform;

class DriveSyncService {
  final DiaryRepository _repository;

  DriveSyncService(this._repository);

  /// Searches for a Google Drive sync folder on the local filesystem.
  /// Returns the path or null if not found.
  String? findGoogleDriveFolder() {
    if (kIsWeb) return null;
    return platform.findGoogleDriveFolder();
  }

  /// Exports diary data as JSON to Google Drive's local sync folder.
  /// Returns true on success, false on failure.
  Future<bool> exportToGoogleDrive() async {
    if (kIsWeb) return false;
    try {
      final driveFolder = findGoogleDriveFolder();
      if (driveFolder == null) return false;

      final jsonString = await _repository.exportToJson();
      final encoded = base64Encode(utf8.encode(jsonString));

      await platform.writeBackupFile(driveFolder, encoded);
      return true;
    } catch (e) {
      debugPrint('Drive sync export failed: $e');
      return false;
    }
  }

  /// Imports diary data from Google Drive's local sync folder.
  /// Returns the decoded JSON string, or null if the file doesn't exist.
  Future<String?> importFromGoogleDrive() async {
    if (kIsWeb) return null;
    try {
      final driveFolder = findGoogleDriveFolder();
      if (driveFolder == null) return null;

      final encoded = await platform.readBackupFile(driveFolder);
      if (encoded == null) return null;

      return utf8.decode(base64Decode(encoded.trim()));
    } catch (e) {
      debugPrint('Drive sync import failed: $e');
      return null;
    }
  }

  /// Returns the last modification time of the backup file, or null.
  Future<DateTime?> getLastSyncTime() async {
    if (kIsWeb) return null;
    try {
      final driveFolder = findGoogleDriveFolder();
      if (driveFolder == null) return null;
      return platform.getBackupModifiedTime(driveFolder);
    } catch (_) {
      return null;
    }
  }

  /// Convenience method: export to Google Drive (call on startup / after save).
  Future<void> autoSync() async {
    await exportToGoogleDrive();
  }

  void debugPrint(String message) {
    if (kIsWeb) return;
    // ignore: avoid_print
    print(message);
  }
}
