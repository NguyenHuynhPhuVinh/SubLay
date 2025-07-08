import 'package:get/get.dart';

class MainScreenController extends GetxController {
  // Observable cho current tab index
  final currentIndex = 0.obs;
  
  // Danh sách các tab cho DuTupSRT
  final List<String> tabTitles = [
    'Video Input',
    'Player',
    'Editor',
    'Recent',
    'Settings'
  ];

  // Thay đổi tab
  void changeTabIndex(int index) {
    currentIndex.value = index;
  }

  // Navigate to video player (outside of tab navigation)
  void navigateToVideoPlayer({
    required String videoId,
    required String youtubeUrl,
    required String srtContent,
    required String srtFileName,
  }) {
    Get.toNamed('/video_player', arguments: {
      'videoId': videoId,
      'youtubeUrl': youtubeUrl,
      'srtContent': srtContent,
      'srtFileName': srtFileName,
    });
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
    super.onClose();
  }
}
