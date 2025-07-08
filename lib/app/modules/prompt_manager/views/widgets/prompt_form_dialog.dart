import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/prompt_manager_controller.dart';

class PromptFormDialog extends StatelessWidget {
  final PromptManagerController controller;
  final bool isEditing;

  const PromptFormDialog({
    Key? key,
    required this.controller,
    this.isEditing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600.w,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Iconsax.edit : Iconsax.add,
                    size: 24.r,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      isEditing ? 'Sửa Prompt' : 'Thêm Prompt Mới',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.close_circle),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      Text(
                        'Tiêu đề *',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: controller.titleController,
                        validator: controller.validateTitle,
                        decoration: InputDecoration(
                          hintText: 'Nhập tiêu đề prompt...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          prefixIcon: const Icon(Iconsax.text),
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Category field
                      Text(
                        'Danh mục *',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: controller.categoryController,
                        validator: controller.validateCategory,
                        decoration: InputDecoration(
                          hintText: 'Nhập danh mục...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          prefixIcon: const Icon(Iconsax.category),
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Description field
                      Text(
                        'Mô tả',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: controller.descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Mô tả ngắn về prompt này...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          prefixIcon: const Icon(Iconsax.note),
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Content field
                      Text(
                        'Nội dung Prompt *',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: controller.contentController,
                        validator: controller.validateContent,
                        maxLines: 10,
                        decoration: InputDecoration(
                          hintText: 'Nhập nội dung prompt...\n\nVí dụ:\nHãy tạo file phụ đề SRT cho video YouTube này...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          alignLabelWithHint: true,
                        ),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13.sp,
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Tips
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.info_circle,
                                  size: 16.r,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Mẹo viết prompt hiệu quả:',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '• Sử dụng [PLACEHOLDER] để đánh dấu vị trí cần thay thế\n'
                              '• Mô tả rõ ràng yêu cầu và định dạng mong muốn\n'
                              '• Chia nhỏ thành các bước cụ thể\n'
                              '• Đưa ra ví dụ minh họa khi cần thiết',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: Obx(() => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.savePrompt,
                      child: controller.isLoading.value
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(isEditing ? 'Cập nhật' : 'Thêm'),
                    )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
