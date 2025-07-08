import 'dart:async';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/srt_parser.dart';
import '../../../data/services/video_history_service.dart';
import '../../../data/models/video_with_subtitle.dart';

class VideoPlayerController extends GetxController {
  // Services
  final VideoHistoryService _historyService = Get.find<VideoHistoryService>();

  // YouTube Player Controller
  YoutubePlayerController? youtubeController;
  Timer? _controlsTimer; // Timer for auto-hiding controls

  // Observable variables
  final isPlayerReady = false.obs;
  final isFullScreen = false.obs; // Start in normal mode
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  final isPlaying = false.obs;
  final showControls = true.obs;
  final currentSubtitle = ''.obs;

  // Subtitle data
  List<SrtSubtitle> subtitles = [];
  final srtContent = ''.obs;
  final videoId = ''.obs;
  final youtubeUrl = ''.obs;
  final srtFileName = ''.obs;

  // Current video model
  VideoWithSubtitle? currentVideo;

  @override
  void onInit() {
    super.onInit();

    // Start in portrait mode (normal mode)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Show system UI in normal mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Get arguments from navigation
    final args = Get.arguments as Map<String, dynamic>?;
    print('DEBUG - VideoPlayer arguments: $args');

    if (args != null) {
      videoId.value = args['videoId'] ?? '';
      youtubeUrl.value = args['youtubeUrl'] ?? '';
      srtContent.value = args['srtContent'] ?? '';
      srtFileName.value = args['srtFileName'] ?? '';

      print('DEBUG - VideoPlayer data:');
      print('  - videoId: ${videoId.value}');
      print('  - youtubeUrl: ${youtubeUrl.value}');
      print('  - srtContent length: ${srtContent.value.length}');
      print('  - srtFileName: ${srtFileName.value}');

      if (videoId.value.isNotEmpty) {
        _initializePlayer();
        _parseSrtContent();
        _createVideoModel();
      } else {
        print('ERROR - No videoId provided');
      }
    } else {
      print('ERROR - No arguments provided to VideoPlayer');
    }
  }

  void _initializePlayer() {
    if (videoId.value.isNotEmpty) {
      youtubeController = YoutubePlayerController(
        initialVideoId: videoId.value,
        flags: const YoutubePlayerFlags(
          autoPlay: true, // Auto play
          mute: false,
          enableCaption: false, // Disable YouTube captions to use our SRT
          loop: false,
          forceHD: true, // Force HD quality
          hideControls: true, // Hide YouTube controls to use custom controls
          disableDragSeek: false, // Allow seeking
          useHybridComposition: true, // Better performance
        ),
      );

      youtubeController!.addListener(_playerListener);
      // Don't start auto-save to prevent crash
    }
  }

  void _playerListener() {
    if (youtubeController != null) {
      isPlayerReady.value = youtubeController!.value.isReady;
      isPlaying.value = youtubeController!.value.isPlaying;
      currentPosition.value = youtubeController!.value.position;
      totalDuration.value = youtubeController!.value.metaData.duration;

      // Update subtitle based on current position
      _updateCurrentSubtitle();
    }
  }

  void _parseSrtContent() {
    if (srtContent.value.isNotEmpty) {
      try {
        // Parse SRT content using custom parser
        subtitles = SrtParser.parse(srtContent.value);

        if (subtitles.isNotEmpty) {
          Get.snackbar(
            'Thành công',
            'Đã tải ${subtitles.length} phụ đề',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Cảnh báo',
            'Không tìm thấy phụ đề hợp lệ trong file SRT',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withOpacity(0.8),
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Lỗi',
          'Không thể phân tích file SRT: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  void _updateCurrentSubtitle() {
    if (subtitles.isEmpty) return;

    // Use SrtParser helper method to find current subtitle
    currentSubtitle.value = SrtParser.findCurrentSubtitle(
      subtitles,
      currentPosition.value,
    );
  }

  void togglePlayPause() {
    if (youtubeController != null) {
      if (isPlaying.value) {
        youtubeController!.pause();
      } else {
        // Khi play lại từ trạng thái pause, trừ 5s
        final currentSeconds = currentPosition.value.inSeconds;
        final rewindSeconds = currentSeconds < 5 ? 0 : currentSeconds - 5;
        final rewindPosition = Duration(seconds: rewindSeconds);

        if (rewindPosition != currentPosition.value) {
          youtubeController!.seekTo(rewindPosition);
          print(
            'Rewound 5s before play: ${rewindPosition.inSeconds}s (from ${currentSeconds}s)',
          );
        }

        youtubeController!.play();
      }
    }
  }

  // Seek to specific position
  void seekTo(Duration position) {
    if (youtubeController != null) {
      youtubeController!.seekTo(position);
    }
  }

  // Seek relative to current position
  void seekRelative(int seconds) {
    if (youtubeController != null) {
      final newPosition = currentPosition.value + Duration(seconds: seconds);
      final clampedPosition = Duration(
        seconds: newPosition.inSeconds.clamp(0, totalDuration.value.inSeconds),
      );
      youtubeController!.seekTo(clampedPosition);
    }
  }

  // Getters for compatibility with view
  Duration get videoPosition => currentPosition.value;
  Duration get videoDuration => totalDuration.value;

  void toggleFullScreen() {
    if (isFullScreen.value) {
      _exitFullscreen();
    } else {
      _enterFullscreen();
    }
    update(); // Trigger rebuild
  }

  // Chỉ thoát fullscreen, không về Input
  void exitFullscreenOnly() {
    print('exitFullscreenOnly called');
    if (isFullScreen.value) {
      isFullScreen.value = false;
      _exitFullscreen();
      update();
    }
  }

  void _enterFullscreen() {
    isFullScreen.value = true;
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI - try different approach
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    // Start controls timer for fullscreen
    _startControlsTimer();
  }

  void _exitFullscreen() {
    isFullScreen.value = false;
    // Restore portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Show system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Stop controls timer when exit fullscreen
    _controlsTimer?.cancel();
    showControls.value = true; // Always show controls in normal mode
  }

  void toggleControls() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      _startControlsTimer();
    }
  }

  void _startControlsTimer() {
    // Auto hide controls after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (showControls.value) {
        showControls.value = false;
      }
    });
  }

  // Method to set video data directly (for tab navigation)
  void setVideoData({
    required String videoId,
    required String youtubeUrl,
    required String srtContent,
    required String srtFileName,
  }) {
    print('DEBUG - setVideoData called with:');
    print('  - videoId: $videoId');
    print('  - youtubeUrl: $youtubeUrl');
    print('  - srtContent length: ${srtContent.length}');
    print('  - srtFileName: $srtFileName');

    this.videoId.value = videoId;
    this.youtubeUrl.value = youtubeUrl;
    this.srtContent.value = srtContent;
    this.srtFileName.value = srtFileName;

    if (videoId.isNotEmpty) {
      _initializePlayer();
      _parseSrtContent();
      _createVideoModel();

      // Start in normal mode - no auto fullscreen
      // _startControlsTimer(); // No need for controls timer in normal mode
      // _startAutoSave(); // Disable auto-save for now to prevent crash
      update(); // Trigger GetBuilder rebuild
    }
  }

  void _createVideoModel() {
    if (videoId.value.isNotEmpty) {
      currentVideo = VideoWithSubtitle.fromInput(
        videoId: videoId.value,
        youtubeUrl: youtubeUrl.value,
        srtContent: srtContent.value,
        srtFileName: srtFileName.value,
      );

      // Save to history when user starts watching (no auto-update)
      _historyService.addOrUpdateVideo(currentVideo!);
    }
  }

  void goBack() {
    print('VideoPlayerController.goBack() called');
    print('Current route: ${Get.currentRoute}');

    // Always restore orientation and go back to previous screen
    _exitFullscreen();

    // Clear video data
    youtubeController?.pause();

    // Use Navigator.pop instead of Get.back to avoid GetX SnackbarController error
    try {
      if (Get.key.currentState?.canPop() == true) {
        print('Using Navigator.pop()');
        Get.key.currentState?.pop();
      } else {
        print('Using Get.offAllNamed to main screen');
        Get.offAllNamed('/main');
      }
    } catch (e) {
      print('Navigation error: $e');
      // Fallback to main screen
      Get.offAllNamed('/main');
    }
  }

  @override
  void onClose() {
    print('VideoPlayerController.onClose() called');
    _exitFullscreen(); // Restore orientation when controller is disposed
    youtubeController?.removeListener(_playerListener);
    youtubeController?.dispose();
    super.onClose();
  }
}
