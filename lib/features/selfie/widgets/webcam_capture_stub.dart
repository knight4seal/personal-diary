import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Stub for non-web platforms — webcam dialog is not used (image_picker handles it).
Future<Uint8List?> showWebcamCaptureDialog(BuildContext context) async {
  return null;
}
