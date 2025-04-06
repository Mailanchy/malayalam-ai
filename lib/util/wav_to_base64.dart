import 'dart:convert';
import 'dart:io';

/// Converts a WAV file at [wavPath] to a Base64 encoded string.
Future<String> convertWavToBase64(String wavPath) async {
  final file = File(wavPath);
  // Read the WAV file bytes.
  final bytes = await file.readAsBytes();
  // Convert bytes to a Base64 string.
  return base64Encode(bytes);
}
