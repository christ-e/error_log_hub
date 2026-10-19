import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/error_utils.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/firebase_app_manager.dart';

enum EssTimeFilter { all, today, last24h, last7d }

enum PunchSubFilter { all, errors, exceptions }

enum UiSubFilter { all, errors404, exceptions }

enum ActivationStatusFilter { all, activeOnly, warningOnly }

class EssFaceErrorsController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  FirebaseFirestore get _firestore => FirebaseAppManager.getFirestore(FirebaseAppManager.appIdEssFace);

  // Exact 5 collections used by ESS Face FirestoreService:
  static const String colPunchError = 'Punch_Error_404';
  static const String colPunchException = 'Punch_Exception_Error';
  static const String colFunction404 = 'Function_404_Error';
  static const String colFunctionException = 'Function_Exception_Error';
  static const String colFaceActivation = 'FacePackageActivation_Error';

  StreamSubscription<QuerySnapshot>? _punchErrSub;
  StreamSubscription<QuerySnapshot>? _punchExcSub;
  StreamSubscription<QuerySnapshot>? _fn404Sub;
  StreamSubscription<QuerySnapshot>? _fnExcSub;
  StreamSubscription<QuerySnapshot>? _activationSub;

  final RxBool isLoading = false.obs;
  final RxBool isLiveMode = true.obs;
  final RxInt selectedTabIndex = 0.obs;
  final RxString connectionStatus = 'Connecting...'.obs;
  final RxString errorMessage = ''.obs;

  // 5 Raw Document Lists
  final RxList<Map<String, dynamic>> rawPunchErrors = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> rawPunchExceptions = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> rawFunctionErrors = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> rawFunctionExceptions = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> rawFaceActivationErrors = <Map<String, dynamic>>[].obs;

  // Filtered Document Lists
  final RxList<Map<String, dynamic>> filteredPunchErrors = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredPunchExceptions = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredFunctionErrors = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredFunctionExceptions = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredFaceActivationErrors = <Map<String, dynamic>>[].obs;

  // Sub-filters
  final Rx<PunchSubFilter> punchSubFilter = PunchSubFilter.all.obs;
  final Rx<UiSubFilter> uiSubFilter = UiSubFilter.all.obs;
  final Rx<ActivationStatusFilter> activationFilter = ActivationStatusFilter.all.obs;

  // Displayed Document Lists (fed to the tab bodies)
  final RxList<Map<String, dynamic>> displayedPunchDocs = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> displayedUiDocs = <Map<String, dynamic>>[].obs;

  // Metrics for all 5 databases
  final RxInt punchErrorsCount = 0.obs;
  final RxInt todayPunchErrors = 0.obs;

  final RxInt punchExceptionsCount = 0.obs;
  final RxInt todayPunchExceptions = 0.obs;

  final RxInt functionErrorsCount = 0.obs;
  final RxInt todayFunctionErrors = 0.obs;

  final RxInt functionExceptionsCount = 0.obs;
  final RxInt todayFunctionExceptions = 0.obs;

  final RxInt faceActivationErrorsCount = 0.obs;
  final RxInt todayFaceActivationErrors = 0.obs;

  int get totalPunchCount => punchErrorsCount.value + punchExceptionsCount.value;
  int get totalUiCount => functionErrorsCount.value + functionExceptionsCount.value;

  // Search & Filter
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final Rx<EssTimeFilter> selectedTimeFilter = EssTimeFilter.all.obs;

  // Face Package Activation Exact State Logic
  Map<String, dynamic>? get latestActivationDoc => rawFaceActivationErrors.isNotEmpty ? rawFaceActivationErrors.first : null;

  bool isDocActive(Map<String, dynamic> doc) {
    final state = doc['facepluginState'];
    if (state is int) {
      return state == 0;
    }
    final stateStr = state?.toString().trim();
    if (stateStr == '0') return true;
    final warn = (doc['warningState'] ?? '').toString().trim().toLowerCase();
    return warn == 'activated';
  }

  bool get isLatestLicenseActive {
    final doc = latestActivationDoc;
    if (doc == null) return false;
    return isDocActive(doc);
  }

  int get activeActivationCount => rawFaceActivationErrors.where(isDocActive).length;
  int get warningActivationCount => rawFaceActivationErrors.length - activeActivationCount;

  @override
  void onInit() {
    super.onInit();
    // 3 Main Tabs: Punch Errors (0), UI Errors (1), Face Activation (2)
    tabController = TabController(length: 3, vsync: this);
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
    _cancelSubscriptions();
    tabController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void _cancelSubscriptions() {
    _punchErrSub?.cancel();
    _punchExcSub?.cancel();
    _fn404Sub?.cancel();
    _fnExcSub?.cancel();
    _activationSub?.cancel();
  }

  Future<void> fetchAllData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      connectionStatus.value = 'Connecting to RealsoftHr Firestore...';

      if (isLiveMode.value) {
        _subscribeToAllStreams();
      } else {
        await _fetchOnce();
      }
    } catch (e, s) {
      log('EssFaceErrorsController fetchAllData error: $e', stackTrace: s);
      errorMessage.value = e.toString();
      connectionStatus.value = 'Connection failed';
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeToAllStreams() {
    _cancelSubscriptions();

    try {
      // 1. Punch_Error_404
      _punchErrSub = _firestore.collection(colPunchError).limit(100).snapshots().listen((snap) {
        final docs = snap.docs.map((d) => {'id': d.id, '_col': colPunchError, ...d.data()}).toList();
        _sortDocs(docs);
        rawPunchErrors.assignAll(docs);
        _updateMetrics();
        applyFilters();
      }, onError: (err) {
        log('Error in $colPunchError: $err');
        errorMessage.value = 'Punch_Error_404 stream error: $err';
      });

      // 2. Punch_Exception_Error
      _punchExcSub = _firestore.collection(colPunchException).limit(100).snapshots().listen((snap) {
        final docs = snap.docs.map((d) => {'id': d.id, '_col': colPunchException, ...d.data()}).toList();
        _sortDocs(docs);
        rawPunchExceptions.assignAll(docs);
        _updateMetrics();
        applyFilters();
      }, onError: (err) {
        log('Error in $colPunchException: $err');
      });

      // 3. Function_404_Error
      _fn404Sub = _firestore.collection(colFunction404).limit(100).snapshots().listen((snap) {
        final docs = snap.docs.map((d) => {'id': d.id, '_col': colFunction404, ...d.data()}).toList();
        _sortDocs(docs);
        rawFunctionErrors.assignAll(docs);
        _updateMetrics();
        applyFilters();
      }, onError: (err) {
        log('Error in $colFunction404: $err');
      });

      // 4. Function_Exception_Error
      _fnExcSub = _firestore.collection(colFunctionException).limit(100).snapshots().listen((snap) {
        final docs = snap.docs.map((d) => {'id': d.id, '_col': colFunctionException, ...d.data()}).toList();
        _sortDocs(docs);
        rawFunctionExceptions.assignAll(docs);
        _updateMetrics();
        applyFilters();
      }, onError: (err) {
        log('Error in $colFunctionException: $err');
      });

      // 5. FacePackageActivation_Error
      _activationSub = _firestore.collection(colFaceActivation).limit(100).snapshots().listen((snap) {
        final docs = snap.docs.map((d) => {'id': d.id, '_col': colFaceActivation, ...d.data()}).toList();
        _sortDocs(docs);
        rawFaceActivationErrors.assignAll(docs);
        _updateMetrics();
        applyFilters();
      }, onError: (err) {
        log('Error in $colFaceActivation: $err');
      });

      connectionStatus.value = '5 Real-time Streams Active';
    } catch (e) {
      log('Error establishing streams: $e');
      errorMessage.value = e.toString();
      connectionStatus.value = 'Stream setup failed';
    }
  }

  Future<void> _fetchOnce() async {
    try {
      final s1 = await _firestore.collection(colPunchError).limit(100).get();
      final docs1 = s1.docs.map((d) => {'id': d.id, '_col': colPunchError, ...d.data()}).toList();
      _sortDocs(docs1);
      rawPunchErrors.assignAll(docs1);

      final s2 = await _firestore.collection(colPunchException).limit(100).get();
      final docs2 = s2.docs.map((d) => {'id': d.id, '_col': colPunchException, ...d.data()}).toList();
      _sortDocs(docs2);
      rawPunchExceptions.assignAll(docs2);

      final s3 = await _firestore.collection(colFunction404).limit(100).get();
      final docs3 = s3.docs.map((d) => {'id': d.id, '_col': colFunction404, ...d.data()}).toList();
      _sortDocs(docs3);
      rawFunctionErrors.assignAll(docs3);

      final s4 = await _firestore.collection(colFunctionException).limit(100).get();
      final docs4 = s4.docs.map((d) => {'id': d.id, '_col': colFunctionException, ...d.data()}).toList();
      _sortDocs(docs4);
      rawFunctionExceptions.assignAll(docs4);

      final s5 = await _firestore.collection(colFaceActivation).limit(100).get();
      final docs5 = s5.docs.map((d) => {'id': d.id, '_col': colFaceActivation, ...d.data()}).toList();
      _sortDocs(docs5);
      rawFaceActivationErrors.assignAll(docs5);

      _updateMetrics();
      applyFilters();
      connectionStatus.value = '5 Databases Synced';
    } catch (e) {
      log('Error fetching once: $e');
      errorMessage.value = e.toString();
    }
  }

  void _sortDocs(List<Map<String, dynamic>> docs) {
    docs.sort((a, b) {
      final dtA = DateTimeHelper.extractDateTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = DateTimeHelper.extractDateTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dtB.compareTo(dtA);
    });
  }

  void _updateMetrics() {
    punchErrorsCount.value = rawPunchErrors.length;
    todayPunchErrors.value = rawPunchErrors.where((d) => DateTimeHelper.isToday(DateTimeHelper.extractDateTime(d))).length;

    punchExceptionsCount.value = rawPunchExceptions.length;
    todayPunchExceptions.value = rawPunchExceptions.where((d) => DateTimeHelper.isToday(DateTimeHelper.extractDateTime(d))).length;

    functionErrorsCount.value = rawFunctionErrors.length;
    todayFunctionErrors.value = rawFunctionErrors.where((d) => DateTimeHelper.isToday(DateTimeHelper.extractDateTime(d))).length;

    functionExceptionsCount.value = rawFunctionExceptions.length;
    todayFunctionExceptions.value = rawFunctionExceptions.where((d) => DateTimeHelper.isToday(DateTimeHelper.extractDateTime(d))).length;

    faceActivationErrorsCount.value = rawFaceActivationErrors.length;
    todayFaceActivationErrors.value = rawFaceActivationErrors.where((d) => DateTimeHelper.isToday(DateTimeHelper.extractDateTime(d))).length;
  }

  void applyFilters() {
    final query = searchQuery.value;
    final timeFilter = selectedTimeFilter.value;

    final pErrors = rawPunchErrors.where((d) => _matchesFilter(d, query, timeFilter)).toList();
    final pExceptions = rawPunchExceptions.where((d) => _matchesFilter(d, query, timeFilter)).toList();
    final uErrors = rawFunctionErrors.where((d) => _matchesFilter(d, query, timeFilter)).toList();
    final uExceptions = rawFunctionExceptions.where((d) => _matchesFilter(d, query, timeFilter)).toList();

    // Face Activation filtering
    final aErrors = rawFaceActivationErrors.where((d) {
      if (!_matchesFilter(d, query, timeFilter)) return false;
      if (activationFilter.value == ActivationStatusFilter.activeOnly) {
        return isDocActive(d);
      }
      if (activationFilter.value == ActivationStatusFilter.warningOnly) {
        return !isDocActive(d);
      }
      return true;
    }).toList();

    filteredPunchErrors.assignAll(pErrors);
    filteredPunchExceptions.assignAll(pExceptions);
    filteredFunctionErrors.assignAll(uErrors);
    filteredFunctionExceptions.assignAll(uExceptions);
    filteredFaceActivationErrors.assignAll(aErrors);

    // Apply Punch SubFilter
    switch (punchSubFilter.value) {
      case PunchSubFilter.errors:
        displayedPunchDocs.assignAll(pErrors);
        break;
      case PunchSubFilter.exceptions:
        displayedPunchDocs.assignAll(pExceptions);
        break;
      case PunchSubFilter.all:
        final combined = [...pErrors, ...pExceptions];
        _sortDocs(combined);
        displayedPunchDocs.assignAll(combined);
        break;
    }

    // Apply UI SubFilter
    switch (uiSubFilter.value) {
      case UiSubFilter.errors404:
        displayedUiDocs.assignAll(uErrors);
        break;
      case UiSubFilter.exceptions:
        displayedUiDocs.assignAll(uExceptions);
        break;
      case UiSubFilter.all:
        final combined = [...uErrors, ...uExceptions];
        _sortDocs(combined);
        displayedUiDocs.assignAll(combined);
        break;
    }
  }

  bool _matchesFilter(Map<String, dynamic> doc, String query, EssTimeFilter filter) {
    if (filter != EssTimeFilter.all) {
      final dt = DateTimeHelper.extractDateTime(doc);
      if (filter == EssTimeFilter.today && !DateTimeHelper.isToday(dt)) return false;
      if (filter == EssTimeFilter.last24h && !DateTimeHelper.isLast24Hours(dt)) return false;
      if (filter == EssTimeFilter.last7d && !DateTimeHelper.isLast7Days(dt)) return false;
    }

    if (query.isNotEmpty) {
      final fn = (doc['function'] ?? doc['Function'] ?? '').toString().toLowerCase();
      final err = (doc['error'] ?? doc['message'] ?? '').toString().toLowerCase();
      final emp = (doc['EmpCode'] ?? doc['RSNID'] ?? doc['employeeId'] ?? '').toString().toLowerCase();
      final branch = (doc['Branch'] ?? '').toString().toLowerCase();
      final comp = (doc['Comapany'] ?? doc['comapany'] ?? '').toString().toLowerCase();
      final status = (doc['Punch_Status'] ?? doc['status'] ?? '').toString().toLowerCase();
      final params = (doc['params'] ?? '').toString().toLowerCase();
      final ver = (doc['AppVersion'] ?? doc['appVersion'] ?? '').toString().toLowerCase();
      final key = (doc['activationKey'] ?? doc['activationCode'] ?? doc['licenseKey'] ?? '').toString().toLowerCase();
      final pluginState = (doc['facepluginState'] ?? '').toString().toLowerCase();
      final warnState = (doc['warningState'] ?? '').toString().toLowerCase();

      final matches = fn.contains(query) ||
          err.contains(query) ||
          emp.contains(query) ||
          branch.contains(query) ||
          comp.contains(query) ||
          status.contains(query) ||
          params.contains(query) ||
          ver.contains(query) ||
          key.contains(query) ||
          pluginState.contains(query) ||
          warnState.contains(query);

      if (!matches) return false;
    }

    return true;
  }

  void setTimeFilter(EssTimeFilter filter) {
    selectedTimeFilter.value = filter;
    applyFilters();
  }

  void setPunchSubFilter(PunchSubFilter filter) {
    punchSubFilter.value = filter;
    applyFilters();
  }

  void setUiSubFilter(UiSubFilter filter) {
    uiSubFilter.value = filter;
    applyFilters();
  }

  void setActivationFilter(ActivationStatusFilter filter) {
    activationFilter.value = filter;
    applyFilters();
  }

  void switchToPunchTab({PunchSubFilter? subFilter}) {
    tabController.animateTo(0);
    if (subFilter != null) {
      punchSubFilter.value = subFilter;
    }
    applyFilters();
  }

  void switchToUiTab({UiSubFilter? subFilter}) {
    tabController.animateTo(1);
    if (subFilter != null) {
      uiSubFilter.value = subFilter;
    }
    applyFilters();
  }

  void switchToActivationTab() {
    tabController.animateTo(2);
  }

  void toggleLiveMode() {
    isLiveMode.value = !isLiveMode.value;
    if (isLiveMode.value) {
      _subscribeToAllStreams();
      Get.snackbar(
        'Live Monitoring',
        'Real-time sync listening on all 5 ESS Face databases',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F766E),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      _cancelSubscriptions();
      connectionStatus.value = 'Live Sync Paused';
      Get.snackbar(
        'Live Monitoring Paused',
        'Streams paused. Pull to refresh manually.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> deleteDocument(String collection, String id) async {
    try {
      await _firestore.collection(collection).doc(id).delete();
      rawPunchErrors.removeWhere((d) => d['id'] == id);
      rawPunchExceptions.removeWhere((d) => d['id'] == id);
      rawFunctionErrors.removeWhere((d) => d['id'] == id);
      rawFunctionExceptions.removeWhere((d) => d['id'] == id);
      rawFaceActivationErrors.removeWhere((d) => d['id'] == id);

      _updateMetrics();
      applyFilters();
      Get.snackbar('Deleted', 'Record deleted from $collection', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void copyToClipboard(String text, [String label = 'Copied to clipboard']) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('Copied', label, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
  }
}
