import 'package:get/get.dart';
import 'package:hive/hive.dart';

class SubtitleSettingsService extends GetxService {
  static const String _boxName = 'subtitle_settings';
  static const String _offsetKey = 'subtitle_offset';

  late Box _box;

  // Observable subtitle offset (milliseconds)
  final subtitleOffset = 0.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initHive();
    _loadSettings();
  }

  Future<void> _initHive() async {
    _box = await Hive.openBox(_boxName);
  }

  void _loadSettings() {
    subtitleOffset.value = _box.get(_offsetKey, defaultValue: 0);
  }

  // Adjust subtitle offset
  void adjustOffset(int milliseconds) {
    subtitleOffset.value += milliseconds;
    _saveOffset();
  }

  // Set subtitle offset directly
  void setOffset(int milliseconds) {
    subtitleOffset.value = milliseconds;
    _saveOffset();
  }

  // Reset offset to 0
  void resetOffset() {
    subtitleOffset.value = 0;
    _saveOffset();
  }

  void _saveOffset() {
    _box.put(_offsetKey, subtitleOffset.value);
  }

  // Get formatted offset string for UI
  String get offsetString {
    final offset = subtitleOffset.value;
    if (offset == 0) return '0ms';
    return '${offset > 0 ? '+' : ''}${offset}ms';
  }

  // Get offset color for UI
  int get offsetColor {
    final offset = subtitleOffset.value;
    if (offset == 0) return 0xFF9E9E9E; // Grey
    return offset > 0 ? 0xFF4CAF50 : 0xFFF44336; // Green or Red
  }
}
