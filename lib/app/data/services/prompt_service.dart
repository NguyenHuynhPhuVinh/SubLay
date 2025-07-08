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
    await _loadDefaultPrompts();
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

  Future<void> _loadDefaultPrompts() async {
    if (_promptBox.isEmpty) {
      final defaultPrompts = _getDefaultPrompts();
      for (final prompt in defaultPrompts) {
        await _promptBox.put(prompt.id, prompt);
      }
    }
  }

  List<PromptModel> _getDefaultPrompts() {
    final now = DateTime.now();
    return [
      PromptModel(
        id: 'default_1',
        title: 'Tạo phụ đề từ video YouTube',
        content: '''Hãy tạo file phụ đề SRT cho video YouTube này. Yêu cầu:

1. Phân tích nội dung video và tạo phụ đề chính xác
2. Chia nhỏ câu để dễ đọc (tối đa 2 dòng mỗi phụ đề)
3. Thời gian hiển thị phù hợp (2-6 giây mỗi phụ đề)
4. Sử dụng định dạng SRT chuẩn
5. Đảm bảo đồng bộ với âm thanh

URL video: [PASTE_VIDEO_URL_HERE]

Vui lòng tạo file SRT hoàn chỉnh.''',
        description: 'Prompt cơ bản để tạo phụ đề từ video YouTube',
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        category: 'YouTube',
      ),
      PromptModel(
        id: 'default_2',
        title: 'Dịch phụ đề sang tiếng Việt',
        content: '''Hãy dịch file phụ đề SRT này sang tiếng Việt. Yêu cầu:

1. Giữ nguyên định dạng SRT (số thứ tự, thời gian, nội dung)
2. Dịch tự nhiên, phù hợp văn hóa Việt Nam
3. Giữ độ dài câu phù hợp với thời gian hiển thị
4. Sử dụng từ ngữ dễ hiểu
5. Đảm bảo ý nghĩa chính xác

File SRT gốc:
[PASTE_SRT_CONTENT_HERE]

Vui lòng trả về file SRT đã dịch.''',
        description: 'Dịch phụ đề từ ngôn ngữ khác sang tiếng Việt',
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        category: 'Translation',
      ),
      PromptModel(
        id: 'default_3',
        title: 'Tối ưu hóa phụ đề',
        content: '''Hãy tối ưu hóa file phụ đề SRT này để cải thiện trải nghiệm đọc:

1. Điều chỉnh thời gian hiển thị phù hợp
2. Chia nhỏ câu dài thành nhiều phụ đề
3. Sửa lỗi chính tả và ngữ pháp
4. Đảm bảo khoảng cách thời gian hợp lý
5. Cải thiện cách ngắt câu

File SRT cần tối ưu:
[PASTE_SRT_CONTENT_HERE]

Vui lòng trả về file SRT đã được tối ưu hóa.''',
        description: 'Tối ưu hóa và cải thiện chất lượng phụ đề',
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        category: 'Optimization',
      ),
    ];
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

  Future<void> duplicatePrompt(String id) async {
    final original = getPromptById(id);
    if (original != null) {
      final now = DateTime.now();
      final duplicate = original.copyWith(
        id: 'prompt_${now.millisecondsSinceEpoch}',
        title: '${original.title} (Copy)',
        createdAt: now,
        updatedAt: now,
        isDefault: false,
      );
      await addPrompt(duplicate);
    }
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
