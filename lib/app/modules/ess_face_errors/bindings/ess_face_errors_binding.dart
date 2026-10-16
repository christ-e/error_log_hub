import 'package:get/get.dart';

import '../controllers/ess_face_errors_controller.dart';

class EssFaceErrorsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EssFaceErrorsController>(
      () => EssFaceErrorsController(),
    );
  }
}
