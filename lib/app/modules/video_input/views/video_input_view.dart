import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../controllers/video_input_controller.dart';
import '../widgets/srt_validation_widget.dart';

class VideoInputView extends GetView<VideoInputController> {
  const VideoInputView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DuTupSRT'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            SizedBox(height: 24.h),
            _buildYouTubeUrlSection(),
            SizedBox(height: 24.h),
            _buildSrtSection(),
            SizedBox(height: 32.h),
            _buildPlayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.video,
            size: 48.r,
            color: Colors.red,
          ),
          SizedBox(height: 12.h),
          AutoSizeText(
            'Xem YouTube với phụ đề SRT',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          SizedBox(height: 8.h),
          AutoSizeText(
            'Dán link YouTube và tải file SRT để xem video với phụ đề tùy chỉnh',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeUrlSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.link,
                size: 20.r,
                color: Colors.red,
              ),
              SizedBox(width: 8.w),
              Text(
                'YouTube URL',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: controller.urlController,
            onChanged: controller.validateYouTubeUrl,
            decoration: InputDecoration(
              hintText: 'Dán link YouTube vào đây...',
              prefixIcon: const Icon(Iconsax.video_play),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Obx(() => controller.isValidUrl.value
              ? Row(
                  children: [
                    Icon(
                      Iconsax.tick_circle,
                      size: 16.r,
                      color: Colors.green,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'URL hợp lệ',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green,
                      ),
                    ),
                  ],
                )
              : controller.youtubeUrl.value.isNotEmpty
                  ? Row(
                      children: [
                        Icon(
                          Iconsax.close_circle,
                          size: 16.r,
                          color: Colors.red,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'URL không hợp lệ',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildSrtSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.document_text,
                size: 20.r,
                color: Colors.blue,
              ),
              SizedBox(width: 8.w),
              Text(
                'Phụ đề SRT',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
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
              Obx(() => controller.srtContent.value.isNotEmpty
                  ? IconButton(
                      onPressed: controller.clearSrtContent,
                      icon: const Icon(Iconsax.trash),
                      color: Colors.red,
                    )
                  : const SizedBox()),
            ],
          ),
          SizedBox(height: 12.h),
          Obx(() => controller.srtFileName.value.isNotEmpty
              ? Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
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
              : const SizedBox()),
          SizedBox(height: 12.h),
          Text(
            'Hoặc dán nội dung SRT:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: controller.srtTextController,
            onChanged: controller.updateSrtContent,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Dán nội dung SRT vào đây...\n\n1\n00:00:01,000 --> 00:00:04,000\nHello World!',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
          // SRT Validation Widget
          Obx(() => controller.srtValidationResult.value != null
              ? SrtValidationWidget(
                  validationResult: controller.srtValidationResult.value!,
                  onFixApplied: controller.applyAutoFix,
                  onOptimizeLineBreaking: controller.optimizeLineBreaking,
                )
              : const SizedBox()),

          // Optimize button when no validation result but has content
          Obx(() => controller.srtValidationResult.value == null &&
                    controller.srtContent.value.trim().isNotEmpty
              ? Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.optimizeLineBreaking,
                    icon: const Icon(Iconsax.text, size: 18),
                    label: const Text('Tối ưu ngắt dòng thông minh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                )
              : const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Obx(() => ElevatedButton.icon(
          onPressed: controller.canPlayVideo() ? controller.playVideoWithSubtitles : null,
          icon: const Icon(Iconsax.play),
          label: Text(
            'Phát video với phụ đề',
            style: TextStyle(fontSize: 16.sp),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.canPlayVideo() ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: controller.canPlayVideo() ? 4 : 0,
          ),
        ));
  }
}
