import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'recorder.dart';
import 'audio_visual.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FullScreenImage(),
    );
  }
}

class FullScreenImage extends StatefulWidget {
  @override
  _FullScreenImageState createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  final AudioRecorderService recorder = AudioRecorderService();
  bool isRecording = false;
  double micVolume = 0;

  @override
  void initState() {
    super.initState();

    recorder.volumeController.stream.listen((vol) {
      print('Mic volume: $vol');
      setState(() {
        micVolume = vol;
      });
    });
  }

  Future<void> handleMicPressed() async {
    if (!isRecording) {
      await recorder.startRecording();
    } else {
      await recorder.stopRecording();
    }

    setState(() {
      isRecording = !isRecording;
    });
  }

  @override
  void dispose() {
    recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen background image
          SizedBox.expand(
            child: Image.asset(
              'assets/uiBG.png',
              fit: BoxFit.cover,
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
                  if (isRecording) AudioVisual(waveLeft: true, volume: micVolume),

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
                          color: isRecording
                              ? Colors.white.withOpacity(0.7)
                              : Colors.blueAccent.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isRecording ? Icons.mic_off : Icons.mic,
                        size: 36,
                        color: Colors.white,
                      ),
                      onPressed: handleMicPressed,
                    ),
                  ),

                  if (isRecording) AudioVisual(waveLeft: false, volume: micVolume),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
