import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/error_utils.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/firebase_app_manager.dart';
import 'package:vansales_firebase_erorrs/app/modules/exception_eroor/controllers/exception_eroor_controller.dart';

class FunctionEroor404Controller extends GetxController {
  FirebaseFirestore get _firestore => FirebaseAppManager.getFirestore();
  String get _collectionName => FirebaseAppManager.get404Collection();
  StreamSubscription<QuerySnapshot>? _liveSubscription;

  RxBool isLoading = false.obs;
  RxBool isLiveMode = false.obs;
  RxBool isGroupedMode = false.obs;

  RxList<Map<String, dynamic>> errors = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> unfilteredErrors = <Map<String, dynamic>>[].obs;
  RxList<GroupedErrorItem> groupedErrors = <GroupedErrorItem>[].obs;

  RxInt limit = 100.obs;
  Rx<TimeFilter> selectedTimeFilter = TimeFilter.all.obs;

  // Search & Filter fields
  RxString searchQuery = ''.obs;
  RxString selectedRsnId = ''.obs;
  RxString selectedRouteName = ''.obs;
  RxString selectedDateKey = ''.obs;
  RxString failedFunctionName = ''.obs;
  RxString selectedAppVersion = ''.obs;
  RxList<String> availableVersions = <String>[].obs;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController rsnController = TextEditingController();
  final TextEditingController routeController = TextEditingController();
  final TextEditingController failedFunctionNameController = TextEditingController();
  final TextEditingController appVersionController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchErrors();
  }

  @override
  void onClose() {
    _liveSubscription?.cancel();
    searchController.dispose();
    rsnController.dispose();
    routeController.dispose();
    failedFunctionNameController.dispose();
    appVersionController.dispose();
    super.onClose();
  }

  // 🔄 FETCH
  Future<void> fetchErrors() async {
    try {
      isLoading.value = true;

      Query query = _firestore.collection(_collectionName);
      try {
        query = query.orderBy('Servertimestamp', descending: true);
      } catch (_) {
        try {
          query = query.orderBy('timestamp', descending: true);
        } catch (_) {}
      }

      QuerySnapshot snap;
      if (limit.value == 0) {
        snap = await query.get();
      } else {
        snap = await query.limit(limit.value).get();
      }

      _processSnapshot(snap);
    } catch (e, s) {
      log('fetchErrors error: $e', stackTrace: s);
      Get.snackbar(
        'Fetch Error',
        'Could not load function errors: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 🟢 TOGGLE LIVE STREAM
  void toggleLiveMode() {
    isLiveMode.value = !isLiveMode.value;

    if (isLiveMode.value) {
      _startLiveListening();
      Get.snackbar(
        'Live Monitoring On',
        'Listening for Function 404 errors in real-time',
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } else {
      _liveSubscription?.cancel();
      _liveSubscription = null;
      Get.snackbar(
        'Live Monitoring Paused',
        'Switched to manual refresh',
        backgroundColor: Colors.grey.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _startLiveListening() {
    _liveSubscription?.cancel();
    Query query = _firestore.collection(_collectionName);
    try {
      query = query.orderBy('Servertimestamp', descending: true);
    } catch (_) {
      try {
        query = query.orderBy('timestamp', descending: true);
      } catch (_) {}
    }
    if (limit.value > 0) {
      query = query.limit(limit.value);
    }

    _liveSubscription = query.snapshots().listen(
      (snap) {
        _processSnapshot(snap);
      },
      onError: (e) {
        log('Live stream error: $e');
      },
    );
  }

  void _processSnapshot(QuerySnapshot snap) {
    unfilteredErrors.value = snap.docs.map((doc) {
      return {
        'id': doc.id, // 🔑 CRITICAL FIX: Retain doc.id for delete/exports
        ...doc.data() as Map<String, dynamic>,
      };
    }).toList();

    final versions = <String>{};
    for (final doc in unfilteredErrors) {
      final v = (doc['appVersion'] ?? doc['appversion'] ?? '').toString().trim();
      if (v.isNotEmpty) versions.add(v);
    }
    availableVersions.value = versions.toList()..sort();

    filter();
  }

  void setVersionFilter(String version) {
    if (selectedAppVersion.value == version) {
      selectedAppVersion.value = '';
    } else {
      selectedAppVersion.value = version;
    }
    filter();
  }

  // 🔍 FILTER LOGIC
  void filter() {
    List<Map<String, dynamic>> data = List.from(unfilteredErrors);

    // 1. Instant text search
    if (searchQuery.value.trim().isNotEmpty) {
      final query = searchQuery.value.trim().toLowerCase();
      data = data.where((e) {
        final fn = (e['Function'] ?? '').toString().toLowerCase();
        final msg = (e['message'] ?? '').toString().toLowerCase();
        final err = (e['error'] ?? '').toString().toLowerCase();
        final route = (e['Route'] ?? '').toString().toLowerCase();
        final rsn = (e['RSNID'] ?? '').toString().toLowerCase();
        final ver = (e['appVersion'] ?? e['appversion'] ?? '').toString().toLowerCase();
        final date = (e['date'] ?? '').toString().toLowerCase();

        return fn.contains(query) ||
            msg.contains(query) ||
            err.contains(query) ||
            route.contains(query) ||
            rsn.contains(query) ||
            ver.contains(query) ||
            date.contains(query);
      }).toList();
    }

    // 2. Quick Time Filter
    if (selectedTimeFilter.value != TimeFilter.all) {
      data = data.where((e) {
        final dt = DateTimeHelper.extractDateTime(e);
        switch (selectedTimeFilter.value) {
          case TimeFilter.today:
            return DateTimeHelper.isToday(dt);
          case TimeFilter.last24h:
            return DateTimeHelper.isLast24Hours(dt);
          case TimeFilter.last7d:
            return DateTimeHelper.isLast7Days(dt);
          case TimeFilter.all:
            return true;
        }
      }).toList();
    }

    // 3. Filter by RSNID
    if (selectedRsnId.value.isNotEmpty) {
      data = data.where((e) {
        return (e['RSNID'] ?? '').toString() == selectedRsnId.value;
      }).toList();
    }

    // 4. Filter by Route
    if (selectedRouteName.value.isNotEmpty) {
      final input = selectedRouteName.value.toUpperCase();
      data = data.where((e) {
        final route = (e['Route'] ?? '').toString().toUpperCase();
        return route.contains(input);
      }).toList();
    }

    // 5. Filter by Date
    if (selectedDateKey.value.isNotEmpty) {
      data = data.where((e) {
        return (e['date'] ?? '').toString() == selectedDateKey.value;
      }).toList();
    }

    // 6. Filter by Function Name
    if (failedFunctionName.value.isNotEmpty) {
      final input = failedFunctionName.value.toLowerCase().replaceAll(' ', '');
      data = data.where((e) {
        final functionName = (e['Function'] ?? '').toString().toLowerCase().replaceAll(' ', '');
        return functionName.contains(input);
      }).toList();
    }

    // 7. Filter by App Version
    if (selectedAppVersion.value.isNotEmpty) {
      final input = selectedAppVersion.value.toLowerCase().replaceAll(' ', '');
      data = data.where((e) {
        final appVersion = (e['appVersion'] ?? e['appversion'] ?? '').toString().toLowerCase().replaceAll(' ', '');
        return appVersion.contains(input);
      }).toList();
    }

    errors.value = data;
    groupedErrors.value = GroupedErrorItem.group(data, isFunction404: true);
  }

  void onSearchChanged(String val) {
    searchQuery.value = val;
    filter();
  }

  void setTimeFilter(TimeFilter filterType) {
    selectedTimeFilter.value = filterType;
    filter();
  }

  void toggleViewMode() {
    isGroupedMode.value = !isGroupedMode.value;
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: Get.context!,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      selectedDateKey.value = DateFormat('MMMM dd, yyyy').format(date);
      filter();
    }
  }

  void clearFilters() {
    searchQuery.value = '';
    searchController.clear();
    selectedTimeFilter.value = TimeFilter.all;
    selectedRsnId.value = '';
    selectedDateKey.value = '';
    selectedRouteName.value = '';
    failedFunctionName.value = '';
    selectedAppVersion.value = '';
    rsnController.clear();
    routeController.clear();
    failedFunctionNameController.clear();
    appVersionController.clear();

    fetchErrors();
  }

  // 🗑️ DELETE ONE
  Future<void> deleteError(String docId) async {
    try {
      await _firestore.collection(_collectionName).doc(docId).delete();

      errors.removeWhere((e) => e['id'] == docId);
      unfilteredErrors.removeWhere((e) => e['id'] == docId);
      groupedErrors.value = GroupedErrorItem.group(errors, isFunction404: true);

      Get.snackbar(
        'Deleted',
        'Error deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void confirmDelete(String docId) {
    Get.defaultDialog(
      title: 'Delete Error',
      middleText: 'Are you sure you want to delete this error?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        deleteError(docId);
      },
    );
  }

  // 🗑️ DELETE GROUP
  Future<void> deleteGroup(GroupedErrorItem group) async {
    try {
      isLoading.value = true;
      final batch = _firestore.batch();
      final idsToRemove = <String>{};

      for (var item in group.instances) {
        final id = item['id'];
        if (id != null && id.toString().isNotEmpty) {
          final ref = _firestore.collection(_collectionName).doc(id.toString());
          batch.delete(ref);
          idsToRemove.add(id.toString());
        }
      }

      await batch.commit();

      errors.removeWhere((e) => idsToRemove.contains(e['id']));
      unfilteredErrors.removeWhere((e) => idsToRemove.contains(e['id']));
      groupedErrors.value = GroupedErrorItem.group(errors, isFunction404: true);

      Get.snackbar(
        'Cluster Deleted',
        'Deleted ${idsToRemove.length} occurrences',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete cluster', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void confirmDeleteGroup(GroupedErrorItem group) {
    Get.defaultDialog(
      title: 'Delete Error Cluster',
      middleText: 'Delete all ${group.count} occurrences of "${group.functionName}"?',
      textConfirm: 'Delete All',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        deleteGroup(group);
      },
    );
  }

  // 🧨 DELETE ALL
  Future<void> deleteAllErrors() async {
    try {
      isLoading.value = true;

      final batch = _firestore.batch();

      for (var item in unfilteredErrors) {
        final docId = item['id'];
        if (docId != null) {
          final ref = _firestore.collection(_collectionName).doc(docId.toString());
          batch.delete(ref);
        }
      }

      await batch.commit();

      errors.clear();
      unfilteredErrors.clear();
      groupedErrors.clear();

      Get.snackbar(
        'Deleted',
        'All errors deleted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete all',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void confirmDeleteAll() {
    Get.defaultDialog(
      title: 'Delete All Errors',
      middleText: 'This action cannot be undone. Continue?',
      textConfirm: 'Delete All',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        deleteAllErrors();
      },
    );
  }

  // 📥 EXPORT CSV
  Future<void> exportToCsv() async {
    try {
      if (errors.isEmpty) {
        Get.snackbar(
          'Export Failed',
          'No errors to export for the selected filter.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      isLoading.value = true;

      StringBuffer csv = StringBuffer();
      csv.writeln('ID,Function,Message,Date,Time,Route,RSNID,App Version');

      for (var item in errors) {
        csv.writeln('${item['id'] ?? ''},'
            '${item['Function'] ?? ''},'
            '${item['message']?.toString().replaceAll(',', ' ').replaceAll('\n', ' ') ?? ''},'
            '${item['date'] ?? ''},'
            '${item['time'] ?? ''},'
            '${item['Route'] ?? ''},'
            '${item['RSNID'] ?? ''},'
            '${item['appVersion'] ?? item['appversion'] ?? ''}');
      }

      Directory downloadsDir = Directory('/storage/emulated/0/Download');
      Directory appFolder = Directory('${downloadsDir.path}/FunctionErrors');

      if (!await appFolder.exists()) {
        await appFolder.create(recursive: true);
      }

      String fileName = "FunctionErrors_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";
      String path = "${appFolder.path}/$fileName";

      File file = File(path);
      await file.writeAsString(csv.toString());

      Get.snackbar(
        'Success',
        'CSV saved to:\n$path',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      log("CSV Export error: $e");
      Get.snackbar(
        'Error',
        'Failed to export CSV',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 📥 EXPORT EXCEL
  Future<void> exportToExcel() async {
    try {
      if (errors.isEmpty) {
        Get.snackbar(
          'Export Failed',
          'No errors to export.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;

      var excel = Excel.createExcel();
      Sheet sheet = excel['Errors'];

      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Function'),
        TextCellValue('Message'),
        TextCellValue('Date'),
        TextCellValue('Time'),
        TextCellValue('Route'),
        TextCellValue('RSNID'),
        TextCellValue('App Version')
      ]);

      for (var item in errors) {
        sheet.appendRow([
          TextCellValue(item['id']?.toString() ?? ''),
          TextCellValue(item['Function']?.toString() ?? ''),
          TextCellValue(item['message']?.toString() ?? ''),
          TextCellValue(item['date']?.toString() ?? ''),
          TextCellValue(item['time']?.toString() ?? ''),
          TextCellValue(item['Route']?.toString() ?? ''),
          TextCellValue(item['RSNID']?.toString() ?? ''),
          TextCellValue((item['appVersion'] ?? item['appversion'])?.toString() ?? '')
        ]);
      }

      Directory downloadsDir = Directory('/storage/emulated/0/Download');
      Directory appFolder = Directory('${downloadsDir.path}/FunctionErrors');

      if (!await appFolder.exists()) {
        await appFolder.create(recursive: true);
      }

      String fileName = "FunctionErrors_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";
      String path = "${appFolder.path}/$fileName";

      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      Get.snackbar(
        'Success',
        'Excel saved to:\n$path',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      log("Excel export error $e");
      Get.snackbar(
        'Error',
        'Excel export failed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
