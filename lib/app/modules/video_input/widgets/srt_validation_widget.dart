import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/utils/srt_parser.dart';

class SrtValidationWidget extends StatelessWidget {
  final SrtValidationResult validationResult;
  final VoidCallback? onFixApplied;

  const SrtValidationWidget({
    Key? key,
    required this.validationResult,
    this.onFixApplied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (validationResult.isValid &&
        validationResult.formatFixesCount == 0 &&
        validationResult.silenceGaps.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Iconsax.tick_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text(
              'File SRT hợp lệ ✓',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format fixes section
          if (validationResult.formatErrors.isNotEmpty) ...[
            _buildSectionHeader(
              'Lỗi định dạng đã được sửa tự động',
              Colors.blue,
              Iconsax.edit,
              '${validationResult.formatFixesCount} lỗi',
            ),
            _buildErrorList(validationResult.formatErrors, Colors.blue),
            if (validationResult.fixedContent != null && onFixApplied != null)
              _buildApplyFixButton(),
            const SizedBox(height: 12),
          ],

          // Timeline errors section
          if (validationResult.timelineErrors.isNotEmpty) ...[
            _buildSectionHeader(
              'Lỗi timeline cần kiểm tra',
              Colors.orange,
              Iconsax.warning_2,
              '${validationResult.timelineErrors.length} lỗi',
            ),
            _buildErrorList(validationResult.timelineErrors, Colors.orange),
            const SizedBox(height: 12),
          ],

          // Silence gaps section
          if (validationResult.silenceGaps.isNotEmpty) ...[
            _buildSectionHeader(
              'Khoảng lặng > 2.5 giây',
              Colors.purple,
              Iconsax.clock,
              '${validationResult.silenceGaps.length} khoảng',
            ),
            _buildErrorList(validationResult.silenceGaps, Colors.purple),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    Color color,
    IconData icon,
    String count,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorList(List<String> errors, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            errors
                .take(5)
                .map(
                  (error) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error,
                            style: TextStyle(
                              color: color.withOpacity(0.8),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList()
              ..addAll(
                errors.length > 5
                    ? [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '... và ${errors.length - 5} lỗi khác',
                            style: TextStyle(
                              color: color.withOpacity(0.6),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ]
                    : [],
              ),
      ),
    );
  }

  Widget _buildApplyFixButton() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onFixApplied,
        icon: const Icon(Iconsax.tick_circle, size: 18),
        label: const Text('Áp dụng sửa lỗi tự động'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}
