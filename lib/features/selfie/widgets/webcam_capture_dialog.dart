import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// Web-specific imports handled via conditional
import 'webcam_capture_stub.dart'
    if (dart.library.js_interop) 'webcam_capture_web.dart' as webcam;

/// Dialog that opens the webcam, shows a live preview, and lets the user
/// take a selfie snapshot. Returns the captured image bytes or null.
Future<Uint8List?> showWebcamCaptureDialog(BuildContext context) async {
  return webcam.showWebcamCaptureDialog(context);
}
