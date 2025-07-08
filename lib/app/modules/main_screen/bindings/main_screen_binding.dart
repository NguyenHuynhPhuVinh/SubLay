import 'package:get/get.dart';
import '../controllers/main_screen_controller.dart';
import '../../video_input/controllers/video_input_controller.dart';
import '../../video_player/controllers/video_player_controller.dart';
import '../../subtitle_editor/controllers/subtitle_editor_controller.dart';
import '../../recent_videos/controllers/recent_videos_controller.dart';
import '../../app_settings/controllers/app_settings_controller.dart';
import '../../../data/services/video_history_service.dart';

class MainScreenBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure VideoHistoryService is available
    if (!Get.isRegistered<VideoHistoryService>()) {
      Get.put(VideoHistoryService(), permanent: true);
    }

    Get.lazyPut<MainScreenController>(() => MainScreenController());

    // Đăng ký tất cả controller cho các tab trong MainScreenView
    Get.lazyPut<VideoInputController>(() => VideoInputController());

    Get.lazyPut<VideoPlayerController>(() => VideoPlayerController());

    Get.lazyPut<SubtitleEditorController>(() => SubtitleEditorController());

    Get.lazyPut<RecentVideosController>(() => RecentVideosController());

    Get.lazyPut<AppSettingsController>(() => AppSettingsController());
  }
}
