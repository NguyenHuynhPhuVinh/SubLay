import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../controllers/subtitle_editor_controller.dart';
import '../../../core/services/subtitle_settings_service.dart';

class SubtitleEditorView extends GetView<SubtitleEditorController> {
  const SubtitleEditorView({Key? key}) : super(key: key);

  SubtitleSettingsService get _subtitleSettings =>
      Get.find<SubtitleSettingsService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subtitle Editor'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () {
              controller.resetOffset();
            },
            tooltip: 'Reset Offset',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timing adjustment controls
            _buildTimingControls(),
            const SizedBox(height: 24),

            // Info card
            _buildInfoCard(),

            const SizedBox(height: 24),

            // Status info
            _buildStatusInfo(),

            const SizedBox(height: 100), // Extra space at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildTimingControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.timer_1, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Điều chỉnh Timing',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Obx(
                  () => Text(
                    _subtitleSettings.offsetString,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(_subtitleSettings.offsetColor),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Cài đặt chung cho tất cả video - Điều chỉnh nếu phụ đề bị delay:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Quick adjustment buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildOffsetButton('-1000ms', -1000, Colors.red),
                _buildOffsetButton('-500ms', -500, Colors.orange),
                _buildOffsetButton('-100ms', -100, Colors.orange.shade300),
                _buildOffsetButton('Reset', 0, Colors.grey, isReset: true),
                _buildOffsetButton('+100ms', 100, Colors.green.shade300),
                _buildOffsetButton('+500ms', 500, Colors.green),
                _buildOffsetButton('+1000ms', 1000, Colors.green.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffsetButton(
    String label,
    int offset,
    Color color, {
    bool isReset = false,
  }) {
    return ElevatedButton(
      onPressed: () {
        if (isReset) {
          controller.resetOffset();
        } else {
          controller.adjustOffset(offset);
        }

        // Haptic feedback
        HapticFeedback.lightImpact();

        // Show feedback
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.info_circle, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Cài đặt Subtitle Timing',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Cài đặt này áp dụng cho TẤT CẢ video và được lưu tự động\n'
              '• Nếu phụ đề hiển thị chậm hơn âm thanh: dùng nút âm (-)\n'
              '• Nếu phụ đề hiển thị nhanh hơn âm thanh: dùng nút dương (+)\n'
              '• Thay đổi sẽ có hiệu lực ngay lập tức khi xem video',
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Obx(
      () => Card(
        color: Colors.blue.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Icon(Iconsax.setting_2, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Offset hiện tại: ${_subtitleSettings.offsetString} • Đã lưu tự động',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
