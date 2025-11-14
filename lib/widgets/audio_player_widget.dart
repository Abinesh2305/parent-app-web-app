import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:rxdart/rxdart.dart' as rx;

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  const AudioPlayerWidget({super.key, required this.audioUrl});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;

  Stream<PositionData> get _positionDataStream =>
      rx.Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  @override
  void initState() {
    super.initState();

    // Configure the audio player for smoother performance
    _player = AudioPlayer(
      handleInterruptions: true,
      androidApplyAudioAttributes: true,
      androidOffloadSchedulingEnabled: false,
    );

    _setup();
  }

  Future<void> _setup() async {
    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(widget.audioUrl)),
        preload: true,
      );

      // Slightly reduce volume to prevent clipping distortion
      _player.setVolume(0.9);
    } catch (e) {
      debugPrint('Audio load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading audio')),
        );
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Play / Pause Button
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;

              if (processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering) {
                return const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 3),
                );
              } else if (playing != true) {
                return IconButton(
                  iconSize: 40,
                  icon:
                      Icon(Icons.play_circle_fill, color: colorScheme.primary),
                  onPressed: _player.play,
                );
              } else if (processingState != ProcessingState.completed) {
                return IconButton(
                  iconSize: 40,
                  icon: Icon(Icons.pause_circle_filled,
                      color: colorScheme.primary),
                  onPressed: _player.pause,
                );
              } else {
                return IconButton(
                  iconSize: 40,
                  icon: Icon(Icons.replay_circle_filled,
                      color: colorScheme.primary),
                  onPressed: () => _player.seek(Duration.zero),
                );
              }
            },
          ),

          const SizedBox(width: 12),

          // Progress bar with duration labels
          Expanded(
            child: StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data ??
                    PositionData(Duration.zero, Duration.zero, Duration.zero);

                return ProgressBar(
                  progress: positionData.position,
                  buffered: positionData.bufferedPosition,
                  total: positionData.total,
                  progressBarColor: colorScheme.primary,
                  baseBarColor: Colors.grey[400],
                  bufferedBarColor: Colors.grey[300],
                  thumbColor: colorScheme.primary,
                  timeLabelTextStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 12,
                  ),
                  onSeek: _player.seek,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration total;

  PositionData(this.position, this.bufferedPosition, this.total);
}
