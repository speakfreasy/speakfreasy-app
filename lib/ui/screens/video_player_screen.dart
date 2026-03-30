import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String libraryId;
  final String videoId;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.libraryId,
    required this.videoId,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final embedUrl =
        'https://iframe.mediadelivery.net/embed/${widget.libraryId}/${widget.videoId}?autoplay=true&responsive=true';

    _controller = WebViewController();
    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    }
    _controller.loadRequest(Uri.parse(embedUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        backgroundColor: SFColors.charcoal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
