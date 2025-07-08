import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/material.dart';
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
  final isFullScreen = false.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  final isPlaying = false.obs;
  final showControls = true.obs;
  final currentSubtitle = ''.obs;

  // Subtitle data
  List<SrtSubtitle> subtitles = [];
  String srtContent = '';
  String videoId = '';
  String youtubeUrl = '';
  String srtFileName = '';

  // Current video model
  VideoWithSubtitle? currentVideo;

  @override
  void onInit() {
    super.onInit();

    // Get arguments from navigation
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      videoId = args['videoId'] ?? '';
      youtubeUrl = args['youtubeUrl'] ?? '';
      srtContent = args['srtContent'] ?? '';
      srtFileName = args['srtFileName'] ?? '';

      _initializePlayer();
      _parseSrtContent();
      _createVideoModel();
    }
  }

  void _initializePlayer() {
    if (videoId.isNotEmpty) {
      youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false, // Disable YouTube captions to use our SRT
          loop: false,
          forceHD: false,
        ),
      );

      youtubeController!.addListener(_playerListener);
      _startAutoSave();
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
    if (srtContent.isNotEmpty) {
      try {
        // Parse SRT content using custom parser
        subtitles = SrtParser.parse(srtContent);

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
    isFullScreen.value = !isFullScreen.value;
  }

  void toggleControls() {
    showControls.value = !showControls.value;
  }

  void goBack() {
    _saveVideoProgress();
    Get.back();
  }

  void _createVideoModel() {
    if (videoId.isNotEmpty) {
      currentVideo = VideoWithSubtitle.fromInput(
        videoId: videoId,
        youtubeUrl: youtubeUrl,
        srtContent: srtContent,
        srtFileName: srtFileName,
      );

      // Save to history
      _historyService.addOrUpdateVideo(currentVideo!);
    }
  }

  void _saveVideoProgress() {
    if (currentVideo != null) {
      currentVideo!.updateProgress(currentPosition.value, totalDuration.value);
      _historyService.addOrUpdateVideo(currentVideo!);
    }
  }

  // Auto-save progress every 10 seconds
  void _startAutoSave() {
    Stream.periodic(const Duration(seconds: 10)).listen((_) {
      if (isPlaying.value && currentVideo != null) {
        _saveVideoProgress();
      }
    });
  }

  @override
  void onClose() {
    youtubeController?.removeListener(_playerListener);
    youtubeController?.dispose();
    super.onClose();
  }
}
