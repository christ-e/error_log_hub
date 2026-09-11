import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/error_utils.dart';

enum TimeFilter { all, today, last24h, last7d }

class ExceptionEroorController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _liveSubscription;

  RxBool isLoading = false.obs;
  RxBool isLiveMode = false.obs;
  RxBool isGroupedMode = false.obs;

  RxList<Map<String, dynamic>> exceptions = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> unfilteredExceptions = <Map<String, dynamic>>[].obs;
  RxList<GroupedErrorItem> groupedExceptions = <GroupedErrorItem>[].obs;

  RxInt limit = 100.obs;
  Rx<TimeFilter> selectedTimeFilter = TimeFilter.all.obs;

  // Search & Filter fields
  RxString searchQuery = ''.obs;
  RxString selectedFunction = ''.obs;
  RxString selectedRouteName = ''.obs;
  RxString selectedDateKey = ''.obs;
  RxString selectedRsnId = ''.obs;
  RxString selectedAppVersion = ''.obs;
  RxList<String> availableVersions = <String>[].obs;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController functionController = TextEditingController();
  final TextEditingController routeController = TextEditingController();
  final TextEditingController rsnController = TextEditingController();
  final TextEditingController appVersionController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchExceptions();
  }

  @override
  void onClose() {
    _liveSubscription?.cancel();
    searchController.dispose();
    functionController.dispose();
    routeController.dispose();
    rsnController.dispose();
    appVersionController.dispose();
    super.onClose();
  }

  // 🔄 FETCH DATA
  Future<void> fetchExceptions() async {
    try {
      isLoading.value = true;

      Query query = _firestore.collection('Exception').orderBy('timestamp', descending: true);

      QuerySnapshot snap;
      if (limit.value == 0) {
        snap = await query.get();
      } else {
        snap = await query.limit(limit.value).get();
      }

      _processSnapshot(snap);
    } catch (e, s) {
      log('fetchExceptions error: $e', stackTrace: s);
      Get.snackbar(
        'Fetch Error',
        'Could not load exceptions: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 🟢 TOGGLE REAL-TIME LIVE MONITORING
  void toggleLiveMode() {
    isLiveMode.value = !isLiveMode.value;

    if (isLiveMode.value) {
      _startLiveListening();
      Get.snackbar(
        'Live Monitoring On',
        'Listening for live exceptions in real-time',
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
    Query query = _firestore.collection('Exception').orderBy('timestamp', descending: true);
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
    unfilteredExceptions.value = snap.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
    }).toList();

    final versions = <String>{};
    for (final doc in unfilteredExceptions) {
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

  // 🔍 INSTANT FILTER LOGIC
  void filter() {
    List<Map<String, dynamic>> data = List.from(unfilteredExceptions);

    // 1. Instant Text Search across all key fields
    if (searchQuery.value.trim().isNotEmpty) {
      final query = searchQuery.value.trim().toLowerCase();
      data = data.where((e) {
        final fn = (e['Function'] ?? '').toString().toLowerCase();
        final err = (e['error'] ?? '').toString().toLowerCase();
        final msg = (e['message'] ?? '').toString().toLowerCase();
        final route = (e['Route'] ?? '').toString().toLowerCase();
        final rsn = (e['RSNID'] ?? '').toString().toLowerCase();
        final ver = (e['appVersion'] ?? e['appversion'] ?? '').toString().toLowerCase();
        final date = (e['date'] ?? '').toString().toLowerCase();

        return fn.contains(query) ||
            err.contains(query) ||
            msg.contains(query) ||
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

    // 3. Specific Function filter
    if (selectedFunction.value.isNotEmpty) {
      final input = selectedFunction.value.toUpperCase();
      data = data.where((e) {
        final fn = (e['Function'] ?? '').toString().toUpperCase();
        return fn.contains(input);
      }).toList();
    }

    // 4. Specific Route filter
    if (selectedRouteName.value.isNotEmpty) {
      final input = selectedRouteName.value.toUpperCase();
      data = data.where((e) {
        final route = (e['Route'] ?? '').toString().toUpperCase();
        return route.contains(input);
      }).toList();
    }

    // 5. Specific RSN ID filter
    if (selectedRsnId.value.isNotEmpty) {
      data = data.where((e) {
        return (e['RSNID'] ?? '').toString() == selectedRsnId.value;
      }).toList();
    }

    // 6. Specific Date filter
    if (selectedDateKey.value.isNotEmpty) {
      data = data.where((e) {
        return (e['date'] ?? '').toString() == selectedDateKey.value;
      }).toList();
    }

    // 7. Specific App Version filter
    if (selectedAppVersion.value.isNotEmpty) {
      final input = selectedAppVersion.value.toLowerCase().replaceAll(' ', '');
      data = data.where((e) {
        final ver = (e['appVersion'] ?? e['appversion'] ?? '').toString().toLowerCase().replaceAll(' ', '');
        return ver.contains(input);
      }).toList();
    }

    exceptions.value = data;
    groupedExceptions.value = GroupedErrorItem.group(data, isFunction404: false);
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
    selectedFunction.value = '';
    selectedRouteName.value = '';
    selectedRsnId.value = '';
    selectedDateKey.value = '';
    selectedAppVersion.value = '';
    functionController.clear();
    routeController.clear();
    rsnController.clear();
    appVersionController.clear();

    fetchExceptions();
  }

  // 🗑️ DELETE ONE
  Future<void> deleteException(String docId) async {
    try {
      await _firestore.collection('Exception').doc(docId).delete();

      exceptions.removeWhere((e) => e['id'] == docId);
      unfilteredExceptions.removeWhere((e) => e['id'] == docId);
      groupedExceptions.value = GroupedErrorItem.group(exceptions, isFunction404: false);

      Get.snackbar('Deleted', 'Exception deleted', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Delete failed', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void confirmDelete(String docId) {
    Get.defaultDialog(
      title: 'Delete Exception',
      middleText: 'Are you sure you want to delete this exception?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        deleteException(docId);
      },
    );
  }

  // 🗑️ DELETE GROUP (All occurrences of this error)
  Future<void> deleteGroup(GroupedErrorItem group) async {
    try {
      isLoading.value = true;
      final batch = _firestore.batch();
      final idsToRemove = <String>{};

      for (var item in group.instances) {
        final id = item['id'];
        if (id != null && id.toString().isNotEmpty) {
          final ref = _firestore.collection('Exception').doc(id.toString());
          batch.delete(ref);
          idsToRemove.add(id.toString());
        }
      }

      await batch.commit();

      exceptions.removeWhere((e) => idsToRemove.contains(e['id']));
      unfilteredExceptions.removeWhere((e) => idsToRemove.contains(e['id']));
      groupedExceptions.value = GroupedErrorItem.group(exceptions, isFunction404: false);

      Get.snackbar(
        'Group Deleted',
        'Deleted ${idsToRemove.length} occurrences',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete group', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void confirmDeleteGroup(GroupedErrorItem group) {
    Get.defaultDialog(
      title: 'Delete Issue Cluster',
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
  Future<void> deleteAllExceptions() async {
    try {
      isLoading.value = true;

      final batch = _firestore.batch();
      for (var item in unfilteredExceptions) {
        final id = item['id'];
        if (id != null) {
          final ref = _firestore.collection('Exception').doc(id.toString());
          batch.delete(ref);
        }
      }

      await batch.commit();

      exceptions.clear();
      unfilteredExceptions.clear();
      groupedExceptions.clear();

      Get.snackbar('Deleted', 'All exceptions deleted', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Delete all failed', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void confirmDeleteAll() {
    Get.defaultDialog(
      title: 'Delete All Exceptions',
      middleText: 'This action cannot be undone. Continue?',
      textConfirm: 'Delete All',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        deleteAllExceptions();
      },
    );
  }

  // 📥 EXPORT CSV
  Future<void> exportToCsv() async {
    try {
      if (exceptions.isEmpty) {
        Get.snackbar('Export Failed', 'No exceptions to export.', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      isLoading.value = true;

      StringBuffer csv = StringBuffer();
      csv.writeln('ID,Function,Error,Message,Date,Time,Route,RSNID,App Version');

      for (var item in exceptions) {
        csv.writeln('${item['id'] ?? ''},'
            '${item['Function'] ?? ''},'
            '${item['error']?.toString().replaceAll(',', ' ').replaceAll('\n', ' ') ?? ''},'
            '${item['message']?.toString().replaceAll(',', ' ').replaceAll('\n', ' ') ?? ''},'
            '${item['date'] ?? ''},'
            '${item['time'] ?? ''},'
            '${item['Route'] ?? ''},'
            '${item['RSNID'] ?? ''},'
            '${item['appVersion'] ?? item['appversion'] ?? ''}');
      }

      Directory downloadsDir = Directory('/storage/emulated/0/Download');
      Directory appFolder = Directory('${downloadsDir.path}/ExceptionErrors');

      if (!await appFolder.exists()) {
        await appFolder.create(recursive: true);
      }

      String fileName = "ExceptionErrors_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";
      String path = "${appFolder.path}/$fileName";

      File file = File(path);
      await file.writeAsString(csv.toString());

      Get.snackbar(
        'Success',
        'CSV saved to:\n$path',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      log("CSV Export error: $e");
      Get.snackbar('Error', 'Failed to export CSV', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // 📥 EXPORT EXCEL
  Future<void> exportToExcel() async {
    try {
      if (exceptions.isEmpty) {
        Get.snackbar('Export Failed', 'No exceptions to export.', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      isLoading.value = true;

      var excel = Excel.createExcel();
      Sheet sheet = excel['Exceptions'];

      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Function'),
        TextCellValue('Error'),
        TextCellValue('Message'),
        TextCellValue('Date'),
        TextCellValue('Time'),
        TextCellValue('Route'),
        TextCellValue('RSNID'),
        TextCellValue('App Version')
      ]);

      for (var item in exceptions) {
        sheet.appendRow([
          TextCellValue(item['id']?.toString() ?? ''),
          TextCellValue(item['Function']?.toString() ?? ''),
          TextCellValue(item['error']?.toString() ?? ''),
          TextCellValue(item['message']?.toString() ?? ''),
          TextCellValue(item['date']?.toString() ?? ''),
          TextCellValue(item['time']?.toString() ?? ''),
          TextCellValue(item['Route']?.toString() ?? ''),
          TextCellValue(item['RSNID']?.toString() ?? ''),
          TextCellValue((item['appVersion'] ?? item['appversion'])?.toString() ?? '')
        ]);
      }

      Directory downloadsDir = Directory('/storage/emulated/0/Download');
      Directory appFolder = Directory('${downloadsDir.path}/ExceptionErrors');

      if (!await appFolder.exists()) {
        await appFolder.create(recursive: true);
      }

      String fileName = "ExceptionErrors_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";
      String path = "${appFolder.path}/$fileName";

      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      Get.snackbar(
        'Success',
        'Excel saved to:\n$path',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      log("Excel export error: $e");
      Get.snackbar('Error', 'Excel export failed', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
