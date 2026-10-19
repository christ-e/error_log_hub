import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/error_utils.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/firebase_app_manager.dart';

class EssErrorsController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  FirebaseFirestore get _firestore => FirebaseAppManager.getFirestore(FirebaseAppManager.appIdEss);
  String get _colExceptions => FirebaseAppManager.getExceptionCollection(FirebaseAppManager.appIdEss);
  String get _colApiErrors => FirebaseAppManager.get404Collection(FirebaseAppManager.appIdEss);

  StreamSubscription<QuerySnapshot>? _excSubscription;
  StreamSubscription<QuerySnapshot>? _apiErrSubscription;

  final RxBool isLoading = false.obs;
  final RxBool isLiveMode = true.obs;
  final RxInt selectedTabIndex = 1.obs; // Defaults to Exceptions as shown in screenshot
  final RxString connectionStatus = 'Connecting...'.obs;
  final RxString streamError = ''.obs;

  // Raw data from Firestore
  final RxList<Map<String, dynamic>> rawExceptions = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> rawApiErrors = <Map<String, dynamic>>[].obs;

  // Filtered lists displayed in UI
  final RxList<Map<String, dynamic>> filteredExceptions = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredApiErrors = <Map<String, dynamic>>[].obs;

  // Metrics
  final RxInt totalExceptions = 0.obs;
  final RxInt todayExceptions = 0.obs;
  final RxInt totalApiErrors = 0.obs;
  final RxInt todayApiErrors = 0.obs;

  // Search input
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  // Advanced Filters Form Controllers
  final TextEditingController filterDateController = TextEditingController();
  final TextEditingController filterEmpNameController = TextEditingController();
  final TextEditingController filterEmpIdController = TextEditingController();
  final TextEditingController filterBranchIdController = TextEditingController();

  // Active Applied Advanced Filters
  final RxString appliedDate = ''.obs;
  final RxString appliedEmpName = ''.obs;
  final RxString appliedEmpId = ''.obs;
  final RxString appliedBranchId = ''.obs;

  bool get hasAdvancedFilters =>
      appliedDate.value.isNotEmpty ||
      appliedEmpName.value.isNotEmpty ||
      appliedEmpId.value.isNotEmpty ||
      appliedBranchId.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    // 2 Main Tabs: API Errors (0) and Exceptions (1)
    tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    selectedTabIndex.value = 1;
    tabController.addListener(() {
      selectedTabIndex.value = tabController.index;
    });

    searchController.addListener(() {
      searchQuery.value = searchController.text.trim().toLowerCase();
      applyFilters();
    });

    fetchAllData();
  }

  @override
  void onClose() {
    _excSubscription?.cancel();
    _apiErrSubscription?.cancel();
    tabController.dispose();
    searchController.dispose();
    filterDateController.dispose();
    filterEmpNameController.dispose();
    filterEmpIdController.dispose();
    filterBranchIdController.dispose();
    super.onClose();
  }

  Future<void> fetchAllData() async {
    try {
      isLoading.value = true;
      streamError.value = '';
      connectionStatus.value = 'Connecting to RealsoftERP Firestore...';

      if (isLiveMode.value) {
        _subscribeToStreams();
      } else {
        await _fetchOnce();
      }
    } catch (e, s) {
      log('EssErrorsController fetchAllData error: $e', stackTrace: s);
      streamError.value = e.toString();
      connectionStatus.value = 'Connection failed';
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeToStreams() {
    _excSubscription?.cancel();
    _apiErrSubscription?.cancel();

    // 1. ESS Exceptions stream
    try {
      _excSubscription = _firestore
          .collection(_colExceptions)
          .limit(250)
          .snapshots()
          .listen((snap) {
        final docs = snap.docs.map((d) => {'id': d.id, '_col': _colExceptions, ...d.data()}).toList();
        _sortDocs(docs);
        rawExceptions.assignAll(docs);
        _updateMetrics();
        applyFilters();
        connectionStatus.value = 'Live Sync Active (${rawExceptions.length} Exc / ${rawApiErrors.length} API)';
      }, onError: (err) {
        log('ESS exception stream error: $err');
        streamError.value = 'Exceptions stream error: $err';
        connectionStatus.value = 'Sync error';
      });
    } catch (e) {
      log('ESS exception stream init error: $e');
      streamError.value = e.toString();
    }

    // 2. ESS API Error logs stream
    try {
      _apiErrSubscription = _firestore
          .collection(_colApiErrors)
          .limit(250)
          .snapshots()
          .listen((snap) {
        final docs = snap.docs.map((d) => {'id': d.id, '_col': _colApiErrors, ...d.data()}).toList();
        _sortDocs(docs);
        rawApiErrors.assignAll(docs);
        _updateMetrics();
        applyFilters();
        connectionStatus.value = 'Live Sync Active (${rawExceptions.length} Exc / ${rawApiErrors.length} API)';
      }, onError: (err) {
        log('ESS API error stream error: $err');
        streamError.value = 'API error stream error: $err';
      });
    } catch (e) {
      log('ESS API error stream init error: $e');
    }
  }

  Future<void> _fetchOnce() async {
    try {
      final excSnap = await _firestore.collection(_colExceptions).limit(250).get();
      final excDocs = excSnap.docs.map((d) => {'id': d.id, '_col': _colExceptions, ...d.data()}).toList();
      _sortDocs(excDocs);
      rawExceptions.assignAll(excDocs);
    } catch (e) {
      log('Error getting ESS exceptions once: $e');
      streamError.value = 'Error fetching exceptions: $e';
    }

    try {
      final apiSnap = await _firestore.collection(_colApiErrors).limit(250).get();
      final apiDocs = apiSnap.docs.map((d) => {'id': d.id, '_col': _colApiErrors, ...d.data()}).toList();
      _sortDocs(apiDocs);
      rawApiErrors.assignAll(apiDocs);
    } catch (e) {
      log('Error getting ESS API errors once: $e');
    }

    connectionStatus.value = 'Manual Snapshot Loaded';
    _updateMetrics();
    applyFilters();
  }

  void _sortDocs(List<Map<String, dynamic>> docs) {
    docs.sort((a, b) {
      final dtA = DateTimeHelper.extractDateTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = DateTimeHelper.extractDateTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dtB.compareTo(dtA);
    });
  }

  void _updateMetrics() {
    totalExceptions.value = rawExceptions.length;
    todayExceptions.value = rawExceptions.where((d) => DateTimeHelper.isToday(DateTimeHelper.extractDateTime(d))).length;

    totalApiErrors.value = rawApiErrors.length;
    todayApiErrors.value = rawApiErrors.where((d) => DateTimeHelper.isToday(DateTimeHelper.extractDateTime(d))).length;
  }

  void applyFilters() {
    final query = searchQuery.value;
    final dateFilter = appliedDate.value.toLowerCase();
    final empFilter = appliedEmpName.value.toLowerCase();
    final empIdFilter = appliedEmpId.value.toLowerCase();
    final branchFilter = appliedBranchId.value.toLowerCase();

    bool matchesDoc(Map<String, dynamic> doc) {
      // Date filter
      if (dateFilter.isNotEmpty) {
        final docDate = (doc['date'] ?? '').toString().toLowerCase();
        if (!docDate.contains(dateFilter)) return false;
      }
      // Employee name filter
      if (empFilter.isNotEmpty) {
        final docEmp = (doc['empName'] ?? '').toString().toLowerCase();
        if (!docEmp.contains(empFilter)) return false;
      }
      // Employee ID filter
      if (empIdFilter.isNotEmpty) {
        final docEmpId = (doc['empId'] ?? '').toString().toLowerCase();
        if (!docEmpId.contains(empIdFilter)) return false;
      }
      // Branch ID filter
      if (branchFilter.isNotEmpty) {
        final docBranch = (doc['branchId'] ?? '').toString().toLowerCase();
        if (!docBranch.contains(branchFilter)) return false;
      }
      // General search query
      if (query.isNotEmpty && !_matchesQuery(doc, query)) return false;

      return true;
    }

    filteredExceptions.assignAll(rawExceptions.where(matchesDoc));
    filteredApiErrors.assignAll(rawApiErrors.where(matchesDoc));
  }

  bool _matchesQuery(Map<String, dynamic> doc, String query) {
    final fn = (doc['functionName'] ?? doc['Function'] ?? '').toString().toLowerCase();
    final err = (doc['errorDetails'] ?? doc['error'] ?? doc['message'] ?? '').toString().toLowerCase();
    final emp = (doc['empName'] ?? '').toString().toLowerCase();
    final empId = (doc['empId'] ?? '').toString().toLowerCase();
    final branch = (doc['branchId'] ?? '').toString().toLowerCase();
    final rsn = (doc['rsnId'] ?? doc['RSNID'] ?? '').toString().toLowerCase();
    final params = (doc['params'] ?? '').toString().toLowerCase();
    final ver = (doc['appVersion'] ?? '').toString().toLowerCase();
    final date = (doc['date'] ?? '').toString().toLowerCase();
    final time = (doc['time'] ?? '').toString().toLowerCase();

    return fn.contains(query) ||
        err.contains(query) ||
        emp.contains(query) ||
        empId.contains(query) ||
        branch.contains(query) ||
        rsn.contains(query) ||
        params.contains(query) ||
        ver.contains(query) ||
        date.contains(query) ||
        time.contains(query);
  }

  void applyAdvancedFilters() {
    appliedDate.value = filterDateController.text.trim();
    appliedEmpName.value = filterEmpNameController.text.trim();
    appliedEmpId.value = filterEmpIdController.text.trim();
    appliedBranchId.value = filterBranchIdController.text.trim();
    applyFilters();
  }

  void clearAdvancedFilters() {
    filterDateController.clear();
    filterEmpNameController.clear();
    filterEmpIdController.clear();
    filterBranchIdController.clear();
    appliedDate.value = '';
    appliedEmpName.value = '';
    appliedEmpId.value = '';
    appliedBranchId.value = '';
    applyFilters();
  }

  void toggleLiveMode() {
    isLiveMode.value = !isLiveMode.value;
    if (isLiveMode.value) {
      _subscribeToStreams();
      Get.snackbar(
        'Live Monitoring',
        'Real-time stream activated for ESS App',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF8B5CF6),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      _excSubscription?.cancel();
      _apiErrSubscription?.cancel();
      connectionStatus.value = 'Stream Paused';
      Get.snackbar(
        'Live Monitoring Paused',
        'Real-time updates paused. Tap refresh to update.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E1A33),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> deleteException(String id) async {
    try {
      await _firestore.collection(_colExceptions).doc(id).delete();
      rawExceptions.removeWhere((d) => d['id'] == id);
      _updateMetrics();
      applyFilters();
      Get.snackbar('Deleted', 'Exception record removed', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteApiError(String id) async {
    try {
      await _firestore.collection(_colApiErrors).doc(id).delete();
      rawApiErrors.removeWhere((d) => d['id'] == id);
      _updateMetrics();
      applyFilters();
      Get.snackbar('Deleted', 'API error record removed', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void copyToClipboard(String text, [String label = 'Copied to clipboard']) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      label,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1E1A33),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> exportErrorsCsv() async {
    try {
      final List<List<dynamic>> rows = [
        [
          'Type',
          'Document ID',
          'Function Name',
          'Error Details',
          'Employee Name',
          'Employee ID',
          'Branch ID',
          'RSN ID',
          'App Version',
          'Date',
          'Time',
          'Params',
          'Stack Trace',
        ]
      ];

      for (final doc in filteredExceptions) {
        rows.add([
          'Exception',
          doc['id'] ?? '',
          doc['functionName'] ?? doc['Function'] ?? '',
          doc['errorDetails'] ?? doc['error'] ?? '',
          doc['empName'] ?? '',
          doc['empId'] ?? '',
          doc['branchId'] ?? '',
          doc['rsnId'] ?? doc['RSNID'] ?? '',
          doc['appVersion'] ?? '',
          doc['date'] ?? '',
          doc['time'] ?? '',
          doc['params'] ?? '',
          doc['stack'] ?? doc['Stack'] ?? '',
        ]);
      }

      for (final doc in filteredApiErrors) {
        rows.add([
          'API Error',
          doc['id'] ?? '',
          doc['functionName'] ?? doc['Function'] ?? '',
          doc['errorDetails'] ?? doc['error'] ?? '',
          doc['empName'] ?? '',
          doc['empId'] ?? '',
          doc['branchId'] ?? '',
          doc['rsnId'] ?? doc['RSNID'] ?? '',
          doc['appVersion'] ?? '',
          doc['date'] ?? '',
          doc['time'] ?? '',
          doc['params'] ?? '',
          '',
        ]);
      }

      final csvData = csv.encode(rows);
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/ess_system_logs_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(filePath);
      await file.writeAsString(csvData);

      Get.snackbar(
        'Export Successful',
        'CSV exported: $filePath',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF8B5CF6),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('Export Failed', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}
