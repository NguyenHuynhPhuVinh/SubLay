import 'package:get/get.dart';
import '../modules/main_screen/bindings/main_screen_binding.dart';
import '../modules/main_screen/views/main_screen_view.dart';
import '../modules/video_input/bindings/video_input_binding.dart';
import '../modules/video_input/views/video_input_view.dart';
import '../modules/video_player/bindings/video_player_binding.dart';
import '../modules/video_player/views/video_player_view.dart';
import '../modules/subtitle_editor/bindings/subtitle_editor_binding.dart';
import '../modules/subtitle_editor/views/subtitle_editor_view.dart';
import '../modules/prompt_manager/bindings/prompt_manager_binding.dart';
import '../modules/prompt_manager/views/prompt_manager_view.dart';
import '../modules/app_settings/bindings/app_settings_binding.dart';
import '../modules/app_settings/views/app_settings_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.MAIN_SCREEN;

  static final routes = [
    GetPage(
      name: _Paths.MAIN_SCREEN,
      page: () => const MainScreenView(),
      binding: MainScreenBinding(),
    ),
    GetPage(
      name: _Paths.VIDEO_INPUT,
      page: () => const VideoInputView(),
      binding: VideoInputBinding(),
    ),
    GetPage(
      name: _Paths.VIDEO_PLAYER,
      page: () => const VideoPlayerView(),
      binding: VideoPlayerBinding(),
    ),
    GetPage(
      name: _Paths.SUBTITLE_EDITOR,
      page: () => const SubtitleEditorView(),
      binding: SubtitleEditorBinding(),
    ),
    GetPage(
      name: _Paths.PROMPT_MANAGER,
      page: () => const PromptManagerView(),
      binding: PromptManagerBinding(),
    ),
    GetPage(
      name: _Paths.APP_SETTINGS,
      page: () => const AppSettingsView(),
      binding: AppSettingsBinding(),
    ),
  ];
}
