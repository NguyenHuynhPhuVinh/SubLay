import 'dart:async';
import 'package:get/get.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/srt_parser.dart';
import '../../../core/services/subtitle_settings_service.dart';
import '../../../data/services/video_service.dart';
import '../../../data/services/app_settings_service.dart';
import '../../../data/models/video_with_subtitle.dart';

class VideoPlayerController extends GetxController {
  // Services
  final VideoService _historyService = Get.find<VideoService>();
  final AppSettingsService _settingsService = Get.find<AppSettingsService>();
  final SubtitleSettingsService _subtitleSettings = Get.find<SubtitleSettingsService>();

  // YouTube Player Controller
  YoutubePlayerController? youtubeController;
  Timer? _controlsTimer; // Timer for auto-hiding controls
  Timer? _positionTimer; // Timer for position updates

  // Observable variables
  final isPlayerReady = false.obs;
  final isFullScreen = false.obs; // Will be set based on user settings
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
  final videoTitle = ''.obs;
  final srtFileName = ''.obs;

  // Current video model
  VideoWithSubtitle? currentVideo;

  @override
  void onInit() {
    super.onInit();

    // Set fullscreen mode and orientation based on user settings
    _setFullScreenModeFromSettings();

    // Hide system UI for fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Get arguments from navigation
    final args = Get.arguments as Map<String, dynamic>?;

    if (args != null) {
      videoId.value = args['videoId'] ?? '';
      youtubeUrl.value = args['youtubeUrl'] ?? '';
      videoTitle.value = args['title'] ?? 'YouTube Video';
      srtContent.value = args['srtContent'] ?? '';
      srtFileName.value = args['srtFileName'] ?? '';

      if (videoId.value.isNotEmpty) {
        _initializePlayer();
        _parseSrtContent();
        _createVideoModel();
      }
    }
  }

  void _initializePlayer() {
    if (videoId.value.isNotEmpty) {
      try {
        youtubeController = YoutubePlayerController(
          params: const YoutubePlayerParams(
            mute: false,
            enableCaption: false,
            enableJavaScript: true,
            loop: false,
            playsInline: true,
            showControls: true,
            showFullscreenButton: false,
            strictRelatedVideos: false,
          ),
        );

        // Load video after controller initialization
        _loadVideoDelayed();

        // Add listener for player state changes and errors
        youtubeController!.listen((event) {
          // Check if there's an error in the player state
          if (event.hasError) {
            _handlePlayerError(null);
          }
        });

        // Start position timer for iframe player
        _startPositionTimer();
      } catch (e) {
        Get.snackbar(
          'Lỗi',
          'Không thể khởi tạo trình phát video: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  void _loadVideoDelayed() {
    // Load video after a delay to ensure controller is fully initialized
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        if (youtubeController != null && videoId.value.isNotEmpty) {
          await youtubeController!.loadVideoById(videoId: videoId.value);
          // Auto-play after loading
          Future.delayed(const Duration(milliseconds: 300), () async {
            try {
              await youtubeController!.playVideo();
            } catch (e) {
              // Silent fail for auto-play
            }
          });
        }
      } catch (e) {
        // If loading fails, try alternative approach
        _tryAlternativeLoad();
      }
    });
  }

  void _tryAlternativeLoad() {
    // Alternative loading method for problematic video IDs
    Future.delayed(const Duration(milliseconds: 1000), () async {
      try {
        if (youtubeController != null) {
          // Try reloading with the same video ID but different timing
          await youtubeController!.loadVideoById(videoId: videoId.value);
        }
      } catch (e) {
        // Silent fail for alternative load
      }
    });
  }

  void _handlePlayerError(String? errorCode) {
    String errorMessage = 'Lỗi không xác định';

    switch (errorCode) {
      case '2':
        errorMessage = 'Video ID không hợp lệ';
        break;
      case '5':
        errorMessage = 'Video không hỗ trợ phát trên HTML5 player';
        break;
      case '100':
        errorMessage = 'Video không tìm thấy hoặc đã bị xóa';
        break;
      case '101':
      case '150':
        errorMessage = 'Video bị hạn chế hoặc không khả dụng ở khu vực của bạn';
        break;
      default:
        errorMessage = 'Không thể phát video (Mã lỗi: $errorCode)';
    }

    Get.snackbar(
      'Lỗi phát video',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    // Giảm interval xuống 100ms để phụ đề responsive hơn
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) async {
      if (youtubeController != null) {
        try {
          final position = await youtubeController!.currentTime;

          // Giữ độ chính xác millisecond cho phụ đề
          final precisePosition = Duration(milliseconds: (position * 1000).toInt());
          currentPosition.value = precisePosition;

          // Chỉ cập nhật duration và player state mỗi 500ms để tối ưu performance
          if (timer.tick % 5 == 0) {
            final duration = await youtubeController!.duration;
            final playerState = await youtubeController!.playerState;

            totalDuration.value = Duration(seconds: duration.toInt());
            isPlaying.value = playerState == PlayerState.playing;
            isPlayerReady.value = playerState != PlayerState.unknown;
          }

          // Update subtitle based on current position với độ chính xác cao
          _updateCurrentSubtitle();

        } catch (e) {
          // Silent error handling for position updates
        }
      }
    });
  }

  void _parseSrtContent() {
    if (srtContent.value.isNotEmpty) {
      // Parse SRT content using custom parser
      subtitles = SrtParser.parse(srtContent.value);
    }
  }

  // Cache để tối ưu tìm kiếm phụ đề
  int _lastSubtitleIndex = -1;

  void _updateCurrentSubtitle() {
    if (subtitles.isEmpty) return;

    // Áp dụng subtitle offset từ settings service
    final adjustedTime = Duration(
      milliseconds: currentPosition.value.inMilliseconds + _subtitleSettings.subtitleOffset.value
    );

    // Tối ưu: kiểm tra subtitle hiện tại trước
    if (_lastSubtitleIndex >= 0 && _lastSubtitleIndex < subtitles.length) {
      final currentSub = subtitles[_lastSubtitleIndex];
      if (adjustedTime >= currentSub.startTime && adjustedTime <= currentSub.endTime) {
        // Vẫn trong subtitle hiện tại, không cần tìm lại
        return;
      }
    }

    // Tìm subtitle mới với tối ưu hóa
    String newSubtitle = '';
    for (int i = 0; i < subtitles.length; i++) {
      final subtitle = subtitles[i];
      if (adjustedTime >= subtitle.startTime && adjustedTime <= subtitle.endTime) {
        newSubtitle = subtitle.text;
        _lastSubtitleIndex = i;
        break;
      }
    }

    // Chỉ cập nhật nếu có thay đổi để tránh rebuild không cần thiết
    if (currentSubtitle.value != newSubtitle) {
      currentSubtitle.value = newSubtitle;
    }

    // Reset cache nếu không tìm thấy subtitle
    if (newSubtitle.isEmpty) {
      _lastSubtitleIndex = -1;
    }
  }





  void togglePlayPause() async {
    if (youtubeController != null) {
      try {
        if (isPlaying.value) {
          await youtubeController!.pauseVideo();
        } else {
          // Khi play lại từ trạng thái pause, trừ 5s
          final currentSeconds = currentPosition.value.inSeconds;
          final rewindSeconds = currentSeconds < 5 ? 0 : currentSeconds - 5;
          final rewindPosition = Duration(seconds: rewindSeconds);

          if (rewindPosition != currentPosition.value) {
            await youtubeController!.seekTo(
              seconds: rewindPosition.inSeconds.toDouble(),
            );
            // Rewound 5s before play
          }

          await youtubeController!.playVideo();
        }

        // Reset controls timer when user interacts
        _resetControlsTimer();
      } catch (e) {
        // Silent error handling
      }
    }
  }

  // Seek to specific position
  void seekTo(Duration position) async {
    if (youtubeController != null) {
      try {
        await youtubeController!.seekTo(seconds: position.inSeconds.toDouble());
        // Reset controls timer when user interacts
        _resetControlsTimer();
      } catch (e) {
        // Silent error handling
      }
    }
  }

  // Seek relative to current position
  void seekRelative(int seconds) async {
    if (youtubeController != null) {
      try {
        final newPosition = currentPosition.value + Duration(seconds: seconds);
        final clampedPosition = Duration(
          seconds: newPosition.inSeconds.clamp(
            0,
            totalDuration.value.inSeconds,
          ),
        );
        await youtubeController!.seekTo(
          seconds: clampedPosition.inSeconds.toDouble(),
        );
        // Reset controls timer when user interacts
        _resetControlsTimer();
      } catch (e) {
        // Silent error handling
      }
    }
  }

  // Getters for compatibility with view
  Duration get videoPosition => currentPosition.value;
  Duration get videoDuration => totalDuration.value;

  void _setFullScreenModeFromSettings() {
    if (_settingsService.isLandscapeMode) {
      // Landscape mode = fullscreen player
      isFullScreen.value = true;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Portrait mode = normal player
      isFullScreen.value = false;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void toggleControls() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      _startControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _startControlsTimer() {
    // Cancel existing timer
    _controlsTimer?.cancel();

    // Auto hide controls after 4 seconds
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (showControls.value) {
        showControls.value = false;
      }
    });
  }

  // Reset controls timer when user interacts
  void _resetControlsTimer() {
    if (isFullScreen.value && showControls.value) {
      _startControlsTimer();
    }
  }

  // Public method to reset controls timer
  void resetControlsTimer() {
    _resetControlsTimer();
  }

  // Show controls and reset timer
  void showControlsAndResetTimer() {
    showControls.value = true;
    _resetControlsTimer();
  }

  // Method to set video data directly (for tab navigation)
  void setVideoData({
    required String videoId,
    required String youtubeUrl,
    required String srtContent,
    required String srtFileName,
    String? title,
  }) {
    this.videoId.value = videoId;
    this.youtubeUrl.value = youtubeUrl;
    this.videoTitle.value = title ?? 'YouTube Video';
    this.srtContent.value = srtContent;
    this.srtFileName.value = srtFileName;

    if (videoId.isNotEmpty) {
      _initializePlayer();
      _parseSrtContent();
      _createVideoModel();

      // Set fullscreen mode and orientation based on user settings
      _setFullScreenModeFromSettings();
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
        title: videoTitle.value,
      );

      // Save to history when user starts watching (no auto-update)
      _historyService.addOrUpdateVideo(currentVideo!);
    }
  }

  void goBack() {
    // Restore portrait orientation when going back
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Clear video data
    youtubeController?.pauseVideo();

    // Use Navigator.pop instead of Get.back to avoid GetX SnackbarController error
    try {
      if (Get.key.currentState?.canPop() == true) {
        Get.key.currentState?.pop();
      } else {
        Get.offAllNamed('/main');
      }
    } catch (e) {
      // Fallback to main screen
      Get.offAllNamed('/main');
    }
  }

  @override
  void onClose() {
    // Restore portrait orientation when controller is disposed
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _positionTimer?.cancel();
    _controlsTimer?.cancel();
    youtubeController?.close();
    super.onClose();
  }
}
