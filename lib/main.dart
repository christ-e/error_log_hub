import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vansales_firebase_erorrs/app/data/services/notification_service.dart';
import 'package:vansales_firebase_erorrs/firebase_options.dart';

import 'app/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await Firebase.initializeApp(
      name: 'RealsoftHr',
      options: RealsoftHrFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing RealsoftHr Firebase: $e');
  }

  try {
    await Firebase.initializeApp(
      name: 'RealsoftErpApps',
      options: RealsoftErpFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing RealsoftErpApps Firebase: $e');
  }

  // Initialize Local Notifications and In-App Alert Service
  await Get.putAsync(() => NotificationService().init());

  runApp(
    GetMaterialApp(
      title: "Error Monitoring Hub",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E3C72),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
        ),
      ),
    ),
  );
}
