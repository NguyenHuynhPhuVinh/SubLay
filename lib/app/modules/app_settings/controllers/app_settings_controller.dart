import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../data/services/app_settings_service.dart';

class AppSettingsController extends GetxController {
  final AppSettingsService _settingsService = Get.find<AppSettingsService>();

  // Text controllers for time conversion
  final minutesController = TextEditingController();
  final secondsController = TextEditingController();
  final totalSecondsController = TextEditingController();

  // Observable for conversion results
  final convertedSeconds = 0.obs;
  final convertedMinutes = 0.obs;
  final convertedSecondsRemainder = 0.obs;

  // Getter để truy cập settings service
  AppSettingsService get settingsService => _settingsService;

  // Method để thay đổi video orientation
  Future<void> changeVideoOrientation(VideoOrientation orientation) async {
    await _settingsService.setVideoOrientation(orientation);
  }

  // Convert minutes:seconds to total seconds
  void convertToSeconds() {
    try {
      final minutes = int.tryParse(minutesController.text) ?? 0;
      final seconds = int.tryParse(secondsController.text) ?? 0;

      if (seconds >= 60) {
        Get.snackbar(
          'Lỗi',
          'Giây không được vượt quá 59',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        return;
      }

      final totalSeconds = (minutes * 60) + seconds;
      convertedSeconds.value = totalSeconds;
      totalSecondsController.text = totalSeconds.toString();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập số hợp lệ',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  // Convert total seconds to minutes:seconds
  void convertToMinutesSeconds() {
    try {
      final totalSeconds = int.tryParse(totalSecondsController.text) ?? 0;

      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;

      convertedMinutes.value = minutes;
      convertedSecondsRemainder.value = seconds;
      minutesController.text = minutes.toString();
      secondsController.text = seconds.toString();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập số hợp lệ',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  // Clear all fields
  void clearTimeConversion() {
    minutesController.clear();
    secondsController.clear();
    totalSecondsController.clear();
    convertedSeconds.value = 0;
    convertedMinutes.value = 0;
    convertedSecondsRemainder.value = 0;
  }

  @override
  void onClose() {
    minutesController.dispose();
    secondsController.dispose();
    totalSecondsController.dispose();
    super.onClose();
  }
}
