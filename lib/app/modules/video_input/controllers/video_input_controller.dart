import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/utils/srt_parser.dart';
import '../../../data/services/video_history_service.dart';
import '../../../data/models/video_with_subtitle.dart';

class VideoInputController extends GetxController {
  // Services
  late VideoHistoryService _historyService;
  final Dio _dio = Dio();

  // Observable variables
  final youtubeUrl = ''.obs;
  final videoTitle = ''.obs;
  final srtContent = ''.obs;
  final srtFileName = ''.obs;
  final isLoading = false.obs;
  final isValidUrl = false.obs;
  final showVideoList = true.obs;
  final searchQuery = ''.obs;
  final isLoadingVideoInfo = false.obs;

  // Text controllers
  final urlController = TextEditingController();
  final titleController = TextEditingController();
  final srtTextController = TextEditingController();
  final searchController = TextEditingController();

  // Video management
  List<VideoWithSubtitle> get savedVideos => _historyService.videos;
  List<VideoWithSubtitle> get filteredVideos {
    if (searchQuery.value.isEmpty) return savedVideos;
    return _historyService.searchVideos(searchQuery.value);
  }

  // Validate YouTube URL
  void validateYouTubeUrl(String url) {
    youtubeUrl.value = url;

    // Basic YouTube URL validation
    final youtubeRegex = RegExp(
      r'^(https?\:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.+',
      caseSensitive: false,
    );

    isValidUrl.value = youtubeRegex.hasMatch(url) && url.isNotEmpty;

    // Fetch video info if URL is valid
    if (isValidUrl.value) {
      _fetchVideoInfo(url);
    } else {
      videoTitle.value = '';
      titleController.clear();
    }
  }

  // Fetch video information from YouTube
  Future<void> _fetchVideoInfo(String url) async {
    final videoId = extractVideoId(url);
    if (videoId == null) return;

    try {
      isLoadingVideoInfo.value = true;

      // Simulate fetching video title (in real app, you would use YouTube API)
      // For now, we'll extract from the URL or use a placeholder
      await Future.delayed(const Duration(milliseconds: 500));

      // Try to get title from YouTube oEmbed API (simple approach)
      final title = await _getVideoTitleFromOEmbed(url) ?? 'YouTube Video';

      videoTitle.value = title;
      titleController.text = title;

    } catch (e) {
      print('Error fetching video info: $e');
      videoTitle.value = 'YouTube Video';
      titleController.text = 'YouTube Video';
    } finally {
      isLoadingVideoInfo.value = false;
    }
  }

  // Get video title from YouTube oEmbed API
  Future<String?> _getVideoTitleFromOEmbed(String url) async {
    try {
      // Use YouTube oEmbed API to get video title
      final oEmbedUrl = 'https://www.youtube.com/oembed?url=${Uri.encodeComponent(url)}&format=json';

      final response = await _dio.get(oEmbedUrl);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('title')) {
          return data['title'] as String;
        }
      }

      // Fallback if API fails
      final videoId = extractVideoId(url);
      if (videoId != null) {
        return 'YouTube Video ($videoId)';
      }

    } catch (e) {
      print('Error getting video title from oEmbed: $e');

      // Fallback if API fails
      final videoId = extractVideoId(url);
      if (videoId != null) {
        return 'YouTube Video ($videoId)';
      }
    }
    return null;
  }

  // Extract YouTube video ID from URL
  String? extractVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );

    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  // Pick SRT file
  Future<void> pickSrtFile() async {
    try {
      isLoading.value = true;

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['srt', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        srtFileName.value = file.name;

        // Read file content
        if (file.bytes != null) {
          final content = String.fromCharCodes(file.bytes!);
          srtContent.value = content;
          srtTextController.text = content;
          _validateSrtContent(content);
          print('DEBUG - File loaded: ${content.length} characters');
        } else if (file.path != null) {
          // Fallback: read from file path
          try {
            final fileContent = await File(file.path!).readAsString();
            srtContent.value = fileContent;
            srtTextController.text = fileContent;
            _validateSrtContent(fileContent);
            print(
              'DEBUG - File loaded from path: ${fileContent.length} characters',
            );
          } catch (e) {
            print('DEBUG - Error reading file from path: $e');
          }
        }

        Get.snackbar(
          'Thành công',
          'Đã tải file SRT: ${file.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể đọc file SRT: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // SRT validation result
  final srtValidationResult = Rxn<SrtValidationResult>();

  // Update SRT content from text input
  void updateSrtContent(String content) {
    srtContent.value = content;
    _validateSrtContent(content);
  }

  // Validate SRT content
  void _validateSrtContent(String content) {
    if (content.trim().isEmpty) {
      srtValidationResult.value = null;
      return;
    }

    // Perform validation and auto-fix
    final result = SrtParser.validateAndFixSrt(content);
    srtValidationResult.value = result;

    // Show summary notification
    if (result.formatFixesCount > 0) {
      Get.snackbar(
        'Phát hiện lỗi định dạng',
        'Đã tìm thấy ${result.formatFixesCount} lỗi định dạng có thể sửa tự động',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else if (result.timelineErrors.isNotEmpty ||
        result.silenceGaps.isNotEmpty) {
      Get.snackbar(
        'Cảnh báo',
        'Phát hiện ${result.timelineErrors.length} lỗi timeline và ${result.silenceGaps.length} khoảng lặng',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Apply auto-fix for format errors
  void applyAutoFix() {
    final result = srtValidationResult.value;
    if (result?.fixedContent != null) {
      srtContent.value = result!.fixedContent!;
      srtTextController.text = result.fixedContent!;

      // Re-validate after applying fix
      _validateSrtContent(result.fixedContent!);

      Get.snackbar(
        'Thành công',
        'Đã áp dụng sửa lỗi tự động cho ${result.formatFixesCount} lỗi định dạng',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }



  // Clear SRT content
  void clearSrtContent() {
    srtContent.value = '';
    srtFileName.value = '';
    srtTextController.clear();
    srtValidationResult.value = null;
  }

  // Clear YouTube URL
  void clearYouTubeUrl() {
    youtubeUrl.value = '';
    urlController.clear();
    isValidUrl.value = false;
  }

  // Validate and prepare for video player
  bool canPlayVideo() {
    final hasValidUrl = isValidUrl.value;
    final hasSrtContent = srtContent.value.trim().isNotEmpty;

    print(
      'DEBUG - canPlayVideo: URL valid: $hasValidUrl, SRT content: ${srtContent.value.length} chars',
    );

    return hasValidUrl && hasSrtContent;
  }

  // Save video with subtitle
  Future<void> saveVideoWithSubtitle() async {
    if (canPlayVideo()) {
      final videoId = extractVideoId(youtubeUrl.value);
      if (videoId != null) {
        try {
          isLoading.value = true;

          // Create video model
          final video = VideoWithSubtitle.fromInput(
            videoId: videoId,
            youtubeUrl: youtubeUrl.value,
            srtContent: srtContent.value,
            srtFileName: srtFileName.value.isNotEmpty
                ? srtFileName.value
                : 'Phụ đề tùy chỉnh',
            title: titleController.text.isNotEmpty
                ? titleController.text
                : videoTitle.value.isNotEmpty
                    ? videoTitle.value
                    : 'YouTube Video',
          );

          // Save to history service
          await _historyService.addOrUpdateVideo(video);

          // Clear form and switch back to list view
          _clearForm();
          showVideoList.value = true;

          Get.snackbar(
            'Thành công',
            'Đã lưu video vào danh sách',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            'Lỗi',
            'Không thể lưu video: $e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
        } finally {
          isLoading.value = false;
        }
      }
    }
  }

  // Navigate to video player
  void playVideoWithSubtitles() {
    if (canPlayVideo()) {
      final videoId = extractVideoId(youtubeUrl.value);
      if (videoId != null) {
        // Navigate to video player with data
        final arguments = {
          'videoId': videoId,
          'youtubeUrl': youtubeUrl.value,
          'srtContent': srtContent.value,
          'srtFileName': srtFileName.value,
        };

        print('DEBUG - Navigating to video player with arguments: $arguments');

        // Navigate to video player as separate screen (not tab)
        Get.toNamed('/video_player', arguments: arguments);
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể trích xuất ID video từ URL',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } else {
      Get.snackbar(
        'Thiếu thông tin',
        'Vui lòng nhập URL YouTube và nội dung SRT',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // Play saved video
  void playSavedVideo(VideoWithSubtitle video) {
    final arguments = {
      'videoId': video.videoId,
      'youtubeUrl': video.youtubeUrl,
      'srtContent': video.srtContent,
      'srtFileName': video.srtFileName,
    };
    Get.toNamed('/video_player', arguments: arguments);
  }

  // Edit saved video
  void editSavedVideo(VideoWithSubtitle video) {
    youtubeUrl.value = video.youtubeUrl;
    urlController.text = video.youtubeUrl;
    videoTitle.value = video.title;
    titleController.text = video.title;
    srtContent.value = video.srtContent;
    srtTextController.text = video.srtContent;
    srtFileName.value = video.srtFileName;

    validateYouTubeUrl(video.youtubeUrl);
    _validateSrtContent(video.srtContent);

    showVideoList.value = false; // Switch to input form
  }

  // Delete saved video
  Future<void> deleteSavedVideo(VideoWithSubtitle video) async {
    try {
      await _historyService.removeVideo(video.videoId);
      Get.snackbar(
        'Thành công',
        'Đã xóa video khỏi danh sách',
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

  // Search videos
  void searchVideos(String query) {
    searchQuery.value = query;
  }

  // Clear search
  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();
  }

  // Toggle between video list and input form
  void toggleView() {
    showVideoList.value = !showVideoList.value;
    if (showVideoList.value) {
      _clearForm();
    }
  }

  // Clear form
  void _clearForm() {
    clearYouTubeUrl();
    clearSrtContent();
    videoTitle.value = '';
    titleController.clear();
  }

  @override
  void onInit() {
    super.onInit();
    _historyService = Get.find<VideoHistoryService>();

    // Listen to search input
    searchController.addListener(() {
      searchVideos(searchController.text);
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    urlController.dispose();
    titleController.dispose();
    srtTextController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
