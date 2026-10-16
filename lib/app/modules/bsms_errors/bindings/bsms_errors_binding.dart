import 'package:get/get.dart';

import '../controllers/bsms_errors_controller.dart';

class BsmsErrorsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BsmsErrorsController>(
      () => BsmsErrorsController(),
    );
  }
}
