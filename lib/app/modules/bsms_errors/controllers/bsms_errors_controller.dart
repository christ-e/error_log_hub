import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/error_utils.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/firebase_app_manager.dart';

enum BsmsTimeFilter { all, today, last24h, last7d }

class BsmsErrorsController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  FirebaseFirestore get _firestore => FirebaseAppManager.getFirestore(FirebaseAppManager.appIdBsms);
  String get _exceptionCollection => FirebaseAppManager.getExceptionCollection(FirebaseAppManager.appIdBsms);
  String get _f404Collection => FirebaseAppManager.get404Collection(FirebaseAppManager.appIdBsms);

  StreamSubscription<QuerySnapshot>? _excSubscription;
  StreamSubscription<QuerySnapshot>? _f404Subscription;

  final RxBool isLoading = false.obs;
  final RxBool isLiveMode = true.obs;
  final RxInt selectedTabIndex = 0.obs;

  // Raw data
  final RxList<Map<String, dynamic>> rawExceptions = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> raw404Errors = <Map<String, dynamic>>[].obs;

  // Filtered lists
  final RxList<Map<String, dynamic>> filteredExceptions = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filtered404Errors = <Map<String, dynamic>>[].obs;

  // Metrics
  final RxInt totalExceptions = 0.obs;
  final RxInt todayExceptions = 0.obs;
  final RxInt total404Errors = 0.obs;
  final RxInt today404Errors = 0.obs;

  // Search & Filter
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final Rx<BsmsTimeFilter> selectedTimeFilter = BsmsTimeFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
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
    _f404Subscription?.cancel();
    tabController.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchAllData() async {
    try {
      isLoading.value = true;
      if (isLiveMode.value) {
        _subscribeToStreams();
      } else {
        await _fetchOnce();
      }
    } catch (e, s) {
      log('BsmsErrorsController fetchAllData error: $e', stackTrace: s);
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeToStreams() {
    _excSubscription?.cancel();
    _f404Subscription?.cancel();

    // 1. BSMS Exceptions stream
    try {
      _excSubscription = _firestore
          .collection(_exceptionCollection)
          .limit(150)
          .snapshots()
          .listen((snap) {
        final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        _sortDocs(docs);
        rawExceptions.assignAll(docs);
        _updateMetrics();
        applyFilters();
      }, onError: (err) {
        log('BSMS exception stream error: $err');
      });
    } catch (e) {
      log('BSMS exception stream initialization error: $e');
    }

    // 2. BSMS 404 stream
    try {
      _f404Subscription = _firestore
          .collection(_f404Collection)
          .limit(150)
          .snapshots()
          .listen((snap) {
        final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        _sortDocs(docs);
        raw404Errors.assignAll(docs);
        _updateMetrics();
        applyFilters();
      }, onError: (err) {
        log('BSMS 404 stream error: $err');
      });
    } catch (e) {
      log('BSMS 404 stream initialization error: $e');
    }
  }

  Future<void> _fetchOnce() async {
    try {
      final excSnap = await _firestore.collection(_exceptionCollection).limit(150).get();
      final excDocs = excSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _sortDocs(excDocs);
      rawExceptions.assignAll(excDocs);
    } catch (e) {
      log('Error getting BSMS exceptions once: $e');
    }

    try {
      final f404Snap = await _firestore.collection(_f404Collection).limit(150).get();
      final f404Docs = f404Snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _sortDocs(f404Docs);
      raw404Errors.assignAll(f404Docs);
    } catch (e) {
      log('Error getting BSMS 404s once: $e');
    }

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

    total404Errors.value = raw404Errors.length;
    today404Errors.value = raw404Errors.where((d) => DateTimeHelper.isToday(DateTimeHelper.extractDateTime(d))).length;
  }

  void applyFilters() {
    final query = searchQuery.value;
    final timeFilter = selectedTimeFilter.value;

    filteredExceptions.assignAll(rawExceptions.where((doc) {
      if (!_matchesTimeFilter(doc, timeFilter)) return false;
      if (query.isNotEmpty && !_matchesQuery(doc, query)) return false;
      return true;
    }));

    filtered404Errors.assignAll(raw404Errors.where((doc) {
      if (!_matchesTimeFilter(doc, timeFilter)) return false;
      if (query.isNotEmpty && !_matchesQuery(doc, query)) return false;
      return true;
    }));
  }

  bool _matchesTimeFilter(Map<String, dynamic> doc, BsmsTimeFilter filter) {
    if (filter == BsmsTimeFilter.all) return true;
    final dt = DateTimeHelper.extractDateTime(doc);
    switch (filter) {
      case BsmsTimeFilter.today:
        return DateTimeHelper.isToday(dt);
      case BsmsTimeFilter.last24h:
        return DateTimeHelper.isLast24Hours(dt);
      case BsmsTimeFilter.last7d:
        return DateTimeHelper.isLast7Days(dt);
      default:
        return true;
    }
  }

  bool _matchesQuery(Map<String, dynamic> doc, String query) {
    final fn = (doc['Function'] ?? '').toString().toLowerCase();
    final err = (doc['error'] ?? doc['message'] ?? '').toString().toLowerCase();
    final route = (doc['Route'] ?? doc['route'] ?? '').toString().toLowerCase();
    final room = (doc['roomNo'] ?? doc['bedId'] ?? doc['tenantId'] ?? doc['property'] ?? '').toString().toLowerCase();
    final url = (doc['url'] ?? doc['Url'] ?? doc['endpoint'] ?? '').toString().toLowerCase();

    return fn.contains(query) ||
        err.contains(query) ||
        route.contains(query) ||
        room.contains(query) ||
        url.contains(query);
  }

  void setTimeFilter(BsmsTimeFilter filter) {
    selectedTimeFilter.value = filter;
    applyFilters();
  }

  void toggleLiveMode() {
    isLiveMode.value = !isLiveMode.value;
    if (isLiveMode.value) {
      _subscribeToStreams();
      Get.snackbar(
        'Live Monitoring',
        'Real-time stream activated for BSMS',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF6D28D9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      _excSubscription?.cancel();
      _f404Subscription?.cancel();
      Get.snackbar(
        'Live Monitoring Paused',
        'Stream paused. Pull down to refresh manually.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> deleteException(String id) async {
    try {
      await _firestore.collection(_exceptionCollection).doc(id).delete();
      rawExceptions.removeWhere((d) => d['id'] == id);
      _updateMetrics();
      applyFilters();
      Get.snackbar('Deleted', 'Exception record removed', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> delete404Error(String id) async {
    try {
      await _firestore.collection(_f404Collection).doc(id).delete();
      raw404Errors.removeWhere((d) => d['id'] == id);
      _updateMetrics();
      applyFilters();
      Get.snackbar('Deleted', '404 error record removed', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void copyToClipboard(String text, [String label = 'Copied to clipboard']) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('Copied', label, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
  }
}
