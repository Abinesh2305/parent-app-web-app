import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YouTubePlayerScreen extends StatefulWidget {
  final String videoUrl;

  const YouTubePlayerScreen({super.key, required this.videoUrl});

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  late final YoutubePlayerController _controller;
  late final String videoId;

  @override
  void initState() {
    super.initState();

    videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl) ?? "";

    if (videoId.isEmpty) {
      debugPrint("Invalid YouTube URL");
      return;
    }

    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    )..loadVideoById(videoId: videoId);
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (videoId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Invalid video link")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("YouTube Video")),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(
            controller: _controller,
          ),
        ),
      ),
    );
  }
}
