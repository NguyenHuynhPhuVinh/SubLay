import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/prompt_manager_controller.dart';
import '../../../data/models/prompt_model.dart';
import 'widgets/prompt_card.dart';
import 'widgets/prompt_form_dialog.dart';

class PromptManagerView extends GetView<PromptManagerController> {
  const PromptManagerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Prompt AI'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.global),
            tooltip: 'Mở Google AI Studio',
            onPressed: () => _openAIStudio(),
          ),
          Obx(
            () => IconButton(
              icon: Icon(
                controller.showPromptList.value
                    ? Iconsax.add_circle
                    : Iconsax.arrow_left_2,
              ),
              onPressed: controller.toggleView,
              tooltip: controller.showPromptList.value
                  ? 'Thêm prompt mới'
                  : 'Quay lại danh sách',
            ),
          ),
        ],
      ),
      body: Obx(
        () => controller.showPromptList.value
            ? _buildPromptListView()
            : _buildPromptFormView(),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: controller.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm prompt...',
              prefixIcon: const Icon(Iconsax.search_normal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              filled: true,
              fillColor: Theme.of(Get.context!).colorScheme.surface,
            ),
          ),
          SizedBox(height: 12.h),
          // Category filter
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.categories.map((category) {
                  final isSelected =
                      controller.selectedCategory.value == category;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) =>
                          controller.setSelectedCategory(category),
                      backgroundColor: Theme.of(
                        Get.context!,
                      ).colorScheme.surface,
                      selectedColor: Theme.of(
                        Get.context!,
                      ).colorScheme.primaryContainer,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build prompt list view
  Widget _buildPromptListView() {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(child: Obx(() => _buildPromptList())),
      ],
    );
  }

  Widget _buildPromptList() {
    final filteredPrompts = controller.filteredPrompts;

    if (filteredPrompts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.message_text, size: 64.r, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              controller.searchQuery.value.isNotEmpty
                  ? 'Không tìm thấy prompt nào'
                  : 'Chưa có prompt nào',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              controller.searchQuery.value.isNotEmpty
                  ? 'Thử tìm kiếm với từ khóa khác'
                  : 'Nhấn nút + để thêm prompt đầu tiên',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: filteredPrompts.length,
      itemBuilder: (context, index) {
        final prompt = filteredPrompts[index];
        return PromptCard(
          prompt: prompt,
          onTap: () => _showPromptDetail(context, prompt),
          onEdit: () => controller.showEditPromptForm(prompt),
          onDelete: () => controller.deletePrompt(prompt),
          onCopy: () => controller.copyPromptToClipboard(prompt),
        );
      },
    );
  }

  void _openAIStudio() async {
    const url = 'https://aistudio.google.com/';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể mở trình duyệt. Vui lòng kiểm tra lại cài đặt ứng dụng.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể mở link: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Build prompt form view
  Widget _buildPromptFormView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFormHeader(),
            SizedBox(height: 24.h),
            _buildTitleField(),
            SizedBox(height: 16.h),
            _buildCategoryField(),
            SizedBox(height: 16.h),
            _buildDescriptionField(),
            SizedBox(height: 16.h),
            _buildContentField(),
            SizedBox(height: 32.h),
            _buildFormActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            controller.editingPrompt != null ? Iconsax.edit : Iconsax.add,
            size: 24.r,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              controller.editingPrompt != null
                  ? 'Sửa Prompt'
                  : 'Thêm Prompt Mới',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiêu đề *',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
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
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh mục *',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
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
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mô tả',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller.descriptionController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Nhập mô tả ngắn...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            prefixIcon: const Icon(Iconsax.document_text),
          ),
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nội dung *',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller.contentController,
          validator: controller.validateContent,
          maxLines: 10,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung prompt...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFormActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: controller.toggleView,
            child: const Text('Hủy'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.savePrompt,
              child: controller.isLoading.value
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      controller.editingPrompt != null ? 'Cập nhật' : 'Thêm',
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPromptForm(BuildContext context, {PromptModel? prompt}) {
    if (prompt != null) {
      controller.editPrompt(prompt);
    } else {
      controller.clearForm();
    }

    showDialog(
      context: context,
      builder: (context) =>
          PromptFormDialog(controller: controller, isEditing: prompt != null),
    );
  }

  void _showPromptDetail(BuildContext context, PromptModel prompt) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prompt.title,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (prompt.description.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              prompt.description,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.close_circle),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: SelectableText(
                    prompt.content,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ),
              // Actions
              Container(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              controller.copyPromptToClipboard(prompt);
                              Get.back();
                            },
                            icon: const Icon(Iconsax.copy),
                            label: const Text('Copy'),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.back();
                              controller.showEditPromptForm(prompt);
                            },
                            icon: const Icon(Iconsax.edit),
                            label: const Text('Sửa'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
