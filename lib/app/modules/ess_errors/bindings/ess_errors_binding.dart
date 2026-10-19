import 'package:get/get.dart';
import '../controllers/ess_errors_controller.dart';

class EssErrorsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EssErrorsController>(
      () => EssErrorsController(),
    );
  }
}
