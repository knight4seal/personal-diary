import 'dart:io';

const _backupRelativePath = 'Diary/diary_backup.json';

/// Searches common Google Drive mount points on macOS (and other desktops).
String? findGoogleDriveFolder() {
  final home = Platform.environment['HOME'];
  if (home == null) return null;

  // macOS Google Drive desktop client (most common location)
  final cloudStorageDir = Directory('$home/Library/CloudStorage');
  if (cloudStorageDir.existsSync()) {
    try {
      for (final entity in cloudStorageDir.listSync()) {
        if (entity is Directory) {
          final name = entity.path.split('/').last;
          if (name.startsWith('GoogleDrive')) {
            // Look for "My Drive" subfolder
            final myDrive = Directory('${entity.path}/My Drive');
            if (myDrive.existsSync()) return myDrive.path;
            // Some setups put files directly in the folder
            return entity.path;
          }
        }
      }
    } catch (_) {}
  }

  // Fallback paths
  final fallbacks = [
    '$home/Google Drive/My Drive',
    '$home/Google Drive',
    '$home/GoogleDrive',
  ];

  for (final path in fallbacks) {
    if (Directory(path).existsSync()) return path;
  }

  return null;
}

/// Writes the encoded backup data to the Diary subfolder in Google Drive.
Future<void> writeBackupFile(String driveFolder, String content) async {
  final diaryDir = Directory('$driveFolder/Diary');
  if (!diaryDir.existsSync()) {
    diaryDir.createSync(recursive: true);
  }
  final file = File('$driveFolder/$_backupRelativePath');
  await file.writeAsString(content);
}

/// Reads the backup file from Google Drive. Returns null if it doesn't exist.
Future<String?> readBackupFile(String driveFolder) async {
  final file = File('$driveFolder/$_backupRelativePath');
  if (!file.existsSync()) return null;
  return file.readAsString();
}

/// Returns the last modified time of the backup file, or null.
DateTime? getBackupModifiedTime(String driveFolder) {
  final file = File('$driveFolder/$_backupRelativePath');
  if (!file.existsSync()) return null;
  return file.lastModifiedSync();
}
