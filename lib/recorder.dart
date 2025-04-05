import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  StreamController<double> volumeController = StreamController.broadcast();

  Future<void> init() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw RecordingPermissionException('Mic permission not granted');
    }
    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<void> startRecording() async {
    if (!_isRecorderInitialized) await init();

    await _recorder.startRecorder(
      codec: Codec.pcm16,
      sampleRate: 44100,
      bitRate: 16000, // 👈 important
      numChannels: 1,
      audioSource: AudioSource.microphone,
    );



    // Listen to audio stream level
    _recorder.onProgress!.listen((event) {
      final level = (event.decibels ?? (event.duration.inMilliseconds % 60)).toDouble();
      volumeController.add(level.abs()); // emit absolute value of loudness
    });
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
    volumeController.add(0); // reset to zero
  }

  void dispose() {
    _recorder.closeRecorder();
    volumeController.close();
  }

  bool get isRecording => _recorder.isRecording ?? false;
}
