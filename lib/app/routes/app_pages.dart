import 'package:get/get.dart';

import '../modules/exception_eroor/bindings/exception_eroor_binding.dart';
import '../modules/exception_eroor/views/exception_eroor_view.dart';
import '../modules/function_eroor_404/bindings/function_eroor_404_binding.dart';
import '../modules/function_eroor_404/views/function_eroor_404_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.FUNCTION_EROOR_404,
      page: () => const FunctionEroor404View(),
      binding: FunctionEroor404Binding(),
    ),
    GetPage(
      name: _Paths.EXCEPTION_EROOR,
      page: () => const ExceptionEroorView(),
      binding: ExceptionEroorBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
  ];
}
