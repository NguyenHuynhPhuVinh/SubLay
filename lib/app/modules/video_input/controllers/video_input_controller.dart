import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/utils/srt_parser.dart';
import '../../main_screen/controllers/main_screen_controller.dart';
import '../../video_player/controllers/video_player_controller.dart';

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
          srtContent.value = String.fromCharCodes(file.bytes!);
          srtTextController.text = srtContent.value;
          print('DEBUG - File loaded: ${srtContent.value.length} characters');
        } else if (file.path != null) {
          // Fallback: read from file path
          try {
            final fileContent = await File(file.path!).readAsString();
            srtContent.value = fileContent;
            srtTextController.text = srtContent.value;
            print('DEBUG - File loaded from path: ${srtContent.value.length} characters');
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
  
  // Update SRT content from text input
  void updateSrtContent(String content) {
    srtContent.value = content;

    // Validate SRT content
    if (content.isNotEmpty && !SrtParser.isValidSrtContent(content)) {
      Get.snackbar(
        'Cảnh báo',
        'Nội dung SRT có thể không đúng định dạng',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
  
  // Clear SRT content
  void clearSrtContent() {
    srtContent.value = '';
    srtFileName.value = '';
    srtTextController.clear();
  }
  
  // Validate and prepare for video player
  bool canPlayVideo() {
    final hasValidUrl = isValidUrl.value;
    final hasSrtContent = srtContent.value.trim().isNotEmpty;

    print('DEBUG - canPlayVideo: URL valid: $hasValidUrl, SRT content: ${srtContent.value.length} chars');

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
