part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const mainScreen = _Paths.mainScreen;
  static const videoInput = _Paths.videoInput;
  static const videoPlayer = _Paths.videoPlayer;
  static const subtitleEditor = _Paths.subtitleEditor;
  static const promptManager = _Paths.promptManager;
  static const appSettings = _Paths.appSettings;
  static const youtubeBrowser = _Paths.youtubeBrowser;
}

abstract class _Paths {
  _Paths._();
  static const mainScreen = '/main_screen';
  static const videoInput = '/video_input';
  static const videoPlayer = '/video_player';
  static const subtitleEditor = '/subtitle_editor';
  static const promptManager = '/prompt_manager';
  static const appSettings = '/app_settings';
  static const youtubeBrowser = '/youtube_browser';
}
