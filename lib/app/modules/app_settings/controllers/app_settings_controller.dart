import 'package:get/get.dart';
import '../../../data/services/app_settings_service.dart';

class AppSettingsController extends GetxController {
  final AppSettingsService _settingsService = Get.find<AppSettingsService>();

  // Getter để truy cập settings service
  AppSettingsService get settingsService => _settingsService;

  // Method để thay đổi video orientation
  Future<void> changeVideoOrientation(VideoOrientation orientation) async {
    await _settingsService.setVideoOrientation(orientation);
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
