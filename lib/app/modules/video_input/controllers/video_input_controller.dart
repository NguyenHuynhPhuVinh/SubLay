import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/utils/srt_parser.dart';

class VideoInputController extends GetxController {
  // Observable variables
  final youtubeUrl = ''.obs;
  final srtContent = ''.obs;
  final srtFileName = ''.obs;
  final isLoading = false.obs;
  final isValidUrl = false.obs;

  // Text controllers
  final urlController = TextEditingController();
  final srtTextController = TextEditingController();

  // Validate YouTube URL
  void validateYouTubeUrl(String url) {
    youtubeUrl.value = url;

    // Basic YouTube URL validation
    final youtubeRegex = RegExp(
      r'^(https?\:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.+',
      caseSensitive: false,
    );

    isValidUrl.value = youtubeRegex.hasMatch(url) && url.isNotEmpty;
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

  // Validate and prepare for video player
  bool canPlayVideo() {
    final hasValidUrl = isValidUrl.value;
    final hasSrtContent = srtContent.value.trim().isNotEmpty;

    print(
      'DEBUG - canPlayVideo: URL valid: $hasValidUrl, SRT content: ${srtContent.value.length} chars',
    );

    return hasValidUrl && hasSrtContent;
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

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    urlController.dispose();
    srtTextController.dispose();
    super.onClose();
  }
}
