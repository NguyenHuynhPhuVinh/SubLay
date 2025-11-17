import 'dart:async';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
  final SubtitleSettingsService _subtitleSettings =
      Get.find<SubtitleSettingsService>();

  // YouTube Player Controller
  late YoutubePlayerController youtubeController;
  Timer? _controlsTimer; // Timer for auto-hiding controls
  Timer? _qualityTimer; // Timer để ép chất lượng HD định kỳ

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
          initialVideoId: videoId.value,
          flags: const YoutubePlayerFlags(
            mute: false,
            autoPlay: true,
            enableCaption: false,
            loop: false,
            hideControls: false,
            forceHD: true, // Vẫn giữ để yêu cầu HD ban đầu
          ),
        );
        youtubeController.addListener(_playerListener);
      } catch (e) {
        Get.snackbar(
          'Lỗi',
          'Không thể khởi tạo trình phát video: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  void _playerListener() {
    final value = youtubeController.value;

    // Bắt đầu timer ép chất lượng HD khi trình phát đã sẵn sàng
    if (value.isReady && _qualityTimer == null) {
      _startQualityTimer();
    }

    currentPosition.value = value.position;
    totalDuration.value = value.metaData.duration;
    isPlaying.value = value.isPlaying;
    isPlayerReady.value = value.isReady;
    if (value.hasError) {
      _handlePlayerError(value.errorCode);
    }
    _updateCurrentSubtitle();
  }

  void _startQualityTimer() {
    _qualityTimer?.cancel();
    // Chạy ngay lần đầu
    _setVideoQuality();
    // Sau đó chạy định kỳ mỗi 1 giây
    _qualityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _setVideoQuality();
    });
  }

  void _setVideoQuality() {
    try {
      youtubeController.value.webViewController?.evaluateJavascript(
        source: 'player.setPlaybackQuality("hd720")',
      );
    } catch (e) {
      // Silent fail nếu không thể set quality
    }
  }

  void _handlePlayerError(int errorCode) {
    String errorMessage = 'Lỗi không xác định';

    switch (errorCode) {
      case 1:
        errorMessage = 'Video ID không hợp lệ';
      case 5:
        errorMessage = 'Video không hỗ trợ phát trên HTML5 player';
      case 100:
        errorMessage = 'Video không tìm thấy hoặc đã bị xóa';
      case 101:
      case 150:
        errorMessage = 'Video bị hạn chế hoặc không khả dụng ở khu vực của bạn';
      default:
        errorMessage = 'Không thể phát video (Mã lỗi: $errorCode)';
    }

    Get.snackbar(
      'Lỗi phát video',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
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
      milliseconds:
          currentPosition.value.inMilliseconds +
          _subtitleSettings.subtitleOffset.value,
    );

    // Tối ưu: kiểm tra subtitle hiện tại trước
    if (_lastSubtitleIndex >= 0 && _lastSubtitleIndex < subtitles.length) {
      final currentSub = subtitles[_lastSubtitleIndex];
      if (adjustedTime >= currentSub.startTime &&
          adjustedTime <= currentSub.endTime) {
        // Vẫn trong subtitle hiện tại, không cần tìm lại
        return;
      }
    }

    // Tìm subtitle mới với tối ưu hóa
    String newSubtitle = '';
    for (int i = 0; i < subtitles.length; i++) {
      final subtitle = subtitles[i];
      if (adjustedTime >= subtitle.startTime &&
          adjustedTime <= subtitle.endTime) {
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
    try {
      if (youtubeController.value.isPlaying) {
        youtubeController.pause();
      } else {
        // Khi play lại từ trạng thái pause, trừ 5s
        final currentSeconds = currentPosition.value.inSeconds;
        final rewindSeconds = currentSeconds < 5 ? 0 : currentSeconds - 5;
        final rewindPosition = Duration(seconds: rewindSeconds);

        seekTo(rewindPosition);
        youtubeController.play();
      }

      // Reset controls timer when user interacts
      _resetControlsTimer();
    } catch (e) {
      // Silent error handling
    }
  }

  // Seek to specific position
  void seekTo(Duration position) async {
    try {
      youtubeController.seekTo(position);
      // Reset controls timer when user interacts
      _resetControlsTimer();
    } catch (e) {
      // Silent error handling
    }
  }

  // Seek relative to current position
  void seekRelative(int seconds) async {
    try {
      final newPosition = currentPosition.value + Duration(seconds: seconds);
      final clampedPosition = Duration(
        seconds: newPosition.inSeconds.clamp(0, totalDuration.value.inSeconds),
      );
      youtubeController.seekTo(clampedPosition);
      // Reset controls timer when user interacts
      _resetControlsTimer();
    } catch (e) {
      // Silent error handling
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
    videoTitle.value = title ?? 'YouTube Video';
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
    youtubeController.pause();

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
    _controlsTimer?.cancel();
    _qualityTimer?.cancel();
    youtubeController.removeListener(_playerListener);
    youtubeController.dispose();
    super.onClose();
  }
}
