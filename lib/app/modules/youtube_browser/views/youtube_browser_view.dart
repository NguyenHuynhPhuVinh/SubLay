import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../controllers/youtube_browser_controller.dart';
import '../../video_input/widgets/srt_validation_widget.dart';

class YoutubeBrowserView extends GetView<YoutubeBrowserController> {
  const YoutubeBrowserView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isFullScreen.value) {
        return _buildFullScreenView();
      }
      return _buildNormalView();
    });
  }

  Widget _buildNormalView() {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isLoading.value ? 'Đang tải...' : 'YouTube',
            style: TextStyle(fontSize: 16.sp),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.arrow_left_2),
            onPressed: controller.goBack,
            tooltip: 'Quay lại',
          ),
          IconButton(
            icon: const Icon(Iconsax.arrow_right_3),
            onPressed: controller.goForward,
            tooltip: 'Tiến tới',
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: controller.reload,
            tooltip: 'Tải lại',
          ),
          IconButton(
            icon: const Icon(Iconsax.home),
            onPressed: controller.goHome,
            tooltip: 'Trang chủ YouTube',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller.webViewController),
          Obx(
            () => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          ),

          // Floating subtitle button
          Obx(
            () =>
                controller.showSubtitleButton.value &&
                    !controller.isPlayingWithSubtitles.value
                ? Positioned(
                    bottom: 20.h,
                    right: 20.w,
                    child: FloatingActionButton(
                      onPressed: controller.toggleSubtitlePanel,
                      backgroundColor: Colors.red,
                      child: const Icon(Iconsax.subtitle, color: Colors.white),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Stop subtitle button when playing
          Obx(
            () => controller.isPlayingWithSubtitles.value
                ? Positioned(
                    bottom: 20.h,
                    right: 20.w,
                    child: FloatingActionButton(
                      onPressed: controller.stopSubtitles,
                      backgroundColor: Colors.orange,
                      child: const Icon(Iconsax.stop, color: Colors.white),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Subtitle panel
          Obx(
            () => controller.showSubtitlePanel.value
                ? _buildSubtitlePanel()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // WebView fullscreen
          Positioned.fill(
            child: WebViewWidget(controller: controller.webViewController),
          ),

          // Subtitle overlay
          Obx(() {
            final subtitle = controller.currentSubtitle.value;
            if (subtitle.isEmpty) return const SizedBox.shrink();

            final lineCount = '\n'.allMatches(subtitle).length + 1;
            final bottomPosition = _getSubtitleBottomPosition(lineCount);

            return Positioned(
              bottom: bottomPosition,
              left: 40,
              right: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outline
                  AutoSizeText(
                    subtitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      letterSpacing: 0.5,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3.0
                        ..strokeJoin = StrokeJoin.round
                        ..strokeCap = StrokeCap.round
                        ..color = Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    minFontSize: 12,
                    maxFontSize: 22,
                    overflow: TextOverflow.ellipsis,
                    wrapWords: true,
                  ),
                  // Text
                  AutoSizeText(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    minFontSize: 12,
                    maxFontSize: 22,
                    overflow: TextOverflow.ellipsis,
                    wrapWords: true,
                  ),
                ],
              ),
            );
          }),

          // Exit fullscreen button
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              onPressed: controller.stopSubtitles,
              icon: const Icon(Iconsax.close_square, color: Colors.white),
              iconSize: 32,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getSubtitleBottomPosition(int lineCount) {
    switch (lineCount) {
      case 1:
        return 40.0;
      case 2:
        return 50.0;
      case 3:
        return 60.0;
      default:
        return 70.0;
    }
  }

  Widget _buildSubtitlePanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: Get.height * 0.6,
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10.r,
              offset: Offset(0, -2.h),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thêm phụ đề',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.close_circle),
                    onPressed: controller.toggleSubtitlePanel,
                  ),
                ],
              ),
            ),

            Divider(height: 1.h),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pick file button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: controller.pickSrtFile,
                            icon: const Icon(Iconsax.document_upload),
                            label: const Text('Chọn file SRT'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Obx(
                          () => controller.srtContent.value.isNotEmpty
                              ? IconButton(
                                  onPressed: controller.clearSrtContent,
                                  icon: const Icon(Iconsax.trash),
                                  color: Colors.red,
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // File name display
                    Obx(
                      () => controller.srtFileName.value.isNotEmpty
                          ? Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Iconsax.document,
                                    size: 16.r,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      controller.srtFileName.value,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(),
                    ),

                    SizedBox(height: 12.h),

                    // Or paste text
                    Text(
                      'Hoặc dán nội dung SRT:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    // Text field
                    TextField(
                      controller: controller.srtTextController,
                      onChanged: controller.updateSrtContent,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText:
                            'Dán nội dung SRT vào đây...\n\n1\n00:00:01,000 --> 00:00:04,000\nHello World!',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    // Validation widget
                    Obx(
                      () => controller.srtValidationResult.value != null
                          ? SrtValidationWidget(
                              validationResult:
                                  controller.srtValidationResult.value!,
                              onFixApplied: controller.applyAutoFix,
                            )
                          : const SizedBox(),
                    ),

                    SizedBox(height: 16.h),

                    // Activate button
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.srtContent.value.isNotEmpty
                              ? controller.activateSubtitles
                              : null,
                          icon: const Icon(Iconsax.tick_circle),
                          label: Text(
                            'Kích hoạt phụ đề',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                controller.srtContent.value.isNotEmpty
                                ? Colors.green
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
