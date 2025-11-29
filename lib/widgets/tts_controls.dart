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
        IconButton(icon: Icon(Icons.volume_up), onPressed: onStart),
        IconButton(
            icon: Icon(Icons.pause), onPressed: isSpeaking ? onPause : null),
        IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: isPaused ? onResume : null),
        IconButton(
            icon: Icon(Icons.stop),
            onPressed: isSpeaking || isPaused ? onStop : null),
        IconButton(icon: Icon(Icons.refresh), onPressed: onRestart),
      ],
    );
  }
}
