import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Converts a Base64 encoded WAV string to a WAV file in the temporary directory.
/// Returns the full path of the saved WAV file.
Future<String> convertBase64ToWav(String base64String) async {
  // Decode the Base64 string to bytes.
  final bytes = base64Decode(base64String);

  // Get the temporary directory.
  final tempDir = await getTemporaryDirectory();

  // Define the path for the output WAV file.
  final wavPath = '${tempDir.path}/output.wav';

  // Write the decoded bytes to the file.
  final file = File(wavPath);
  await file.writeAsBytes(bytes);

  // Return the path to the saved file.
  return wavPath;
}
