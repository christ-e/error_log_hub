import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/firebase_app_manager.dart';
import 'package:vansales_firebase_erorrs/app/routes/app_pages.dart';

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  final RxBool notificationsEnabled = true.obs;
  final RxBool soundEnabled = true.obs;

  // Per-app notification toggles
  final RxMap<String, bool> appNotifications = <String, bool>{
    'vansales': true,
    'ess_face': true,
    'ess': true,
    'bsms': true,
  }.obs;

  static const String channelId = 'error_logs_channel';
  static const String channelName = 'Error Log Alerts';
  static const String channelDesc = 'Real-time alerts for incoming fatal crashes and API error logs';

  // Callback storage for notification taps
  final Map<int, VoidCallback> _tapCallbacks = {};
  final Set<String> _notifiedDocIds = {};
  int _notificationCounter = 1000;

  final List<StreamSubscription> _globalSubscriptions = [];

  Future<NotificationService> init() async {
    try {
      // 1. Load saved preferences from disk
      await _loadPreferences();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.id != null && _tapCallbacks.containsKey(response.id)) {
            _tapCallbacks[response.id]?.call();
          } else {
            if (Get.currentRoute != Routes.ESS_ERRORS) {
              Get.toNamed(Routes.ESS_ERRORS);
            }
          }
        },
      );

      // Create high-importance Android channel
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        // Request Android 13+ permission
        await androidPlugin.requestNotificationsPermission();
      }

      // Start global monitoring across all error collections
      _startGlobalMonitoring();
    } catch (e) {
      log('NotificationService init error: $e');
    }
    return this;
  }

  /// Check whether notifications are enabled for a specific application
  bool isAppEnabled(String appId) {
    if (!notificationsEnabled.value) return false;
    return appNotifications[appId] ?? true;
  }

  /// Toggle notification on/off for a specific application
  Future<void> toggleAppNotification(String appId) async {
    final current = appNotifications[appId] ?? true;
    appNotifications[appId] = !current;
    await _savePreferences();

    final isNowOn = appNotifications[appId]!;
    Get.snackbar(
      isNowOn ? 'Alerts Activated' : 'Alerts Muted',
      'Push notifications for ${_getAppName(appId)} are now ${isNowOn ? "ON" : "OFF"}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1B1630),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
    );
  }

  String _getAppName(String appId) {
    switch (appId) {
      case 'vansales':
        return 'Van Sales';
      case 'ess_face':
        return 'Ess face';
      case 'ess':
        return 'ESS System Logs';
      case 'bsms':
        return 'BSMS';
      default:
        return appId.toUpperCase();
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_notifications_prefs.json');
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        data.forEach((k, v) {
          if (v is bool) appNotifications[k] = v;
        });
      }
    } catch (e) {
      log('Error loading notification preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_notifications_prefs.json');
      await file.writeAsString(jsonEncode(appNotifications));
    } catch (e) {
      log('Error saving notification preferences: $e');
    }
  }

  void _startGlobalMonitoring() {
    _cancelGlobalMonitoring();

    // 1. RealsoftErpApps (ESS System Logs)
    try {
      final erpFirestore = FirebaseAppManager.getFirestore(FirebaseAppManager.appIdEss);
      _listenToCollection(
        appId: 'ess',
        firestore: erpFirestore,
        collectionName: 'ESS_exception_logs',
        isException: true,
        targetRoute: Routes.ESS_ERRORS,
      );
      _listenToCollection(
        appId: 'ess',
        firestore: erpFirestore,
        collectionName: 'ESS_error_logs',
        isException: false,
        targetRoute: Routes.ESS_ERRORS,
      );
    } catch (e) {
      log('Error starting RealsoftErpApps monitoring: $e');
    }

    // 2. RealsoftHr (Ess Face Logs: Punch & Function Errors)
    try {
      final hrFirestore = FirebaseAppManager.getFirestore(FirebaseAppManager.appIdEssFace);
      _listenToCollection(
        appId: 'ess_face',
        firestore: hrFirestore,
        collectionName: 'Punch_Error_404',
        isException: false,
        targetRoute: Routes.ESS_FACE_ERRORS,
      );
      _listenToCollection(
        appId: 'ess_face',
        firestore: hrFirestore,
        collectionName: 'Punch_Exception_Error',
        isException: true,
        targetRoute: Routes.ESS_FACE_ERRORS,
      );
      _listenToCollection(
        appId: 'ess_face',
        firestore: hrFirestore,
        collectionName: 'Function_Exception_Error',
        isException: true,
        targetRoute: Routes.ESS_FACE_ERRORS,
      );
      _listenToCollection(
        appId: 'ess_face',
        firestore: hrFirestore,
        collectionName: 'Function_404_Error',
        isException: false,
        targetRoute: Routes.ESS_FACE_ERRORS,
      );
    } catch (e) {
      log('Error starting RealsoftHr monitoring: $e');
    }

    // 3. BSMS (RealsoftErpApps)
    try {
      final bsmsFirestore = FirebaseAppManager.getFirestore(FirebaseAppManager.appIdBsms);
      _listenToCollection(
        appId: 'bsms',
        firestore: bsmsFirestore,
        collectionName: 'BSMS-exception_logs',
        isException: true,
        targetRoute: Routes.BSMS_ERRORS,
      );
      _listenToCollection(
        appId: 'bsms',
        firestore: bsmsFirestore,
        collectionName: 'BSMS_error_logs',
        isException: false,
        targetRoute: Routes.BSMS_ERRORS,
      );
    } catch (e) {
      log('Error starting BSMS monitoring: $e');
    }

    // 4. Van Sales
    try {
      final vanFirestore = FirebaseFirestore.instance;
      _listenToCollection(
        appId: 'vansales',
        firestore: vanFirestore,
        collectionName: 'Exception',
        isException: true,
        targetRoute: Routes.HOME,
      );
      _listenToCollection(
        appId: 'vansales',
        firestore: vanFirestore,
        collectionName: 'FunctionError-404',
        isException: false,
        targetRoute: Routes.HOME,
      );
    } catch (e) {
      log('Error starting Van Sales monitoring: $e');
    }
  }

  void _listenToCollection({
    required String appId,
    required FirebaseFirestore firestore,
    required String collectionName,
    required bool isException,
    required String targetRoute,
  }) {
    try {
      bool isFirstLoad = true;
      final sub = firestore.collection(collectionName).snapshots().listen((snap) {
        if (isFirstLoad) {
          isFirstLoad = false;
          for (final doc in snap.docs) {
            _notifiedDocIds.add(doc.id);
          }
          log('Initialized monitor for $appId ($collectionName) with ${snap.docs.length} existing docs');
          return;
        }

        for (final change in snap.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final doc = {
              'id': change.doc.id,
              '_col': collectionName,
              ...change.doc.data() as Map<String, dynamic>,
            };
            log('New error detected in $appId ($collectionName): ${change.doc.id}');

            // Check if notifications are enabled for this specific app
            if (isAppEnabled(appId)) {
              notifyError(
                appId: appId,
                doc: doc,
                isException: isException,
                onInspect: () {
                  if (Get.currentRoute != targetRoute) {
                    Get.toNamed(targetRoute);
                  }
                },
              );
            } else {
              log('Push notification skipped: Alerts for app "$appId" are turned OFF by user.');
            }
          }
        }
      }, onError: (e) {
        log('Global monitor error on $appId ($collectionName): $e');
      });
      _globalSubscriptions.add(sub);
    } catch (e) {
      log('Failed to attach listener to $appId ($collectionName): $e');
    }
  }

  void _cancelGlobalMonitoring() {
    for (final s in _globalSubscriptions) {
      s.cancel();
    }
    _globalSubscriptions.clear();
  }

  @override
  void onClose() {
    _cancelGlobalMonitoring();
    super.onClose();
  }

  Future<void> testNotification([String? appId]) async {
    final targetApp = appId ?? 'ess';
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    notifyError(
      appId: targetApp,
      doc: {
        'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
        'functionName': '${_getAppName(targetApp)}_Alert_Test',
        'empName': 'Admin Test User',
        'empId': 'EMP100',
        'errorDetails': 'Simulated live error alert for ${_getAppName(targetApp)}.',
        'date': DateTime.now().toString().substring(0, 10),
        'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      },
      isException: true,
      onInspect: () {
        Get.snackbar(
          'Notification Working!',
          'Notification click callback passed for ${_getAppName(targetApp)}.',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
      },
    );
  }

  void toggleNotifications() {
    notificationsEnabled.value = !notificationsEnabled.value;
    Get.snackbar(
      notificationsEnabled.value ? 'All Alerts Enabled' : 'Master Mute Active',
      notificationsEnabled.value
          ? 'You will receive notifications for enabled apps'
          : 'All app notifications are muted',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1B1630),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Trigger both In-App alert banner and System Status Bar Notification
  void notifyError({
    String? appId,
    required Map<String, dynamic> doc,
    required bool isException,
    VoidCallback? onInspect,
  }) {
    if (!notificationsEnabled.value) return;
    if (appId != null && !isAppEnabled(appId)) {
      log('Notification suppressed: App "$appId" alerts are disabled.');
      return;
    }

    final docId = doc['id']?.toString() ?? '';
    if (docId.isNotEmpty) {
      if (_notifiedDocIds.contains(docId)) return;
      _notifiedDocIds.add(docId);
      if (_notifiedDocIds.length > 500) {
        _notifiedDocIds.remove(_notifiedDocIds.first);
      }
    }

    final fn = (doc['functionName'] ??
            doc['Function'] ??
            (doc['punchDicretion'] != null ? "Punch ${doc['punchDicretion']}" : null) ??
            'Unknown Function')
        .toString();
    final emp = (doc['empName'] ??
            (doc['person'] is Map ? doc['person']['empName'] : null) ??
            doc['empCode'] ??
            'Unknown Employee')
        .toString();
    final empId = (doc['empId'] ??
            (doc['person'] is Map ? doc['person']['empid'] : null) ??
            '')
        .toString();
    final errorMsg = (doc['errorDetails'] ??
            doc['error'] ??
            doc['message'] ??
            'Error occurred')
        .toString();
    final date = (doc['date'] ?? doc['Punch_Time/Date'] ?? '').toString();
    final time = (doc['time'] ?? '').toString();

    final employeeDisplay = empId.isNotEmpty && empId != 'Unknown' ? '$emp (#$empId)' : emp;
    final title = isException ? '🚨 CRASH: $fn' : '⚠️ API ERROR: $fn';

    // 1. Trigger System Status Bar Notification
    _showSystemNotification(
      title: title,
      body: '$employeeDisplay: $errorMsg',
      isException: isException,
      onTap: onInspect,
    );

    // 2. Trigger In-App Heads-Up Banner
    _showInAppBanner(
      fn: fn,
      emp: employeeDisplay,
      errorMsg: errorMsg,
      isException: isException,
      timeStr: time.isNotEmpty ? time : date,
      onInspect: onInspect,
    );

    // 3. Haptic vibration
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  Future<void> _showSystemNotification({
    required String title,
    required String body,
    required bool isException,
    VoidCallback? onTap,
  }) async {
    try {
      final notifId = _notificationCounter++;
      if (onTap != null) {
        _tapCallbacks[notifId] = onTap;
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        color: isException ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          htmlFormatContent: false,
          htmlFormatContentTitle: false,
        ),
        playSound: soundEnabled.value,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notifId,
        title,
        body,
        platformDetails,
      );
    } catch (e) {
      log('Error showing system notification: $e');
    }
  }

  void _showInAppBanner({
    required String fn,
    required String emp,
    required String errorMsg,
    required bool isException,
    required String timeStr,
    VoidCallback? onInspect,
  }) {
    final borderColor = isException ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final badgeColor = isException ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final badgeBg = isException ? const Color(0xFF2A131E) : const Color(0xFF0E2A24);

    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: EdgeInsets.zero,
      duration: const Duration(seconds: 6),
      messageText: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161226),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isException ? Icons.flash_on_rounded : Icons.cloud_off_rounded,
                        size: 12,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isException ? 'NEW EXCEPTION' : 'NEW API ERROR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (timeStr.isNotEmpty)
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => Get.closeCurrentSnackbar(),
                  child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              fn,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '👤 $emp',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              errorMsg,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFFCBD5E1),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: borderColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.visibility_rounded, size: 14),
                    label: const Text('INSPECT NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Get.closeCurrentSnackbar();
                      onInspect?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
