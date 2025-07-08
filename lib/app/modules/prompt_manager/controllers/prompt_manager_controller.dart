import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/prompt_model.dart';
import '../../../data/services/prompt_service.dart';

class PromptManagerController extends GetxController {
  final PromptService _promptService = Get.find<PromptService>();

  // Observable variables
  final selectedCategory = 'All'.obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;

  // Form controllers
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController();

  // Form validation
  final formKey = GlobalKey<FormState>();

  // Current editing prompt
  PromptModel? editingPrompt;

  // Getters
  List<PromptModel> get prompts => _promptService.prompts;
  
  List<PromptModel> get filteredPrompts {
    var filtered = prompts.where((prompt) {
      final matchesCategory = selectedCategory.value == 'All' || 
                             prompt.category == selectedCategory.value;
      final matchesSearch = searchQuery.value.isEmpty ||
                           prompt.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                           prompt.description.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                           prompt.content.toLowerCase().contains(searchQuery.value.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
    
    return filtered;
  }

  List<String> get categories {
    final cats = ['All'] + _promptService.getCategories();
    return cats;
  }

  @override
  void onInit() {
    super.onInit();
    categoryController.text = 'General';
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    super.onClose();
  }

  void setSelectedCategory(String category) {
    selectedCategory.value = category;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void clearForm() {
    titleController.clear();
    contentController.clear();
    descriptionController.clear();
    categoryController.text = 'General';
    editingPrompt = null;
  }

  void editPrompt(PromptModel prompt) {
    editingPrompt = prompt;
    titleController.text = prompt.title;
    contentController.text = prompt.content;
    descriptionController.text = prompt.description;
    categoryController.text = prompt.category;
  }

  Future<void> savePrompt() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final now = DateTime.now();
      
      if (editingPrompt != null) {
        // Update existing prompt
        final updatedPrompt = editingPrompt!.copyWith(
          title: titleController.text.trim(),
          content: contentController.text.trim(),
          description: descriptionController.text.trim(),
          category: categoryController.text.trim(),
          updatedAt: now,
        );
        await _promptService.updatePrompt(updatedPrompt);
        Get.snackbar(
          'Thành công',
          'Đã cập nhật prompt',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // Create new prompt
        final newPrompt = PromptModel(
          id: 'prompt_${now.millisecondsSinceEpoch}',
          title: titleController.text.trim(),
          content: contentController.text.trim(),
          description: descriptionController.text.trim(),
          category: categoryController.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        await _promptService.addPrompt(newPrompt);
        Get.snackbar(
          'Thành công',
          'Đã thêm prompt mới',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
      
      clearForm();
      Get.back(); // Close dialog/bottom sheet
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể lưu prompt: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePrompt(PromptModel prompt) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa prompt "${prompt.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _promptService.deletePrompt(prompt.id);
        Get.snackbar(
          'Thành công',
          'Đã xóa prompt',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Lỗi',
          'Không thể xóa prompt: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> duplicatePrompt(PromptModel prompt) async {
    try {
      await _promptService.duplicatePrompt(prompt.id);
      Get.snackbar(
        'Thành công',
        'Đã sao chép prompt',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể sao chép prompt: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> copyPromptToClipboard(PromptModel prompt) async {
    try {
      await Clipboard.setData(ClipboardData(text: prompt.content));
      Get.snackbar(
        'Thành công',
        'Đã copy prompt vào clipboard',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể copy prompt: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tiêu đề';
    }
    if (value.trim().length < 3) {
      return 'Tiêu đề phải có ít nhất 3 ký tự';
    }
    return null;
  }

  String? validateContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập nội dung prompt';
    }
    if (value.trim().length < 10) {
      return 'Nội dung phải có ít nhất 10 ký tự';
    }
    return null;
  }

  String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập danh mục';
    }
    return null;
  }
}
