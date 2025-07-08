import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../controllers/recent_videos_controller.dart';
import '../../../data/models/video_with_subtitle.dart';
import '../../../core/utils/responsive_helper.dart' as rh;
import '../../../widgets/responsive_layout.dart' as rl;

class RecentVideosView extends GetView<RecentVideosController> {
  const RecentVideosView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Videos'),
        centerTitle: true,
        actions: [
          Obx(() => IconButton(
            icon: Icon(
              controller.showSearchInput.value
                ? Iconsax.close_circle
                : Iconsax.search_normal
            ),
            onPressed: controller.toggleSearchInput,
          )),
          PopupMenuButton<String>(
            icon: const Icon(Iconsax.more),
            onSelected: (value) {
              if (value == 'clear_all') {
                _showClearAllDialog();
              } else if (value == 'statistics') {
                _showStatisticsDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(Iconsax.chart),
                    SizedBox(width: 8),
                    Text('Thống kê'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Iconsax.trash, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search input
          Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: controller.showSearchInput.value ? 60.h : 0,
            child: controller.showSearchInput.value
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: TextField(
                      controller: controller.searchController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tên video hoặc file SRT...',
                        prefixIcon: const Icon(Iconsax.search_normal),
                        suffixIcon: controller.searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Iconsax.close_circle),
                                onPressed: controller.clearSearch,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      onChanged: controller.searchVideos,
                      autofocus: true,
                    ),
                  )
                : const SizedBox.shrink(),
          )),

          // Video list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoadingView();
              }

              if (controller.filteredVideos.isEmpty) {
                return _buildEmptyView();
              }

              return _buildVideoList();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 5,
      itemBuilder: (context, index) => _buildShimmerItem(),
    );
  }

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        child: Row(
          children: [
            Container(
              width: 120.w,
              height: 68.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    height: 12.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            controller.searchQuery.value.isNotEmpty
                ? Iconsax.search_normal
                : Iconsax.clock,
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
                : 'Video bạn đã xem sẽ hiển thị ở đây',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (controller.searchQuery.value.isNotEmpty) ...[
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: controller.clearSearch,
              icon: const Icon(Iconsax.close_circle),
              label: const Text('Xóa tìm kiếm'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    return rl.ResponsiveBuilder(
      builder: (context, deviceType) {
        if (deviceType == rh.DeviceType.desktop) {
          return _buildDesktopGrid();
        } else {
          return _buildMobileList();
        }
      },
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: controller.filteredVideos.length,
      itemBuilder: (context, index) {
        final video = controller.filteredVideos[index];
        return _buildVideoItem(video);
      },
    );
  }

  Widget _buildDesktopGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 2.5,
      ),
      itemCount: controller.filteredVideos.length,
      itemBuilder: (context, index) {
        final video = controller.filteredVideos[index];
        return _buildDesktopVideoCard(video);
      },
    );
  }

  Widget _buildVideoItem(VideoWithSubtitle video) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
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
      child: InkWell(
        onTap: () => controller.playVideo(video),
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
                    child: Icon(
                      Iconsax.video,
                      color: Colors.grey[600],
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Iconsax.video_slash,
                      color: Colors.grey[600],
                    ),
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

                    Row(
                      children: [
                        Icon(
                          Iconsax.clock,
                          size: 12.r,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          video.formattedLastWatched,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        if (video.progressPercentage > 0) ...[
                          Text(
                            '${(video.progressPercentage * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (video.progressPercentage > 0) ...[
                      SizedBox(height: 4.h),
                      LinearProgressIndicator(
                        value: video.progressPercentage,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: Icon(
                  Iconsax.more,
                  size: 20.r,
                  color: Colors.grey[600],
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(video);
                  }
                },
                itemBuilder: (context) => [
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



  void _showDeleteDialog(VideoWithSubtitle video) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xóa video'),
        content: Text('Bạn có chắc muốn xóa "${video.title}" khỏi lịch sử?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(Get.context!).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              controller.removeVideo(video);
              Navigator.of(Get.context!).pop();
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void _showClearAllDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Xóa tất cả lịch sử'),
        content: const Text('Bạn có chắc muốn xóa tất cả lịch sử video?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(Get.context!).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              controller.clearAllHistory();
              Navigator.of(Get.context!).pop();
            },
            child: const Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void _showStatisticsDialog() {
    final stats = controller.statistics;
    Get.dialog(
      AlertDialog(
        title: const Text('Thống kê'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem('Tổng số video', '${stats['totalVideos']}'),
            _buildStatItem('Video gần đây', '${stats['recentVideos']}'),
            _buildStatItem('Video có tiến độ', '${stats['videosWithProgress']}'),
            _buildStatItem('Tổng thời gian xem', _formatDuration(stats['totalWatchTime'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(Get.context!).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Widget _buildDesktopVideoCard(VideoWithSubtitle video) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => controller.playVideo(video),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: video.thumbnail,
                  width: 160,
                  height: 90,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Iconsax.video,
                      color: Colors.grey[600],
                      size: 32,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Iconsax.video_slash,
                      color: Colors.grey[600],
                      size: 32,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Video info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      video.srtFileName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Iconsax.clock,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateDesktop(video.lastWatched),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => controller.playVideo(video),
                    icon: const Icon(Iconsax.play),
                    tooltip: 'Phát video',
                  ),
                  IconButton(
                    onPressed: () => controller.removeVideo(video),
                    icon: const Icon(Iconsax.trash),
                    tooltip: 'Xóa video',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateDesktop(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
