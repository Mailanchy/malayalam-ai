import 'dart:io';
import 'dart:typed_data';

/// Converts a raw PCM file (16-bit, mono, 16 kHz) to a WAV file.
/// [pcmPath] is the full path of the input PCM file.
/// The output WAV file is saved in the same directory.
Future<String> convertPcmToWav(String pcmPath) async {
  // Read PCM file bytes.
  final pcmFile = File(pcmPath);
  final pcmBytes = await pcmFile.readAsBytes();
  final pcmDataSize = pcmBytes.length;

  // Generate the WAV file path by replacing the .pcm extension with .wav.
  final wavPath = pcmPath.replaceAll(RegExp(r'\.pcm$'), '.wav');

  // Define WAV parameters.
  const int sampleRate = 16000;
  const int numChannels = 1;
  const int bitsPerSample = 16;
  final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
  final int blockAlign = numChannels * bitsPerSample ~/ 8;
  final int subChunk2Size = pcmDataSize;
  final int chunkSize = 36 + subChunk2Size;

  // Create a 44-byte buffer for the WAV header.
  final header = ByteData(44);

  // RIFF header.
  header.setUint8(0, 'R'.codeUnitAt(0));
  header.setUint8(1, 'I'.codeUnitAt(0));
  header.setUint8(2, 'F'.codeUnitAt(0));
  header.setUint8(3, 'F'.codeUnitAt(0));
  header.setUint32(4, chunkSize, Endian.little);
  header.setUint8(8, 'W'.codeUnitAt(0));
  header.setUint8(9, 'A'.codeUnitAt(0));
  header.setUint8(10, 'V'.codeUnitAt(0));
  header.setUint8(11, 'E'.codeUnitAt(0));

  // fmt subchunk.
  header.setUint8(12, 'f'.codeUnitAt(0));
  header.setUint8(13, 'm'.codeUnitAt(0));
  header.setUint8(14, 't'.codeUnitAt(0));
  header.setUint8(15, ' '.codeUnitAt(0));
  header.setUint32(16, 16, Endian.little); // Subchunk1Size for PCM
  header.setUint16(20, 1, Endian.little); // AudioFormat 1 for PCM
  header.setUint16(22, numChannels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);

  // data subchunk.
  header.setUint8(36, 'd'.codeUnitAt(0));
  header.setUint8(37, 'a'.codeUnitAt(0));
  header.setUint8(38, 't'.codeUnitAt(0));
  header.setUint8(39, 'a'.codeUnitAt(0));
  header.setUint32(40, subChunk2Size, Endian.little);

  // Open the output file and write the header and PCM data.
  final wavFile = File(wavPath);
  final wavSink = wavFile.openWrite();
  wavSink.add(header.buffer.asUint8List());
  wavSink.add(pcmBytes);
  await wavSink.flush();
  await wavSink.close();

  return wavPath;
}
