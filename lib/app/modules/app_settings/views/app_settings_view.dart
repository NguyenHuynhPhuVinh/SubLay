import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../controllers/app_settings_controller.dart';
import '../../../data/services/app_settings_service.dart';

class AppSettingsView extends GetView<AppSettingsController> {
  const AppSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildVideoOrientationSection()],
        ),
      ),
    );
  }

  Widget _buildVideoOrientationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.mobile, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Hướng xem video',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn hướng hiển thị khi phát video',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Obx(
              () => Column(
                children: [
                  _buildOrientationOption(
                    VideoOrientation.landscape,
                    'Ngang (Landscape)',
                    'Video sẽ hiển thị ở chế độ ngang',
                    Iconsax.rotate_right,
                  ),
                  const SizedBox(height: 8),
                  _buildOrientationOption(
                    VideoOrientation.portrait,
                    'Dọc (Portrait)',
                    'Video sẽ hiển thị ở chế độ dọc',
                    Iconsax.mobile,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrientationOption(
    VideoOrientation orientation,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected =
        controller.settingsService.videoOrientation.value == orientation;

    return InkWell(
      onTap: () => controller.changeVideoOrientation(orientation),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.blue : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Iconsax.tick_circle, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
