import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vansales_firebase_erorrs/app/routes/app_pages.dart';

class AppItem {
  final String id;
  final String name;
  final String tag;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String status;

  const AppItem({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.status = 'Active',
  });
}

class AppSelectionController extends GetxController {
  final RxList<AppItem> allApps = <AppItem>[
    const AppItem(
      id: 'vansales',
      name: 'Van Sales',
      tag: 'Distribution & Invoicing',
      description: 'Field sales operations, route tracking, invoice sync & server 404 errors.',
      icon: Icons.local_shipping_rounded,
      primaryColor: Color(0xFF1E3C72),
      secondaryColor: Color(0xFF2A5298),
      accentColor: Color(0xFF3B82F6),
    ),
    const AppItem(
      id: 'ess_face',
      name: 'Ess face',
      tag: 'Face Attendance System',
      description: 'Facial recognition attendance logs, biometric sync & punch failure records.',
      icon: Icons.face_unlock_rounded,
      primaryColor: Color(0xFF0F766E),
      secondaryColor: Color(0xFF14B8A6),
      accentColor: Color(0xFF2DD4BF),
    ),
    const AppItem(
      id: 'ess',
      name: 'ESS System Logs',
      tag: 'SYSTEM LOGS',
      description: 'Employee portal diagnostics, API errors, network 404s & fatal exception signatures.',
      icon: Icons.hub_rounded,
      primaryColor: Color(0xFF8B5CF6),
      secondaryColor: Color(0xFF6D28D9),
      accentColor: Color(0xFFA855F7),
      status: 'Active',
    ),
    const AppItem(
      id: 'bsms',
      name: 'BSMS',
      tag: 'Bed Space Management',
      description: 'Bed allotment, room inventory, rent payments and tenant tracking error logs.',
      icon: Icons.apartment_rounded,
      primaryColor: Color(0xFF6D28D9),
      secondaryColor: Color(0xFF7C3AED),
      accentColor: Color(0xFFA78BFA),
      status: 'Not Configured',
    ),
  ].obs;

  final RxList<AppItem> filteredApps = <AppItem>[].obs;
  final Rx<AppItem?> selectedApp = Rx<AppItem?>(null);
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    filteredApps.assignAll(allApps);
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredApps.assignAll(allApps);
    } else {
      filteredApps.assignAll(
        allApps.where((app) {
          return app.name.toLowerCase().contains(query) ||
              app.tag.toLowerCase().contains(query) ||
              app.description.toLowerCase().contains(query);
        }),
      );
    }
  }

  void selectApp(AppItem app) {
    selectedApp.value = app;
    if (app.id == 'ess_face') {
      Get.toNamed(Routes.ESS_FACE_ERRORS, arguments: app);
    } else if (app.id == 'bsms') {
      Get.toNamed(Routes.BSMS_ERRORS, arguments: app);
    } else if (app.id == 'ess') {
      Get.toNamed(Routes.ESS_ERRORS, arguments: app);
    } else {
      Get.toNamed(Routes.HOME, arguments: app);
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAllNamed(Routes.LOGIN);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
