import 'package:get/get.dart';

import '../controllers/exception_eroor_controller.dart';

class ExceptionEroorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExceptionEroorController>(
      () => ExceptionEroorController(),
    );
  }
}
