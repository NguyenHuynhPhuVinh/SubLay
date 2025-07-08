import 'package:get/get.dart';
import '../controllers/video_input_controller.dart';

class VideoInputBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VideoInputController>(
      () => VideoInputController(),
    );
  }
}
