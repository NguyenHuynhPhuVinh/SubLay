import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../data/services/video_history_service.dart';
import '../../../data/models/video_with_subtitle.dart';

class RecentVideosController extends GetxController {
  final VideoHistoryService _historyService = Get.find<VideoHistoryService>();

  // Observable variables
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final filteredVideos = <VideoWithSubtitle>[].obs;

  // Text controller for search
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadVideos();

    // Listen to history service changes
    ever(_historyService.videos, (_) => _filterVideos());
  }

  void _loadVideos() {
    isLoading.value = true;
    _filterVideos();
    isLoading.value = false;
  }

  void _filterVideos() {
    if (searchQuery.value.isEmpty) {
      filteredVideos.value = _historyService.videos;
    } else {
      filteredVideos.value = _historyService.searchVideos(searchQuery.value);
    }
  }

  void searchVideos(String query) {
    searchQuery.value = query;
    _filterVideos();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _filterVideos();
  }

  Future<void> removeVideo(VideoWithSubtitle video) async {
    try {
      await _historyService.removeVideo(video.videoId);
      Get.snackbar(
        'Đã xóa',
        'Video đã được xóa khỏi lịch sử',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể xóa video: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> clearAllHistory() async {
    try {
      await _historyService.clearHistory();
      Get.snackbar(
        'Đã xóa',
        'Tất cả lịch sử đã được xóa',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể xóa lịch sử: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void playVideo(VideoWithSubtitle video) {
    // Navigate to video player with video data
    Get.toNamed('/video_player', arguments: {
      'videoId': video.videoId,
      'youtubeUrl': video.youtubeUrl,
      'srtContent': video.srtContent,
      'srtFileName': video.srtFileName,
    });
  }

  // Get statistics
  Map<String, dynamic> get statistics => _historyService.statistics;

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
