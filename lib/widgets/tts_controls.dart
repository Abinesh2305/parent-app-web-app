import 'package:flutter/material.dart';

class TtsControls extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onRestart;
  final bool isSpeaking;
  final bool isPaused;

  const TtsControls({
    super.key,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onRestart,
    required this.isSpeaking,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.volume_up), onPressed: onStart),
        IconButton(
            icon: const Icon(Icons.pause), onPressed: isSpeaking ? onPause : null),
        IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: isPaused ? onResume : null),
        IconButton(
            icon: const Icon(Icons.stop),
            onPressed: isSpeaking || isPaused ? onStop : null),
        IconButton(icon: const Icon(Icons.refresh), onPressed: onRestart),
      ],
    );
  }
}
