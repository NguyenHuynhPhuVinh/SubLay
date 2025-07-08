import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add),
            onPressed: () => _showPromptForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: Obx(() => _buildPromptList()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPromptForm(context),
        child: const Icon(Iconsax.add),
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
          Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: controller.categories.map((category) {
                final isSelected = controller.selectedCategory.value == category;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => controller.setSelectedCategory(category),
                    backgroundColor: Theme.of(Get.context!).colorScheme.surface,
                    selectedColor: Theme.of(Get.context!).colorScheme.primaryContainer,
                  ),
                );
              }).toList(),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPromptList() {
    final filteredPrompts = controller.filteredPrompts;
    
    if (filteredPrompts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.message_text,
              size: 64.r,
              color: Colors.grey,
            ),
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
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
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
          onEdit: () => _showPromptForm(context, prompt: prompt),
          onDelete: () => controller.deletePrompt(prompt),
          onDuplicate: () => controller.duplicatePrompt(prompt),
          onCopy: () => controller.copyPromptToClipboard(prompt),
        );
      },
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
      builder: (context) => PromptFormDialog(
        controller: controller,
        isEditing: prompt != null,
      ),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        controller.copyPromptToClipboard(prompt);
                        Get.back();
                      },
                      icon: const Icon(Iconsax.copy),
                      label: const Text('Copy'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        _showPromptForm(context, prompt: prompt);
                      },
                      icon: const Icon(Iconsax.edit),
                      label: const Text('Sửa'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        controller.duplicatePrompt(prompt);
                      },
                      icon: const Icon(Iconsax.copy),
                      label: const Text('Nhân bản'),
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
