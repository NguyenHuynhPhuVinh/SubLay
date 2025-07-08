import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/video_player_controller.dart';
import '../../main_screen/controllers/main_screen_controller.dart';

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

        // Always show fullscreen player
        return _buildFullScreenPlayer();
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

  Widget _buildFullScreenPlayer() {
    return Scaffold(
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
            // Back button overlay
            _buildBackButton(),
          ],
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
    return Positioned(
      bottom: 60, // Fixed position from bottom
      left: 40,
      right: 40,
      child: Obx(
        () => AnimatedOpacity(
          opacity: controller.currentSubtitle.value.isNotEmpty ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Text(
              controller.currentSubtitle.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14, // Smaller font size
                fontWeight: FontWeight.w500,
                height: 1.3,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Max 2 lines
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
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
                        IconButton(
                          onPressed: controller.goBack,
                          icon: const Icon(Iconsax.arrow_left),
                          color: Colors.white,
                          iconSize: 24.r,
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
                        IconButton(
                          onPressed: controller.toggleFullScreen,
                          icon: Icon(Iconsax.close_square),
                          color: Colors.white,
                          iconSize: 20.r,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Center play/pause button
              Center(
                child: Obx(
                  () => AnimatedOpacity(
                    opacity: controller.showControls.value ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: controller.togglePlayPause,
                        icon: Icon(
                          controller.isPlaying.value
                              ? Iconsax.pause
                              : Iconsax.play,
                        ),
                        color: Colors.white,
                        iconSize: 40.r,
                      ),
                    ),
                  ),
                ),
              ),

              // Center tap area to toggle controls
              Positioned.fill(
                child: GestureDetector(
                  onTap: controller.toggleControls,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 40,
      left: 20,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              // Go back to previous screen
              Get.back();
            },
            icon: const Icon(Iconsax.arrow_left),
            color: Colors.white,
            iconSize: 24,
          ),
        ),
      ),
    );
  }
}
