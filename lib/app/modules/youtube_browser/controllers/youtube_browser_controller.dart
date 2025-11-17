import 'dart:async';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/utils/srt_parser.dart';

class YoutubeBrowserController extends GetxController {
  late WebViewController webViewController;
  final isLoading = true.obs;
  final currentUrl = 'https://www.youtube.com'.obs;
  final isVideoPage = false.obs;
  final showSubtitleButton = false.obs;
  final showSubtitlePanel = false.obs;
  final isFullScreen = false.obs;
  final isPlayingWithSubtitles = false.obs;

  // SRT data
  final srtContent = ''.obs;
  final srtFileName = ''.obs;
  final srtValidationResult = Rxn<SrtValidationResult>();
  final srtTextController = TextEditingController();

  // Subtitle display
  List<SrtSubtitle> subtitles = [];
  final currentSubtitle = ''.obs;
  Timer? _subtitleTimer;
  DateTime? _videoStartTime;

  // Video data
  String? currentVideoId;
  String? currentVideoUrl;

  @override
  void onInit() {
    super.onInit();
    _initializeWebView();
  }

  void _initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            isLoading.value = true;
            currentUrl.value = url;
            _checkIfVideoPage(url);
          },
          onPageFinished: (String url) {
            isLoading.value = false;
            _checkIfVideoPage(url);
          },
          onWebResourceError: (WebResourceError error) {
            Get.snackbar(
              'Lỗi',
              'Không thể tải trang: ${error.description}',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.youtube.com'));
  }

  void _checkIfVideoPage(String url) {
    final isVideo =
        url.contains('youtube.com/watch?v=') || url.contains('youtu.be/');
    isVideoPage.value = isVideo;
    showSubtitleButton.value = isVideo;

    if (isVideo) {
      currentVideoId = _extractVideoId(url);
      currentVideoUrl = url;
    } else {
      currentVideoId = null;
      currentVideoUrl = null;
      // Stop subtitles if navigating away from video
      if (isPlayingWithSubtitles.value) {
        stopSubtitles();
      }
    }
  }

  String? _extractVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  void toggleSubtitlePanel() {
    showSubtitlePanel.value = !showSubtitlePanel.value;
  }

  Future<void> pickSrtFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['srt', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        srtFileName.value = file.name;

        if (file.bytes != null) {
          final content = String.fromCharCodes(file.bytes!);
          srtContent.value = content;
          srtTextController.text = content;
          _validateSrtContent(content);
        } else if (file.path != null) {
          final fileContent = await File(file.path!).readAsString();
          srtContent.value = fileContent;
          srtTextController.text = fileContent;
          _validateSrtContent(fileContent);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể đọc file SRT: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  void updateSrtContent(String content) {
    srtContent.value = content;
    _validateSrtContent(content);
  }

  void _validateSrtContent(String content) {
    if (content.trim().isEmpty) {
      srtValidationResult.value = null;
      return;
    }
    final result = SrtParser.validateAndFixSrt(content);
    srtValidationResult.value = result;
  }

  void applyAutoFix() {
    final result = srtValidationResult.value;
    if (result?.fixedContent != null) {
      srtContent.value = result!.fixedContent!;
      srtTextController.text = result.fixedContent!;
      _validateSrtContent(result.fixedContent!);
    }
  }

  void clearSrtContent() {
    srtContent.value = '';
    srtFileName.value = '';
    srtTextController.clear();
    srtValidationResult.value = null;
  }

  void activateSubtitles() {
    if (srtContent.value.isNotEmpty) {
      // Parse SRT content
      subtitles = SrtParser.parse(srtContent.value);

      // Close panel
      showSubtitlePanel.value = false;

      // Start subtitle display
      isPlayingWithSubtitles.value = true;
      _videoStartTime = DateTime.now();
      _startSubtitleTimer();

      // Enter fullscreen landscape
      isFullScreen.value = true;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

      Get.snackbar(
        'Phụ đề đã kích hoạt',
        'Phụ đề sẽ hiển thị trên video',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Thiếu thông tin',
        'Vui lòng chọn file SRT hoặc dán nội dung phụ đề',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  void _startSubtitleTimer() {
    _subtitleTimer?.cancel();
    _subtitleTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_videoStartTime != null && subtitles.isNotEmpty) {
        final elapsed = DateTime.now().difference(_videoStartTime!);
        _updateCurrentSubtitle(elapsed);
      }
    });
  }

  void _updateCurrentSubtitle(Duration elapsed) {
    String newSubtitle = '';
    for (final subtitle in subtitles) {
      if (elapsed >= subtitle.startTime && elapsed <= subtitle.endTime) {
        newSubtitle = subtitle.text;
        break;
      }
    }

    if (currentSubtitle.value != newSubtitle) {
      currentSubtitle.value = newSubtitle;
    }
  }

  void stopSubtitles() {
    isPlayingWithSubtitles.value = false;
    currentSubtitle.value = '';
    _subtitleTimer?.cancel();
    _videoStartTime = null;

    // Exit fullscreen
    isFullScreen.value = false;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void toggleFullScreen() {
    if (isFullScreen.value) {
      // Exit fullscreen
      isFullScreen.value = false;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      // Enter fullscreen
      isFullScreen.value = true;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }

  void goBack() async {
    if (await webViewController.canGoBack()) {
      webViewController.goBack();
    }
  }

  void goForward() async {
    if (await webViewController.canGoForward()) {
      webViewController.goForward();
    }
  }

  void reload() {
    webViewController.reload();
  }

  void goHome() {
    webViewController.loadRequest(Uri.parse('https://www.youtube.com'));
  }

  @override
  void onClose() {
    _subtitleTimer?.cancel();
    srtTextController.dispose();
    // Restore portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.onClose();
  }
}
