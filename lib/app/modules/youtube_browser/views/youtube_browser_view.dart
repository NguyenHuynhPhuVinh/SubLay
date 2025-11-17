import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/youtube_browser_controller.dart';

class YoutubeBrowserView extends GetView<YoutubeBrowserController> {
  const YoutubeBrowserView({super.key});

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}
