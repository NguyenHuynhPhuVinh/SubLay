import 'package:get/get.dart';
import '../controllers/recent_videos_controller.dart';

class RecentVideosBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecentVideosController>(
      () => RecentVideosController(),
    );
  }
}
