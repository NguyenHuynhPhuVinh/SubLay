import 'package:get/get.dart';
import '../controllers/youtube_browser_controller.dart';

class YoutubeBrowserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<YoutubeBrowserController>(() => YoutubeBrowserController());
  }
}
