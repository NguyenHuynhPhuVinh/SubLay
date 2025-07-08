import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          actions: [
            IconButton(
              icon: const Icon(Iconsax.arrow_up_3),
              onPressed: controller.toggleFullScreen,
            ),
          ],
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
              // Subtitle overlay
              _buildFullScreenSubtitleOverlay(),
              // Controls overlay
              _buildFullScreenControlsOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return YoutubePlayer(
      controller: controller.youtubeController!,
      showVideoProgressIndicator: false, // Hide default progress bar
      progressIndicatorColor: Colors.red,
      progressColors: const ProgressBarColors(
        playedColor: Colors.red,
        handleColor: Colors.redAccent,
      ),
      aspectRatio: 16 / 9, // Standard video aspect ratio
      onReady: () {
        controller.isPlayerReady.value = true;
        // Auto play when ready
        controller.youtubeController!.play();
      },
      onEnded: (data) {
        // Video ended - could show replay options
        controller.showControls.value = true;
      },
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
            // Outline đen mượt mà
            AutoSizeText(
              subtitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.3,
                letterSpacing: 0.5,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..color = Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 5,
              minFontSize: 12,
              maxFontSize: 20,
              overflow: TextOverflow.ellipsis,
              wrapWords: true,
            ),
            // Chữ trắng bên trên
            AutoSizeText(
              subtitle,
              style: const TextStyle(
                color: Color(0xFFFFFFF0),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.3,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 5,
              minFontSize: 12,
              maxFontSize: 20,
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

  // Show quality selector dialog
  void _showQualitySelector() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chất lượng video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildQualityOption('Auto', 'auto'),
              _buildQualityOption('1080p', 'hd1080'),
              _buildQualityOption('720p', 'hd720'),
              _buildQualityOption('480p', 'large'),
              _buildQualityOption('360p', 'medium'),
              _buildQualityOption('240p', 'small'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualityOption(String label, String quality) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        // Close dialog
        Get.back();

        // Show snackbar
        Get.snackbar(
          'Chất lượng video',
          'Đã chọn $label',
          backgroundColor: Colors.black.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Note: YouTube Player Flutter doesn't support runtime quality change
        // This is just UI feedback. Quality is controlled by forceHD flag
      },
    );
  }

  // Bottom controls with progress bar and time controls
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              _buildProgressBar(),
              SizedBox(height: 12.h),
              // Control buttons row
              _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // Progress bar with time display
  Widget _buildProgressBar() {
    return Obx(() {
      final duration = controller.totalDuration.value;
      final position = controller.currentPosition.value;

      return Row(
        children: [
          // Current time
          Text(
            _formatDuration(position),
            style: TextStyle(color: Colors.white, fontSize: 12.sp),
          ),
          SizedBox(width: 8.w),
          // Progress slider
          Expanded(
            child: SliderTheme(
              data: const SliderThemeData(
                activeTrackColor: Colors.red,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.red,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                trackHeight: 3,
              ),
              child: Slider(
                value: duration.inSeconds > 0
                    ? (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0)
                    : 0.0,
                onChanged: (value) {
                  final newPosition = Duration(
                    seconds: (value * duration.inSeconds).round(),
                  );
                  controller.seekTo(newPosition);
                },
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Total duration
          Text(
            _formatDuration(duration),
            style: TextStyle(color: Colors.white, fontSize: 12.sp),
          ),
        ],
      );
    });
  }

  // Control buttons (rewind, play/pause, forward)
  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10s
        GestureDetector(
          onTap: () => controller.seekRelative(-10),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.replay_10, color: Colors.white, size: 32),
          ),
        ),
        SizedBox(width: 24.w),
        // Play/Pause
        Obx(
          () => GestureDetector(
            onTap: controller.togglePlayPause,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),
        SizedBox(width: 24.w),
        // Forward 10s
        GestureDetector(
          onTap: () => controller.seekRelative(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.forward_10, color: Colors.white, size: 32),
          ),
        ),
      ],
    );
  }

  // Format duration to mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildFullScreenControlsOverlay() {
    return Obx(
      () => AnimatedOpacity(
        opacity: controller.showControls.value ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Stack(
            children: [
              // Tap area to toggle controls and play/pause (bottom layer)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    // Single tap toggles controls
                    controller.toggleControls();
                  },
                  onDoubleTap: () {
                    // Double tap toggles play/pause
                    controller.togglePlayPause();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Container(),
                ),
              ),

              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            print('Back button tapped in fullscreen!');
                            controller.goBack();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Iconsax.arrow_left,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Obx(
                            () => Text(
                              controller.srtFileName.value.isNotEmpty
                                  ? controller.srtFileName.value
                                  : 'DuTupSRT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        // Quality button
                        GestureDetector(
                          onTap: _showQualitySelector,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.hd,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: () {
                            print(
                              'Minimize button tapped - exit fullscreen only!',
                            );
                            controller.exitFullscreenOnly();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Iconsax.arrow_down_1, // Luôn là minimize icon
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom controls bar (chỉ giữ controls ở bottom)
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
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
              fontSize: 16, // Tăng lại lên 16 vì AutoSizeText sẽ tự điều chỉnh
              fontWeight: FontWeight.w500,
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
            minFontSize: 12, // Font size tối thiểu
            maxFontSize: 18, // Font size tối đa
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
