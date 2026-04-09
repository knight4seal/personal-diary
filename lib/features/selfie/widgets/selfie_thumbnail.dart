import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:personal_diary/services/selfie_service.dart';
import 'webcam_capture_dialog.dart';

/// A subtle circular selfie thumbnail shown in the daily view.
/// - If no selfie for the date: shows a faint dotted circle with a tiny camera icon
/// - If selfie exists: shows the photo in a small circle
/// - Tap to take/replace selfie (webcam on web, front camera on native)
class SelfieThumbnail extends StatefulWidget {
  final DateTime date;
  final double size;

  const SelfieThumbnail({
    super.key,
    required this.date,
    this.size = 36,
  });

  @override
  State<SelfieThumbnail> createState() => _SelfieThumbnailState();
}

class _SelfieThumbnailState extends State<SelfieThumbnail> {
  final SelfieService _selfieService = SelfieService();
  String? _selfiePath;
  // For web, store bytes directly since we can't use File paths
  List<int>? _selfieBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSelfie();
  }

  @override
  void didUpdateWidget(SelfieThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _loadSelfie();
    }
  }

  Future<void> _loadSelfie() async {
    setState(() => _loading = true);
    if (kIsWeb) {
      // On web, check if we have bytes stored in memory
      // (web selfies are session-only since we can't write to filesystem)
      if (mounted) {
        setState(() => _loading = false);
      }
    } else {
      final path = await _selfieService.getSelfie(widget.date);
      if (mounted) {
        setState(() {
          _selfiePath = path;
          _loading = false;
        });
      }
    }
  }

  Future<void> _takeSelfie() async {
    if (kIsWeb) {
      // Use browser webcam dialog
      final bytes = await showWebcamCaptureDialog(context);
      if (bytes != null && mounted) {
        setState(() => _selfieBytes = bytes);
        // On web we can't persist to filesystem, but bytes are kept in memory
        // For persistent web storage, would need IndexedDB
      }
    } else {
      // Native: use image_picker with front camera
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await _selfieService.saveSelfie(widget.date, bytes);
        _loadSelfie();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grey = Colors.grey;

    if (_loading) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    final hasSelfie = _selfiePath != null || _selfieBytes != null;

    return GestureDetector(
      onTap: _takeSelfie,
      child: hasSelfie
          ? Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: _selfieBytes != null
                    ? DecorationImage(
                        image: MemoryImage(
                            Uint8List.fromList(_selfieBytes!)),
                        fit: BoxFit.cover,
                      )
                    : DecorationImage(
                        image: FileImage(File(_selfiePath!)),
                        fit: BoxFit.cover,
                      ),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            )
          : Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: grey.withValues(alpha: 0.3),
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: widget.size * 0.4,
                color: grey.withValues(alpha: 0.3),
              ),
            ),
    );
  }
}
