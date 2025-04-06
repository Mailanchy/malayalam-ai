import 'package:flutter_sound/flutter_sound.dart';

/// Plays a WAV file at [wavPath] using FlutterSoundPlayer.
Future<void> playWavFile(String wavPath) async {
  // Create and open a FlutterSoundPlayer instance.
  final FlutterSoundPlayer player = FlutterSoundPlayer();
  try {
    await player.openPlayer();
    await player.startPlayer(
      fromURI: wavPath,
      codec: Codec.pcm16WAV,
      whenFinished: () async {
        // Close the player when playback is finished.
        await player.closePlayer();
      },
    );
  } catch (e) {
    print("Error playing WAV file: $e");
    // Ensure the player is closed in case of an error.
    await player.closePlayer();
  }
}
