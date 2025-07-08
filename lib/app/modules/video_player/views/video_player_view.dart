import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/video_player_controller.dart';

class VideoPlayerView extends GetView<VideoPlayerController> {
  const VideoPlayerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.youtubeController == null) {
        return _buildNoVideoScreen();
      }

      return controller.isFullScreen.value
          ? _buildFullScreenPlayer()
          : _buildNormalPlayer();
    });
  }

  Widget _buildNoVideoScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.video_slash,
              size: 64,
              color: Colors.grey,
            ),
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalPlayer() {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.srtFileName.isNotEmpty 
            ? controller.srtFileName 
            : 'Video Player'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.maximize_4),
            onPressed: controller.toggleFullScreen,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildVideoPlayer(),
          _buildSubtitleDisplay(),
          _buildVideoControls(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFullScreenPlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: _buildVideoPlayer()),
          _buildFullScreenOverlay(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      height: controller.isFullScreen.value ? double.infinity : 250.h,
      child: YoutubePlayer(
        controller: controller.youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
        onReady: () {
          controller.isPlayerReady.value = true;
        },
        onEnded: (data) {
          // Video ended
        },
      ),
    );
  }

  Widget _buildSubtitleDisplay() {
    return Obx(() => Container(
      width: double.infinity,
      height: 80.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.3)),
          bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
      ),
      child: Center(
        child: Text(
          controller.currentSubtitle.value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.8),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ));
  }

  Widget _buildVideoControls() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Progress bar
          Obx(() => Slider(
            value: controller.currentPosition.value.inSeconds.toDouble(),
            max: controller.totalDuration.value.inSeconds.toDouble(),
            onChanged: (value) {
              controller.seekTo(Duration(seconds: value.toInt()));
            },
            activeColor: Colors.red,
            inactiveColor: Colors.grey[300],
          )),
          
          // Time display
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(controller.currentPosition.value),
                style: TextStyle(fontSize: 12.sp),
              ),
              Text(
                _formatDuration(controller.totalDuration.value),
                style: TextStyle(fontSize: 12.sp),
              ),
            ],
          )),
          
          SizedBox(height: 16.h),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  final newPosition = controller.currentPosition.value - 
                      const Duration(seconds: 10);
                  controller.seekTo(newPosition);
                },
                icon: const Icon(Iconsax.backward_10_seconds),
                iconSize: 32.r,
              ),
              
              Obx(() => IconButton(
                onPressed: controller.togglePlayPause,
                icon: Icon(
                  controller.isPlaying.value 
                      ? Iconsax.pause 
                      : Iconsax.play,
                ),
                iconSize: 40.r,
                color: Colors.red,
              )),
              
              IconButton(
                onPressed: () {
                  final newPosition = controller.currentPosition.value + 
                      const Duration(seconds: 10);
                  controller.seekTo(newPosition);
                },
                icon: const Icon(Iconsax.forward_10_seconds),
                iconSize: 32.r,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenOverlay() {
    return Obx(() => AnimatedOpacity(
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
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: controller.toggleFullScreen,
                        icon: const Icon(Iconsax.arrow_left),
                        color: Colors.white,
                      ),
                      Expanded(
                        child: Text(
                          controller.srtFileName.isNotEmpty 
                              ? controller.srtFileName 
                              : 'DuTupSRT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom subtitle
            Positioned(
              bottom: 100.h,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  controller.currentSubtitle.value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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
    ));
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
}
