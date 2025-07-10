import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:iconsax/iconsax.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../controllers/video_player_controller.dart';

class VideoPlayerView extends GetView<VideoPlayerController> {
  const VideoPlayerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VideoPlayerController>(
      builder: (controller) {
        // Check if controller has video data
        if (controller.youtubeController == null ||
            controller.videoId.value.isEmpty) {
          return _buildNoVideoScreen();
        }

        return Obx(
          () => controller.isFullScreen.value
              ? _buildFullScreenPlayer()
              : _buildNormalPlayer(),
        );
      },
    );
  }

  Widget _buildNoVideoScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Player'), centerTitle: true),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.video_slash, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có video',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vui lòng chọn video từ Video Input',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalPlayer() {
    return WillPopScope(
      onWillPop: () async {
        print('WillPop triggered in normal mode');
        return true; // Allow back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: Obx(
            () => Text(
              controller.srtFileName.value.isNotEmpty
                  ? controller.srtFileName.value
                  : 'Video Player',
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () {
              print('Back button tapped in normal mode');
              controller.goBack();
            },
          ),
        ),
        body: Column(
          children: [
            // Video player
            Container(
              width: double.infinity,
              height: 250,
              child: _buildVideoPlayer(),
            ),
            // Subtitle display
            _buildSubtitleDisplay(),
            // Video controls
            _buildVideoControls(),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenPlayer() {
    return WillPopScope(
      onWillPop: () async {
        print('WillPop triggered in fullscreen mode');
        return true; // Allow back navigation
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Video player takes full screen
              Positioned.fill(child: _buildVideoPlayer()),
              // Subtitle overlay only
              _buildFullScreenSubtitleOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return YoutubePlayer(
      controller: controller.youtubeController!,
      aspectRatio: 16 / 9, // Standard video aspect ratio
    );
  }

  Widget _buildFullScreenSubtitleOverlay() {
    return Obx(() {
      final subtitle = controller.currentSubtitle.value;
      if (subtitle.isEmpty) return const SizedBox.shrink();

      // Tính số dòng để điều chỉnh vị trí
      final lineCount = '\n'.allMatches(subtitle).length + 1;
      final bottomPosition = _getSubtitleBottomPosition(lineCount);

      return Positioned(
        bottom: bottomPosition,
        left: 40,
        right: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: Outline đen mượt mà
            AutoSizeText(
              subtitle,
              style: TextStyle(
                fontSize: 16, // Giảm từ 22 xuống 16
                fontWeight: FontWeight.w600, // Giảm từ w700 xuống w600
                height: 1.3,
                letterSpacing: 0.5,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3.0
                  ..strokeJoin = StrokeJoin.round
                  ..strokeCap = StrokeCap.round
                  ..color = Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              minFontSize: 10, // Giảm từ 16 xuống 10
              maxFontSize: 18, // Giảm từ 26 xuống 18
              overflow: TextOverflow.ellipsis,
              wrapWords: true,
            ),
            // Layer 2: Chữ trắng bên trong
            AutoSizeText(
              subtitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16, // Giảm từ 22 xuống 16
                fontWeight: FontWeight.w600, // Giảm từ w700 xuống w600
                height: 1.3,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              minFontSize: 10, // Giảm từ 16 xuống 10
              maxFontSize: 18, // Giảm từ 26 xuống 18
              overflow: TextOverflow.ellipsis,
              wrapWords: true,
            ),
          ],
        ),
      );
    });
  }

  // Tính vị trí bottom dựa trên số dòng (thấp hơn nữa)
  double _getSubtitleBottomPosition(int lineCount) {
    switch (lineCount) {
      case 1:
        return 5.0; // Thấp hơn nữa: 10 -> 5
      case 2:
        return 8.0; // Thấp hơn nữa: 15 -> 8
      case 3:
        return 12.0; // Thấp hơn nữa: 20 -> 12
      case 4:
        return 16.0; // Thấp hơn nữa: 25 -> 16
      default:
        return 20.0; // Thấp hơn nữa: 30 -> 20
    }
  }

  // Format duration to mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildSubtitleDisplay() {
    return Obx(
      () => Container(
        width: double.infinity,
        height: 150, // Tăng từ 120 lên 150
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.3)),
            bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
        ),
        child: Center(
          child: AutoSizeText(
            controller.currentSubtitle.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14, // Giảm từ 18 xuống 14
              fontWeight: FontWeight.w500, // Giảm từ w600 xuống w500
              height: 1.4, // Thêm line height
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black,
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 5, // Tăng từ 4 lên 5 lines
            minFontSize: 10, // Giảm font size tối thiểu từ 14 xuống 10
            maxFontSize: 16, // Giảm font size tối đa từ 20 xuống 16
            overflow: TextOverflow.ellipsis,
            wrapWords: true, // Quan trọng: cho phép wrap words thông minh
          ),
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress bar
          Obx(
            () => Slider(
              value: controller.currentPosition.value.inSeconds.toDouble(),
              max: controller.totalDuration.value.inSeconds.toDouble(),
              onChanged: (value) {
                controller.seekTo(Duration(seconds: value.toInt()));
              },
              activeColor: Colors.red,
              inactiveColor: Colors.grey[300],
            ),
          ),

          // Time display
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(controller.currentPosition.value),
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  _formatDuration(controller.totalDuration.value),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  final newPosition =
                      controller.currentPosition.value -
                      const Duration(seconds: 10);
                  controller.seekTo(newPosition);
                },
                icon: const Icon(Iconsax.backward_10_seconds),
                iconSize: 32,
              ),

              Obx(
                () => IconButton(
                  onPressed: controller.togglePlayPause,
                  icon: Icon(
                    controller.isPlaying.value ? Iconsax.pause : Iconsax.play,
                  ),
                  iconSize: 40,
                  color: Colors.red,
                ),
              ),

              IconButton(
                onPressed: () {
                  final newPosition =
                      controller.currentPosition.value +
                      const Duration(seconds: 10);
                  controller.seekTo(newPosition);
                },
                icon: const Icon(Iconsax.forward_10_seconds),
                iconSize: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
