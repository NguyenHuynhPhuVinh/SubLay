import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../controllers/video_input_controller.dart';
import '../widgets/srt_validation_widget.dart';
import '../../../data/models/video_with_subtitle.dart';

class VideoInputView extends GetView<VideoInputController> {
  const VideoInputView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Video'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          Obx(
            () => controller.showVideoList.value
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Clear all button
                      if (controller.savedVideos.isNotEmpty)
                        IconButton(
                          icon: const Icon(Iconsax.trash),
                          onPressed: () => _showClearAllDialog(),
                          tooltip: 'Xóa tất cả video',
                          color: Colors.red,
                        ),
                      // Add new video button
                      IconButton(
                        icon: const Icon(Iconsax.add_circle),
                        onPressed: controller.toggleView,
                        tooltip: 'Thêm video mới',
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Iconsax.arrow_left_2),
                    onPressed: controller.toggleView,
                    tooltip: 'Quay lại danh sách',
                  ),
          ),
        ],
      ),
      body: Obx(
        () => controller.showVideoList.value
            ? _buildVideoListView()
            : _buildVideoInputView(),
      ),
    );
  }

  // Build video list view
  Widget _buildVideoListView() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: EdgeInsets.all(16.w),
          child: TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm video...',
              prefixIcon: const Icon(Iconsax.search_normal),
              suffixIcon: Obx(
                () => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle),
                        onPressed: controller.clearSearch,
                      )
                    : const SizedBox.shrink(),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),

        // Video list
        Expanded(
          child: Obx(() {
            final videos = controller.filteredVideos;

            if (videos.isEmpty) {
              return _buildEmptyVideoList();
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return _buildVideoItem(video);
              },
            );
          }),
        ),
      ],
    );
  }

  // Build empty video list
  Widget _buildEmptyVideoList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            controller.searchQuery.value.isNotEmpty
                ? Iconsax.search_normal
                : Iconsax.video_slash,
            size: 64.r,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            controller.searchQuery.value.isNotEmpty
                ? 'Không tìm thấy video'
                : 'Chưa có video nào',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            controller.searchQuery.value.isNotEmpty
                ? 'Thử tìm kiếm với từ khóa khác'
                : 'Nhấn nút + để thêm video mới',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build video input view
  Widget _buildVideoInputView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          SizedBox(height: 24.h),
          _buildYouTubeUrlSection(),
          SizedBox(height: 24.h),
          _buildVideoTitleSection(),
          SizedBox(height: 24.h),
          _buildSrtSection(),
          SizedBox(height: 32.h),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.withValues(alpha: 0.1), Colors.blue.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(Iconsax.video, size: 48.r, color: Colors.red),
          SizedBox(height: 12.h),
          AutoSizeText(
            'Thêm Video với Phụ đề',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          SizedBox(height: 8.h),
          AutoSizeText(
            'Nhập link YouTube và phụ đề SRT để lưu vào danh sách',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
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
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(Iconsax.link, size: 20.r, color: Colors.red),
              SizedBox(width: 8.w),
              Text(
                'YouTube URL',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: TextField(
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
              ),
              SizedBox(width: 8.w),
              Obx(
                () => controller.youtubeUrl.value.isNotEmpty
                    ? IconButton(
                        onPressed: controller.clearYouTubeUrl,
                        icon: const Icon(Iconsax.trash),
                        color: Colors.red,
                      )
                    : const SizedBox(),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Obx(
            () => controller.isValidUrl.value
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
                        style: TextStyle(fontSize: 12.sp, color: Colors.green),
                      ),
                      if (controller.isLoadingVideoInfo.value) ...[
                        SizedBox(width: 8.w),
                        SizedBox(
                          width: 12.r,
                          height: 12.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Đang tải thông tin...',
                          style: TextStyle(fontSize: 12.sp, color: Colors.blue),
                        ),
                      ],
                    ],
                  )
                : controller.youtubeUrl.value.isNotEmpty
                ? Row(
                    children: [
                      Icon(Iconsax.close_circle, size: 16.r, color: Colors.red),
                      SizedBox(width: 4.w),
                      Text(
                        'URL không hợp lệ',
                        style: TextStyle(fontSize: 12.sp, color: Colors.red),
                      ),
                    ],
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTitleSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(Iconsax.edit, size: 20.r, color: Colors.orange),
              SizedBox(width: 8.w),
              Text(
                'Tên Video',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: controller.titleController,
            decoration: InputDecoration(
              hintText: 'Nhập tên video...',
              prefixIcon: const Icon(Iconsax.video),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Obx(
            () => controller.videoTitle.value.isNotEmpty
                ? Row(
                    children: [
                      Icon(Iconsax.info_circle, size: 16.r, color: Colors.blue),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          'Tên gốc: ${controller.videoTitle.value}',
                          style: TextStyle(fontSize: 12.sp, color: Colors.blue),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : const SizedBox(),
          ),
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
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(Iconsax.document_text, size: 20.r, color: Colors.blue),
              SizedBox(width: 8.w),
              Text(
                'Phụ đề SRT',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
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
                        Icon(Iconsax.document, size: 16.r, color: Colors.green),
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
          Text(
            'Hoặc dán nội dung SRT:',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8.h),
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
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
          // SRT Validation Widget
          Obx(
            () => controller.srtValidationResult.value != null
                ? SrtValidationWidget(
                    validationResult: controller.srtValidationResult.value!,
                    onFixApplied: controller.applyAutoFix,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  // Build video item
  Widget _buildVideoItem(VideoWithSubtitle video) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => controller.playSavedVideo(video),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: CachedNetworkImage(
                  imageUrl: video.thumbnail,
                  width: 120.w,
                  height: 68.h,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: Icon(Iconsax.video, color: Colors.grey[600]),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: Icon(Iconsax.video_slash, color: Colors.grey[600]),
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // Video info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 4.h),

                    Row(
                      children: [
                        Icon(
                          Iconsax.document_text,
                          size: 12.r,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            video.srtFileName.isNotEmpty
                                ? video.srtFileName
                                : 'Phụ đề tùy chỉnh',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 4.h),

                    Text(
                      video.formattedLastWatched,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: Icon(Iconsax.more, size: 20.r, color: Colors.grey[600]),
                onSelected: (value) {
                  if (value == 'edit') {
                    controller.editSavedVideo(video);
                  } else if (value == 'delete') {
                    _showDeleteDialog(video);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Iconsax.edit),
                        SizedBox(width: 8),
                        Text('Sửa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Iconsax.trash, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xóa', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build action buttons
  Widget _buildActionButtons() {
    return Obx(
      () => Column(
        children: [
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  controller.canPlayVideo() && !controller.isLoading.value
                  ? controller.saveVideoWithSubtitle
                  : null,
              icon: controller.isLoading.value
                  ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Iconsax.save_2),
              label: Text(
                controller.isLoading.value
                    ? 'Đang lưu...'
                    : 'Lưu vào danh sách',
                style: TextStyle(fontSize: 16.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    controller.canPlayVideo() && !controller.isLoading.value
                    ? Colors.blue
                    : Colors.grey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation:
                    controller.canPlayVideo() && !controller.isLoading.value
                    ? 4
                    : 0,
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Play button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  controller.canPlayVideo() && !controller.isLoading.value
                  ? controller.playVideoWithSubtitles
                  : null,
              icon: const Icon(Iconsax.play),
              label: Text('Phát ngay', style: TextStyle(fontSize: 16.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    controller.canPlayVideo() && !controller.isLoading.value
                    ? Colors.green
                    : Colors.grey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation:
                    controller.canPlayVideo() && !controller.isLoading.value
                    ? 4
                    : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show delete dialog
  void _showDeleteDialog(VideoWithSubtitle video) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xóa video'),
        content: Text('Bạn có chắc muốn xóa "${video.title}" khỏi danh sách?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(Get.context!).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteSavedVideo(video);
              Navigator.of(Get.context!).pop();
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  // Show clear all dialog
  void _showClearAllDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Xóa tất cả video'),
        content: Text(
          'Bạn có chắc muốn xóa tất cả ${controller.savedVideos.length} video khỏi danh sách?\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(Get.context!).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              controller.clearAllVideos();
              Navigator.of(Get.context!).pop();
            },
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
