import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../controllers/video_player_controller.dart';

class VideoPlayerView extends GetView<VideoPlayerController> {
  const VideoPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VideoPlayerController>(
      builder: (controller) {
        if (controller.videoId.value.isEmpty) {
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          print('Pop invoked in normal mode');
        }
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
            SizedBox(
              width: double.infinity,
              height: 250,
              child: _buildVideoPlayer(),
            ),
            _buildSubtitleDisplay(),
            const Spacer(), // Pushes controls to the bottom if any were here
            // Custom controls are removed, using player's built-in controls.
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenPlayer() {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          print('Pop invoked in fullscreen mode');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: SizedBox(
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
      controller: controller.youtubeController,
      aspectRatio: 16 / 9, // Standard video aspect ratio
      bottomActions: [
        CurrentPosition(),
        const SizedBox(width: 8.0),
        ProgressBar(isExpanded: true),
        RemainingDuration(),
        PlaybackSpeedButton(),
      ],
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

  Widget _buildSubtitleDisplay() {
    return Obx(
      () => Container(
        width: double.infinity,
        height: 150, // Tăng từ 120 lên 150
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          border: Border(
            top: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
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
}
