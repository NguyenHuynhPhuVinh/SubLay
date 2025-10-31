import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/srt_parser.dart';
import '../../../core/services/subtitle_settings_service.dart';

class SubtitleEditorController extends GetxController {
  // Services
  final SubtitleSettingsService _subtitleSettings =
      Get.find<SubtitleSettingsService>();

  // Text controllers
  final srtTextController = TextEditingController();

  // Observable variables
  final srtContent = ''.obs;
  final isLoading = false.obs;

  // Subtitle data
  List<SrtSubtitle> subtitles = [];
  final hasValidSubtitles = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to text changes
    srtTextController.addListener(() {
      srtContent.value = srtTextController.text;
      _parseSubtitles();
    });
  }

  @override
  void onClose() {
    srtTextController.dispose();
    super.onClose();
  }

  // Parse SRT content
  void _parseSubtitles() {
    if (srtContent.value.trim().isEmpty) {
      subtitles.clear();
      hasValidSubtitles.value = false;
      return;
    }

    try {
      subtitles = SrtParser.parse(srtContent.value);
      hasValidSubtitles.value = subtitles.isNotEmpty;
    } catch (e) {
      subtitles.clear();
      hasValidSubtitles.value = false;
    }
  }

  // Adjust subtitle timing offset (delegates to service)
  void adjustOffset(int milliseconds) {
    _subtitleSettings.adjustOffset(milliseconds);
  }

  // Reset offset to 0 (delegates to service)
  void resetOffset() {
    _subtitleSettings.resetOffset();
  }

  // Get current offset from service
  int get currentOffset => _subtitleSettings.subtitleOffset.value;

  // Get offset string for UI
  String get offsetString => _subtitleSettings.offsetString;

  // Get offset color for UI
  int get offsetColor => _subtitleSettings.offsetColor;
}
