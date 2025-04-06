import 'package:flutter/material.dart';
import 'dart:math';

class AudioVisual extends StatelessWidget {
  final bool waveLeft;
  final double volume; // volume input from mic

  const AudioVisual({
    super.key,
    required this.waveLeft,
    required this.volume,
  });

  @override
  Widget build(BuildContext context) {
    final barHeights = List.generate(
      5,
          (i) {
        final scale = 10 + (volume * (1 + i * 0.2)); // reactive scale
        return min(scale, 60.0); // limit height to avoid crazy spikes
      },
    );

    final bars = waveLeft ? barHeights : barHeights.reversed.toList();

    return Row(
      children: bars
          .map(
            (h) => Container(
          width: 5,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      )
          .toList(),
    );
  }
}