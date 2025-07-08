import 'dart:async';
import 'package:get/get.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/srt_parser.dart';
import '../../../data/services/video_history_service.dart';
import '../../../data/services/app_settings_service.dart';
import '../../../data/models/video_with_subtitle.dart';

class VideoPlayerController extends GetxController {
  // Services
  final VideoHistoryService _historyService = Get.find<VideoHistoryService>();
  final AppSettingsService _settingsService = Get.find<AppSettingsService>();

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
      youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId.value,
        autoPlay: true,
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

      // Start position timer for iframe player
      _startPositionTimer();
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (youtubeController != null) {
        try {
          final position = await youtubeController!.currentTime;
          final duration = await youtubeController!.duration;
          final playerState = await youtubeController!.playerState;

          currentPosition.value = Duration(seconds: position.toInt());
          totalDuration.value = Duration(seconds: duration.toInt());
          isPlaying.value = playerState == PlayerState.playing;
          isPlayerReady.value = playerState != PlayerState.unknown;

          // Update subtitle based on current position
          _updateCurrentSubtitle();
        } catch (e) {
          print('Error getting player state: $e');
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

  void _updateCurrentSubtitle() {
    if (subtitles.isEmpty) return;

    // Use SrtParser helper method to find current subtitle
    currentSubtitle.value = SrtParser.findCurrentSubtitle(
      subtitles,
      currentPosition.value,
    );
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
            print(
              'Rewound 5s before play: ${rewindPosition.inSeconds}s (from ${currentSeconds}s)',
            );
          }

          await youtubeController!.playVideo();
        }

        // Reset controls timer when user interacts
        _resetControlsTimer();
      } catch (e) {
        print('Error toggling play/pause: $e');
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
        print('Error seeking to position: $e');
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
        print('Error seeking relative: $e');
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
      );

      // Save to history when user starts watching (no auto-update)
      _historyService.addOrUpdateVideo(currentVideo!);
    }
  }

  void goBack() {
    print('VideoPlayerController.goBack() called');
    print('Current route: ${Get.currentRoute}');

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
