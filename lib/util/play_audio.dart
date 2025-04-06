import 'package:flutter_sound/flutter_sound.dart';

/// Plays a WAV file at [wavPath] using FlutterSoundPlayer.
/// Optional callbacks:
/// [onStarted] is called when playback starts.
/// [onFinished] is called when playback ends.
Future<void> playWavFile(
    String wavPath, {
      void Function()? onStarted,
      void Function()? onFinished,
    }) async {
  final FlutterSoundPlayer player = FlutterSoundPlayer();

  try {
    await player.openPlayer();

    await player.startPlayer(
      fromURI: wavPath,
      codec: Codec.pcm16WAV,
      whenFinished: () async {
        if (onFinished != null) onFinished();
        await player.closePlayer();
      },
    );

    // Playback has started successfully
    if (onStarted != null) onStarted();

  } catch (e) {
    print("Error playing WAV file: $e");
    await player.closePlayer();
  }
}
