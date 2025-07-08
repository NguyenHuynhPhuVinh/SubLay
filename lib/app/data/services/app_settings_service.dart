import 'package:get/get.dart';
import 'package:hive/hive.dart';

enum VideoOrientation {
  portrait,
  landscape,
}

class AppSettingsService extends GetxService {
  static const String _boxName = 'app_settings';
  static const String _videoOrientationKey = 'video_orientation';

  late Box _settingsBox;

  // Observable settings
  final videoOrientation = VideoOrientation.landscape.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initHive();
    _loadSettings();
  }

  Future<void> _initHive() async {
    try {
      _settingsBox = await Hive.openBox(_boxName);
    } catch (e) {
      print('Error opening settings box: $e');
      await Hive.deleteBoxFromDisk(_boxName);
      _settingsBox = await Hive.openBox(_boxName);
    }
  }

  void _loadSettings() {
    // Load video orientation
    final orientationIndex = _settingsBox.get(_videoOrientationKey, defaultValue: VideoOrientation.landscape.index);
    videoOrientation.value = VideoOrientation.values[orientationIndex];
  }

  // Video orientation settings
  Future<void> setVideoOrientation(VideoOrientation orientation) async {
    videoOrientation.value = orientation;
    await _settingsBox.put(_videoOrientationKey, orientation.index);
  }

  // Helper methods
  String get videoOrientationText {
    switch (videoOrientation.value) {
      case VideoOrientation.portrait:
        return 'Dọc (Portrait)';
      case VideoOrientation.landscape:
        return 'Ngang (Landscape)';
    }
  }

  bool get isPortraitMode => videoOrientation.value == VideoOrientation.portrait;
  bool get isLandscapeMode => videoOrientation.value == VideoOrientation.landscape;

  @override
  void onClose() {
    _settingsBox.close();
    super.onClose();
  }
}
