import 'package:get/get.dart';
import '../controllers/main_screen_controller.dart';
import '../../video_input/controllers/video_input_controller.dart';
import '../../video_player/controllers/video_player_controller.dart';
import '../../subtitle_editor/controllers/subtitle_editor_controller.dart';
import '../../prompt_manager/controllers/prompt_manager_controller.dart';
import '../../youtube_browser/controllers/youtube_browser_controller.dart';
import '../../app_settings/controllers/app_settings_controller.dart';
import '../../../data/services/video_service.dart';
import '../../../data/services/prompt_service.dart';

class MainScreenBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure services are available
    if (!Get.isRegistered<VideoService>()) {
      Get.put(VideoService(), permanent: true);
    }
    if (!Get.isRegistered<PromptService>()) {
      Get.put(PromptService(), permanent: true);
    }

    Get.lazyPut<MainScreenController>(() => MainScreenController());

    // Đăng ký tất cả controller cho các tab trong MainScreenView
    Get.lazyPut<VideoInputController>(() => VideoInputController());

    Get.lazyPut<VideoPlayerController>(() => VideoPlayerController());

    Get.lazyPut<SubtitleEditorController>(() => SubtitleEditorController());

    Get.lazyPut<PromptManagerController>(() => PromptManagerController());

    Get.lazyPut<YoutubeBrowserController>(() => YoutubeBrowserController());

    Get.lazyPut<AppSettingsController>(() => AppSettingsController());
  }
}
