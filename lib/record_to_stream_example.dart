import 'dart:async';
import 'dart:io';
import 'package:example/audio_visual.dart';
import 'package:example/util/pcm_to_wav.dart';
import 'package:example/util/wav_to_base64.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

///
typedef _Fn = void Function();

/// Example app.
class RecordToStreamExample extends StatefulWidget {
  const RecordToStreamExample({super.key});

  @override
  State<RecordToStreamExample> createState() => _RecordToStreamExampleState();
}

class _RecordToStreamExampleState extends State<RecordToStreamExample> {
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  String? _mPath;
  StreamSubscription? _recorderSubscription;
  Codec codecSelected = Codec.pcmFloat32;

  bool _mplaybackReady = false;
  double _dbLevel = 0.0;
  StreamSubscription? _mRecordingDataSubscription;
  StreamController<List<int>> webStreamController = StreamController();

  @override
  void initState() {
    super.initState();
    setCodec(Codec.pcm16);
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
    _openRecorder();
  }

  @override
  void dispose() {
    stopPlayer();
    _mPlayer!.closePlayer();
    _mPlayer = null;

    stopRecorder();
    _mRecorder!.closeRecorder();
    _mRecorder = null;
    super.dispose();
  }

  Future<IOSink> createFile() async {
    var tempDir = await getTemporaryDirectory();
    _mPath = '${tempDir.path}/flutter_sound_example.pcm';
    var outputFile = File(_mPath!);
    if (outputFile.existsSync()) {
      await outputFile.delete();
    }
    return outputFile.openWrite();
  }

  // ----------------------  Here is the code to record to a Stream ------------

  static const int cstSAMPLERATE = 16000;
  static const int cstCHANNELNB = 1;

  /// We have finished with the recorder. Release the subscription
  Future<void> cancelRecorderSubscriptions() async {
    if (_recorderSubscription != null) {
      await _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }

    if (_mRecordingDataSubscription != null) {
      await _mRecordingDataSubscription!.cancel();
      _mRecordingDataSubscription = null;
    }
  }

  Future<void> _openRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _mRecorder!.openRecorder();

    _recorderSubscription = _mRecorder!.onProgress!.listen((e) {
      // pos = e.duration.inMilliseconds; // We do not need this information in this example.
      setState(() {
        _dbLevel = e.decibels as double;
      });
    });
    await _mRecorder!.setSubscriptionDuration(
        const Duration(milliseconds: 100)); // DO NOT FORGET THIS CALL !!!

    setState(() {
      _mRecorderIsInited = true;
    });

    setState(() {
      _mRecorderIsInited = true;
    });
  }

  Future<void> record() async {
    assert(_mRecorderIsInited && _mPlayer!.isStopped);
    StreamSink<List<int>>? sink;
    if (!kIsWeb) {
      sink = await createFile();
    } else {
      sink = webStreamController.sink;
    }

    var recordingDataController = StreamController<Uint8List>();
    _mRecordingDataSubscription =
        recordingDataController.stream.listen((buffer) {
      sink!.add(buffer);
    });
    await _mRecorder!.startRecorder(
      toStream: recordingDataController.sink,
      codec: codecSelected,
      numChannels: cstCHANNELNB,
      sampleRate: cstSAMPLERATE,
      bufferSize: 8192,
      audioSource: AudioSource.defaultSource,
    );
    setState(() {
      _dbLevel = 0.0;
    });
  }

  Future<void> stopRecorder() async {
    await _mRecorder!.stopRecorder();

    if (_mRecordingDataSubscription != null) {
      await _mRecordingDataSubscription!.cancel();
      _mRecordingDataSubscription = null;
    }

    if (_mPath != null) {
      String wavPath = await convertPcmToWav(_mPath!);
      String wavBase64Data = await convertWavToBase64(wavPath);
      print(wavBase64Data);
    }

    _mplaybackReady = true;
  }

  // --------------------- (it was very simple, wasn't it ?) -------------------

  _Fn? getRecorderFn() {
    if (!_mRecorderIsInited || !_mPlayer!.isStopped) {
      return null;
    }
    return _mRecorder!.isStopped
        ? record
        : () {
            stopRecorder().then((value) => setState(() {}));
          };
  }

  void play() async {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    await _mPlayer!.startPlayer(
        fromURI: _mPath,
        sampleRate: cstSAMPLERATE,
        codec: codecSelected,
        numChannels: cstCHANNELNB,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  Future<void> stopPlayer() async {
    await _mPlayer!.stopPlayer();
  }

  _Fn? getPlaybackFn() {
    if (!_mPlayerIsInited || !_mplaybackReady || !_mRecorder!.isStopped) {
      return null;
    }
    return _mPlayer!.isStopped
        ? play
        : () {
            stopPlayer().then((value) => setState(() {}));
          };
  }

  // ----------------------------------------------------------------------------------------------------------------------

  void setCodec(Codec? codec) {
    setState(() {
      codecSelected = codec!;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget makeBody() {
      return Column(children: [
        Column(children: [
          ElevatedButton(
            onPressed: getRecorderFn(),
            //color: Colors.white,
            //disabledColor: Colors.grey,
            child: Text(_mRecorder!.isRecording ? 'Stop' : 'Record'),
          ),
          IconButton(
            onPressed: getPlaybackFn(),
            //color: Colors.white,
            //disabledColor: Colors.grey,
            icon: _mPlayer!.isPlaying
                ? const Icon(Icons.pause)
                : const Icon(Icons.play_arrow),
          ),
        ]),
      ]);
    }

    // return Scaffold(
    //   body: makeBody(),
    // );

    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen background image
          SizedBox.expand(
            child: Image.asset(
              'assets/image.png',
              fit: BoxFit.cover,
            ),
          ),

          Center(
            child: IconButton(
              onPressed: getPlaybackFn(),
              //color: Colors.white,
              //disabledColor: Colors.grey,
              icon: _mPlayer!.isPlaying
                  ? const Icon(Icons.pause)
                  : const Icon(Icons.play_arrow),
            ),
          ),

          // Mic button
          // Inside Stack children
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_mRecorder!.isRecording)
                    AudioVisual(waveLeft: true, volume: _dbLevel),

                  // Mic button in center
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: _mRecorder!.isRecording
                              ? Colors.white.withOpacity(0.7)
                              : Colors.blueAccent.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _mRecorder!.isRecording ? Icons.mic_off : Icons.mic,
                        size: 36,
                        color: Colors.white,
                      ),
                      onPressed: getRecorderFn(),
                    ),
                  ),

                  if (_mRecorder!.isRecording)
                    AudioVisual(waveLeft: false, volume: _dbLevel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
