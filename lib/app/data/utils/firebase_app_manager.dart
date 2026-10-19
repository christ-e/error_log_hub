import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:vansales_firebase_erorrs/app/modules/app_selection/controllers/app_selection_controller.dart';

class FirebaseAppManager {
  static const String appIdVanSales = 'vansales';
  static const String appIdEssFace = 'ess_face';
  static const String appIdBsms = 'bsms';
  static const String appIdEss = 'ess';

  /// Get the current active app ID from AppSelectionController or fallback to vansales
  static String getActiveAppId([String? overrideId]) {
    if (overrideId != null && overrideId.isNotEmpty) {
      return overrideId;
    }
    if (Get.isRegistered<AppSelectionController>()) {
      final selected = Get.find<AppSelectionController>().selectedApp.value;
      if (selected != null) return selected.id;
    }
    return appIdVanSales;
  }

  /// Get the Firestore instance for the requested app
  static FirebaseFirestore getFirestore([String? appId]) {
    final id = getActiveAppId(appId);
    if (id == appIdEssFace) {
      try {
        return FirebaseFirestore.instanceFor(app: Firebase.app('RealsoftHr'));
      } catch (e) {
        return FirebaseFirestore.instance;
      }
    }
    if (id == appIdEss || id == appIdBsms) {
      try {
        return FirebaseFirestore.instanceFor(app: Firebase.app('RealsoftErpApps'));
      } catch (e) {
        return FirebaseFirestore.instance;
      }
    }
    return FirebaseFirestore.instance;
  }

  /// Primary exception collection name
  static String getExceptionCollection([String? appId]) {
    final id = getActiveAppId(appId);
    if (id == appIdEssFace) {
      return 'Function_Exception_Error';
    }
    if (id == appIdEss) {
      return 'ESS_exception_logs';
    }
    if (id == appIdBsms) {
      return 'BSMS-exception_logs';
    }
    return 'Exception';
  }

  /// 404 error collection name
  static String get404Collection([String? appId]) {
    final id = getActiveAppId(appId);
    if (id == appIdEssFace) {
      return 'Function_404_Error';
    }
    if (id == appIdEss) {
      return 'ESS_error_logs';
    }
    if (id == appIdBsms) {
      return 'BSMS_error_logs';
    }
    return 'FunctionError-404';
  }

  /// Available error collections for current app
  static List<String> getAvailableCollections([String? appId]) {
    final id = getActiveAppId(appId);
    if (id == appIdEssFace) {
      return const [
        'Function_Exception_Error',
        'Function_404_Error',
        'Punch_Error_404',
        'Punch_Exception_Error',
      ];
    }
    if (id == appIdBsms) {
      return const [
        'BSMS-exception_logs',
        'BSMS_error_logs',
      ];
    }
    if (id == appIdEss) {
      return const [
        'ESS_exception_logs',
        'ESS_error_logs',
      ];
    }
    return const [
      'Exception',
      'FunctionError-404',
    ];
  }
}
