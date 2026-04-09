import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Opens a dialog with a live webcam feed and a capture button.
/// Returns the captured JPEG bytes, or null if cancelled.
Future<Uint8List?> showWebcamCaptureDialog(BuildContext context) async {
  return showDialog<Uint8List?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _WebcamDialog(),
  );
}

class _WebcamDialog extends StatefulWidget {
  const _WebcamDialog();

  @override
  State<_WebcamDialog> createState() => _WebcamDialogState();
}

class _WebcamDialogState extends State<_WebcamDialog> {
  web.MediaStream? _stream;
  String? _error;
  bool _captured = false;
  String _viewType = 'webcam-preview-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      final constraints = web.MediaStreamConstraints(
        video: true.toJS,
        audio: false.toJS,
      );

      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;

      _stream = stream;

      // Create video element
      final video = web.document.createElement('video') as web.HTMLVideoElement;
      video.srcObject = stream;
      video.setAttribute('autoplay', '');
      video.setAttribute('playsinline', '');
      video.style.width = '100%';
      video.style.height = '100%';
      video.style.objectFit = 'cover';
      video.style.transform = 'scaleX(-1)'; // Mirror for selfie

      // Register platform view for web
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int id) => video,
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Camera access denied or unavailable');
      }
    }
  }

  Future<void> _capture() async {
    try {
      // Get the video element
      final videos = web.document.querySelectorAll('video');
      web.HTMLVideoElement? video;
      for (int i = 0; i < videos.length; i++) {
        final el = videos.item(i);
        if (el is web.HTMLVideoElement && el.srcObject != null) {
          video = el;
          break;
        }
      }

      if (video == null) {
        // Fallback: capture from stream tracks
        if (_stream != null) {
          final tracks = _stream!.getVideoTracks();
          if (tracks.length > 0) {
            // Use canvas to capture
            final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
            canvas.width = 512;
            canvas.height = 512;
            final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;

            // Draw from video
            final tempVideo = web.document.createElement('video') as web.HTMLVideoElement;
            tempVideo.srcObject = _stream;
            await tempVideo.play().toDart;
            await Future.delayed(const Duration(milliseconds: 100));
            ctx.drawImage(tempVideo, 0, 0, 512, 512);
            tempVideo.pause();

            final dataUrl = canvas.toDataURL('image/jpeg', 0.85.toJS);
            final bytes = _dataUrlToBytes(dataUrl);
            _stopCamera();
            if (mounted) Navigator.pop(context, bytes);
            return;
          }
        }
        if (mounted) setState(() => _error = 'Could not capture image');
        return;
      }

      final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
      canvas.width = 512;
      canvas.height = 512;
      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;

      // Mirror the capture to match the preview
      ctx.translate(512, 0);
      ctx.scale(-1, 1);
      ctx.drawImage(video, 0, 0, 512, 512);

      final dataUrl = canvas.toDataURL('image/jpeg', 0.85.toJS);
      final bytes = _dataUrlToBytes(dataUrl);

      _stopCamera();
      if (mounted) Navigator.pop(context, bytes);
    } catch (e) {
      if (mounted) setState(() => _error = 'Capture failed: $e');
    }
  }

  Uint8List _dataUrlToBytes(String dataUrl) {
    final base64 = dataUrl.split(',').last;
    return Uint8List.fromList(
      web.window.atob(base64).codeUnits.map((c) => c).toList(),
    );
  }

  void _stopCamera() {
    if (_stream != null) {
      final tracks = _stream!.getTracks();
      for (int i = 0; i < tracks.length; i++) {
        tracks[i].stop();
      }
      _stream = null;
    }
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;
    final grey = Colors.grey;

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 340,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Take Selfie',
                    style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _stopCamera();
                      Navigator.pop(context, null);
                    },
                    child: Icon(Icons.close, color: grey, size: 20),
                  ),
                ],
              ),
            ),
            // Camera preview — flexible to fit available space
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _error!,
                  style: TextStyle(color: grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _stream != null
                        ? HtmlElementView(viewType: _viewType)
                        : Center(
                            child: CircularProgressIndicator(
                              color: fg,
                              strokeWidth: 1,
                            ),
                          ),
                  ),
                ),
              ),
            // Capture button
            if (_error == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: fg, width: 3),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fg,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
