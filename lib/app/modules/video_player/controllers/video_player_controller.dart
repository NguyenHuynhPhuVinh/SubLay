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

  // Observable variables
  final isPlayerReady = false.obs;
  final isFullScreen = true.obs; // Start in fullscreen
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
          forceHD: false,
          hideControls: false, // Keep YouTube controls for now
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
        youtubeController!.play();
      }
    }
  }

  void seekTo(Duration position) {
    if (youtubeController != null) {
      youtubeController!.seekTo(position);
    }
  }

  void toggleFullScreen() {
    if (isFullScreen.value) {
      _exitFullscreen();
    } else {
      _enterFullscreen();
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

  void goBack() {
    _saveVideoProgress();
    _exitFullscreen(); // Restore orientation when leaving
    Get.back();
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
      _enterFullscreen(); // Auto enter fullscreen
      _startControlsTimer(); // Auto hide controls
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

      // Skip saving to history for now to prevent crash
      // _historyService.addOrUpdateVideo(currentVideo!);
    }
  }

  void _saveVideoProgress() {
    // Skip saving for now to prevent crash
    print('Video progress: ${currentPosition.value} / ${totalDuration.value}');
  }

  // Auto-save disabled to prevent crash
  void _startAutoSave() {
    // Disabled to prevent crash
    print('Auto-save disabled');
  }

  @override
  void onClose() {
    _exitFullscreen(); // Restore orientation when controller is disposed
    youtubeController?.removeListener(_playerListener);
    youtubeController?.dispose();
    super.onClose();
  }
}
