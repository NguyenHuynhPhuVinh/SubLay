import 'package:get/get.dart';
import '../controllers/subtitle_editor_controller.dart';

class SubtitleEditorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubtitleEditorController>(
      () => SubtitleEditorController(),
    );
  }
}
