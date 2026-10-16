import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/error_utils.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/firebase_app_manager.dart';
import 'package:vansales_firebase_erorrs/app/modules/app_selection/controllers/app_selection_controller.dart';
import 'package:vansales_firebase_erorrs/app/modules/exception_eroor/controllers/exception_eroor_controller.dart';
import 'package:vansales_firebase_erorrs/app/modules/function_eroor_404/controllers/function_eroor_404_controller.dart';
import 'package:vansales_firebase_erorrs/app/routes/app_pages.dart';

class HomeController extends GetxController {
  RxBool isLoading = false.obs;
  Rx<AppItem?> currentApp = Rx<AppItem?>(null);

  RxInt totalExceptions = 0.obs;
  RxInt todayExceptions = 0.obs;
  RxInt totalFunction404 = 0.obs;
  RxInt todayFunction404 = 0.obs;

  RxList<MapEntry<String, int>> topCrashingFunctions = <MapEntry<String, int>>[].obs;
  RxList<Map<String, dynamic>> recentActivity = <Map<String, dynamic>>[].obs;

  // 📱 App Version & Routes Distribution
  RxList<VersionRouteGroup> versionGroups = <VersionRouteGroup>[].obs;
  RxString latestDetectedVersion = ''.obs;
  RxInt routesOnLatestVersion = 0.obs;
  RxInt totalUniqueRoutes = 0.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is AppItem) {
      currentApp.value = Get.arguments as AppItem;
    } else if (Get.isRegistered<AppSelectionController>()) {
      currentApp.value = Get.find<AppSelectionController>().selectedApp.value;
    }
    fetchDashboardMetrics();
  }

  Future<void> fetchDashboardMetrics() async {
    try {
      isLoading.value = true;

      final firestore = FirebaseAppManager.getFirestore(currentApp.value?.id);
      final excCol = FirebaseAppManager.getExceptionCollection(currentApp.value?.id);
      final f404Col = FirebaseAppManager.get404Collection(currentApp.value?.id);

      // 1. Fetch recent Exceptions
      Query excQuery = firestore.collection(excCol);
      QuerySnapshot excSnap;
      try {
        excSnap = await excQuery.orderBy('timestamp', descending: true).limit(100).get();
      } catch (_) {
        try {
          excSnap = await excQuery.orderBy('Servertimestamp', descending: true).limit(100).get();
        } catch (_) {
          excSnap = await excQuery.limit(100).get();
        }
      }

      final excDocs = excSnap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      totalExceptions.value = excDocs.length;
      todayExceptions.value = excDocs.where((d) => DateTimeHelper.isToday(DateTimeHelper.extractDateTime(d))).length;

      // 2. Fetch recent Function 404s
      Query f404Query = firestore.collection(f404Col);
      QuerySnapshot f404Snap;
      try {
        f404Snap = await f404Query.orderBy('Servertimestamp', descending: true).limit(100).get();
      } catch (_) {
        try {
          f404Snap = await f404Query.orderBy('timestamp', descending: true).limit(100).get();
        } catch (_) {
          f404Snap = await f404Query.limit(100).get();
        }
      }

      final f404Docs = f404Snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      totalFunction404.value = f404Docs.length;
      todayFunction404.value = f404Docs.where((d) => DateTimeHelper.isToday(DateTimeHelper.extractDateTime(d))).length;

      // 3. Top Crashing Functions across both collections
      final Map<String, int> functionCounts = {};
      for (final doc in excDocs) {
        final fn = (doc['Function'] ?? 'Unknown').toString().trim();
        if (fn.isNotEmpty && fn != 'Unknown') {
          functionCounts[fn] = (functionCounts[fn] ?? 0) + 1;
        }
      }
      for (final doc in f404Docs) {
        final fn = (doc['Function'] ?? 'Unknown').toString().trim();
        if (fn.isNotEmpty && fn != 'Unknown') {
          functionCounts[fn] = (functionCounts[fn] ?? 0) + 1;
        }
      }

      final sortedEntries = functionCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCrashingFunctions.value = sortedEntries.take(4).toList();

      // 4. Combined Recent Activity ticker (latest 5)
      final List<Map<String, dynamic>> combined = [
        ...excDocs.take(5).map((e) => {...e, '_type': 'Exception'}),
        ...f404Docs.take(5).map((e) => {...e, '_type': '404'}),
      ];
      combined.sort((a, b) {
        final dtA = DateTimeHelper.extractDateTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dtB = DateTimeHelper.extractDateTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dtB.compareTo(dtA);
      });
      recentActivity.value = combined.take(5).toList();

      // 5. Version & Route Analysis
      final allDocs = [...excDocs, ...f404Docs];
      final vGroups = VersionRouteAnalyzer.analyze(allDocs);
      versionGroups.value = vGroups;

      if (vGroups.isNotEmpty) {
        latestDetectedVersion.value = vGroups.first.version;
        routesOnLatestVersion.value = vGroups.first.routeCount;
      }
      totalUniqueRoutes.value = vGroups.expand((g) => g.routes).toSet().length;

    } catch (e, s) {
      log('fetchDashboardMetrics error: $e', stackTrace: s);
    } finally {
      isLoading.value = false;
    }
  }

  void openExceptionsWithFilter([TimeFilter? filter, String? appVersion]) {
    Get.toNamed(Routes.EXCEPTION_EROOR)?.then((_) {
      fetchDashboardMetrics();
    });
    if (Get.isRegistered<ExceptionEroorController>()) {
      final ctrl = Get.find<ExceptionEroorController>();
      if (filter != null) ctrl.setTimeFilter(filter);
      if (appVersion != null) {
        ctrl.selectedAppVersion.value = appVersion;
        ctrl.filter();
      }
    }
  }

  void openFunction404([String? appVersion]) {
    Get.toNamed(Routes.FUNCTION_EROOR_404)?.then((_) {
      fetchDashboardMetrics();
    });
    if (appVersion != null && Get.isRegistered<FunctionEroor404Controller>()) {
      final ctrl = Get.find<FunctionEroor404Controller>();
      ctrl.selectedAppVersion.value = appVersion;
      ctrl.filter();
    }
  }
}
