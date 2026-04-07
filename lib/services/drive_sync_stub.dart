/// Stub implementation for web platform where dart:io is unavailable.

String? findGoogleDriveFolder() => null;

Future<void> writeBackupFile(String driveFolder, String content) async {}

Future<String?> readBackupFile(String driveFolder) async => null;

DateTime? getBackupModifiedTime(String driveFolder) => null;
