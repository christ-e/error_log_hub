import 'package:get/get.dart';

import '../controllers/function_eroor_404_controller.dart';

class FunctionEroor404Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FunctionEroor404Controller>(
      () => FunctionEroor404Controller(),
    );
  }
}
