import 'package:get/get.dart';
import '../controllers/prompt_manager_controller.dart';
import '../../../data/services/prompt_service.dart';

class PromptManagerBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure PromptService is available
    if (!Get.isRegistered<PromptService>()) {
      Get.put(PromptService(), permanent: true);
    }

    Get.lazyPut<PromptManagerController>(
      () => PromptManagerController(),
    );
  }
}
