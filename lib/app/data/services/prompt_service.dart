import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/prompt_model.dart';

class PromptService extends GetxService {
  static const String _boxName = 'prompts';
  late Box<PromptModel> _promptBox;

  // Observable list of prompts
  final RxList<PromptModel> prompts = <PromptModel>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeBox();
    _loadPrompts();
  }

  Future<void> _initializeBox() async {
    _promptBox = await Hive.openBox<PromptModel>(_boxName);
  }

  void _loadPrompts() {
    prompts.clear();
    prompts.addAll(_promptBox.values.toList());
    prompts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }



  Future<void> addPrompt(PromptModel prompt) async {
    await _promptBox.put(prompt.id, prompt);
    _loadPrompts();
  }

  Future<void> updatePrompt(PromptModel prompt) async {
    final updatedPrompt = prompt.copyWith(updatedAt: DateTime.now());
    await _promptBox.put(updatedPrompt.id, updatedPrompt);
    _loadPrompts();
  }

  Future<void> deletePrompt(String id) async {
    await _promptBox.delete(id);
    _loadPrompts();
  }

  PromptModel? getPromptById(String id) {
    return _promptBox.get(id);
  }

  List<PromptModel> getPromptsByCategory(String category) {
    return prompts.where((prompt) => prompt.category == category).toList();
  }

  List<String> getCategories() {
    final categories = prompts.map((prompt) => prompt.category).toSet().toList();
    categories.sort();
    return categories;
  }



  Future<void> exportPrompts() async {
    // TODO: Implement export functionality
  }

  Future<void> importPrompts(List<PromptModel> importedPrompts) async {
    for (final prompt in importedPrompts) {
      await addPrompt(prompt);
    }
  }
}
