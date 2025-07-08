import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
        final bytes = file.bytes;
        if (bytes != null) {
          srtContent.value = String.fromCharCodes(bytes);
          srtTextController.text = srtContent.value;
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
    return isValidUrl.value && srtContent.value.isNotEmpty;
  }
  
  // Navigate to video player
  void playVideoWithSubtitles() {
    if (canPlayVideo()) {
      final videoId = extractVideoId(youtubeUrl.value);
      if (videoId != null) {
        // Navigate to video player with data
        Get.toNamed('/video_player', arguments: {
          'videoId': videoId,
          'youtubeUrl': youtubeUrl.value,
          'srtContent': srtContent.value,
          'srtFileName': srtFileName.value,
        });
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
