import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/error_utils.dart';
import '../controllers/ess_errors_controller.dart';

class EssErrorsView extends GetView<EssErrorsController> {
  const EssErrorsView({super.key});

  // Dark Cyber / System Logs Theme Palette
  static const Color bgDark = Color(0xFF0C0A17);
  static const Color surfaceDark = Color(0xFF161226);
  static const Color surfaceElevated = Color(0xFF1B1630);
  static const Color inputBg = Color(0xFF17132B);
  static const Color borderDark = Color(0xFF262044);
  static const Color borderSubtle = Color(0xFF201B3A);

  // Neon & Brand Accents
  static const Color purplePrimary = Color(0xFF8B5CF6);
  static const Color purpleDeep = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFA855F7);
  static const Color tealNeon = Color(0xFF10B981);
  static const Color tealSubtle = Color(0xFF0E2A24);
  static const Color redNeon = Color(0xFFEF4444);
  static const Color redPinkNeon = Color(0xFFF43F5E);
  static const Color redSubtle = Color(0xFF2A131E);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // 🔝 Top App Header Bar
            _buildTopAppBar(),

            // 🔍 Search Bar & Glowing Filter Button Row
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  // Search Input Box
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderDark),
                      ),
                      child: TextField(
                        controller: controller.searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search logs...',
                          hintStyle: const TextStyle(color: textDim, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: tealNeon, size: 20),
                          suffixIcon: Obx(
                            () => controller.searchQuery.value.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: textDim, size: 18),
                                    onPressed: controller.searchController.clear,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 🎛️ Glowing Advanced Filter Button
                  _buildAdvancedFilterButton(),
                ],
              ),
            ),

            // 🏷️ Active Filter Indicator Banner (if applied)
            _buildActiveFilterIndicator(),

            // 📑 2 Main Tabs: "API Errors" and "Exceptions"
            _buildTabBar(),

            // 📋 Tab Views Content
            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: [
                  // Tab 0: API Errors
                  _buildLogList(isException: false),

                  // Tab 1: Exceptions
                  _buildLogList(isException: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔝 Top Bar with Network Node Logo, Title & Actions
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
            tooltip: 'Back',
            onPressed: () => Get.back(),
          ),
          const SizedBox(width: 4),

          // Glowing Network Hub Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: purplePrimary.withValues(alpha: 0.15),
              border: Border.all(color: purplePrimary.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.hub_rounded,
              color: purpleLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Title: SYSTEM LOGS
          const Expanded(
            child: Text(
              'SYSTEM LOGS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
          ),

          // Live Stream Toggle Icon
          Obx(
            () => IconButton(
              tooltip: controller.isLiveMode.value ? 'Live Monitoring Active' : 'Live Paused',
              icon: Icon(
                controller.isLiveMode.value ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                color: controller.isLiveMode.value ? Colors.greenAccent : textDim,
                size: 22,
              ),
              onPressed: controller.toggleLiveMode,
            ),
          ),

          // Export CSV Icon
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: textMuted, size: 22),
            tooltip: 'Export CSV',
            onPressed: controller.exportErrorsCsv,
          ),

          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: textMuted, size: 22),
            tooltip: 'Refresh',
            onPressed: controller.fetchAllData,
          ),
        ],
      ),
    );
  }

  // 🎛️ Glowing Filter Button
  Widget _buildAdvancedFilterButton() {
    return Obx(() {
      final hasFilters = controller.hasAdvancedFilters;
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [purplePrimary, purpleDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: purplePrimary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _showAdvancedFiltersBottomSheet,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                if (hasFilters)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.amberAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // 🏷️ Active Filter Banner (shows active date/employee/branch)
  Widget _buildActiveFilterIndicator() {
    return Obx(() {
      if (!controller.hasAdvancedFilters) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: purpleDeep.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: purplePrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_alt_rounded, size: 14, color: purpleLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _buildActiveFilterSummary(),
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: controller.clearAdvancedFilters,
                child: const Text(
                  'Reset',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: redNeon),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  String _buildActiveFilterSummary() {
    final parts = <String>[];
    if (controller.appliedDate.value.isNotEmpty) parts.add('Date: ${controller.appliedDate.value}');
    if (controller.appliedEmpName.value.isNotEmpty) parts.add('Emp: ${controller.appliedEmpName.value}');
    if (controller.appliedEmpId.value.isNotEmpty) parts.add('ID: ${controller.appliedEmpId.value}');
    if (controller.appliedBranchId.value.isNotEmpty) parts.add('Branch: ${controller.appliedBranchId.value}');
    return parts.join(' • ');
  }

  // 📑 TabBar (API Errors | Exceptions)
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderSubtle, width: 1.5),
        ),
      ),
      child: TabBar(
        controller: controller.tabController,
        indicatorColor: tealNeon,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: tealNeon,
        unselectedLabelColor: textDim,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: [
          Tab(
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('API Errors'),
                  if (controller.filteredApiErrors.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: tealSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${controller.filteredApiErrors.length}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tealNeon),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Tab(
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Exceptions'),
                  if (controller.filteredExceptions.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: redSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${controller.filteredExceptions.length}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: redNeon),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📋 Log List
  Widget _buildLogList({required bool isException}) {
    return Obx(() {
      final list = isException ? controller.filteredExceptions : controller.filteredApiErrors;

      if (controller.isLoading.value && list.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: purplePrimary));
      }

      if (controller.streamError.value.contains('permission-denied') && list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1428),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: redNeon.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_person_rounded, size: 48, color: redNeon),
                  const SizedBox(height: 12),
                  const Text(
                    'Firestore Permission Denied',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cloud Firestore in "RealsoftERP-Apps" blocked read access.\nPlease update the Security Rules in Firebase Console to allow read access.',
                    style: TextStyle(fontSize: 12.5, color: textMuted, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purplePrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry Connection'),
                    onPressed: controller.fetchAllData,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isException ? Icons.check_circle_outline_rounded : Icons.cloud_done_outlined,
                  size: 52,
                  color: textDim,
                ),
                const SizedBox(height: 12),
                Text(
                  isException ? 'No Exceptions Recorded' : 'No API Errors Recorded',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All systems operational. No records match current search or filters.',
                  style: TextStyle(fontSize: 12, color: textDim),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: purplePrimary,
        backgroundColor: surfaceDark,
        onRefresh: controller.fetchAllData,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = list[index];
            return _buildLogCard(doc, isException: isException);
          },
        ),
      );
    });
  }

  // 🃏 Log Card Item (matching Screenshot 2)
  Widget _buildLogCard(Map<String, dynamic> doc, {required bool isException}) {
    final fnName = (doc['functionName'] ?? doc['Function'] ?? 'UNKNOWN_FUNCTION').toString();
    final errorDetails = (doc['errorDetails'] ?? doc['error'] ?? doc['message'] ?? 'No error description provided').toString();
    final empName = (doc['empName'] ?? 'Unknown').toString();
    final date = (doc['date'] ?? '').toString();
    final time = (doc['time'] ?? '').toString();

    // Format timestamp: e.g. "08:07 AM • 2026-10-07"
    final timeDisplay = time.isNotEmpty && date.isNotEmpty ? '$time • $date' : (time.isNotEmpty ? time : date);

    final badgeColor = isException ? redNeon : tealNeon;
    final badgeBg = isException ? redSubtle : tealSubtle;
    final badgeText = isException ? 'Exception' : 'API Error';

    return Container(
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (isException) {
              _showExceptionSignatureBottomSheet(doc);
            } else {
              _showApiErrorInfoBottomSheet(doc);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Badge + Timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge (Exception / API Error)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),

                    // Timestamp
                    Text(
                      timeDisplay,
                      style: const TextStyle(
                        fontSize: 11,
                        color: textDim,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Function Name Title (e.g. ZONED_FATAL_CRASH)
                Text(
                  fnName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Error Message Snippet
                Text(
                  errorDetails,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Bottom Row: Employee Avatar & Name + Chevron Right
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: purplePrimary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: purpleLight,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        empName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE2E8F0),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: textDim,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🪲 Bottom Sheet 1: Exception Signature (Screenshot 1)
  void _showExceptionSignatureBottomSheet(Map<String, dynamic> doc) {
    final fn = (doc['functionName'] ?? doc['Function'] ?? 'UNKNOWN').toString();
    final date = (doc['date'] ?? '').toString();
    final time = (doc['time'] ?? '').toString();
    final timeStr = date.isNotEmpty && time.isNotEmpty ? '$date $time' : (date.isNotEmpty ? date : time);
    final appVer = (doc['appVersion'] ?? doc['appversion'] ?? 'N/A').toString();
    final empName = (doc['empName'] ?? 'Unknown').toString();
    final empId = (doc['empId'] ?? 'Unknown').toString();
    final branchId = (doc['branchId'] ?? 'Unknown').toString();
    final errorMsg = (doc['errorDetails'] ?? doc['error'] ?? doc['message'] ?? 'N/A').toString();
    final stack = (doc['stack'] ?? doc['Stack'] ?? '').toString();
    final docId = (doc['id'] ?? '').toString();

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.9),
        decoration: const BoxDecoration(
          color: Color(0xFF120E22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF332D50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Red Bug Icon + Exception Signature
                    Row(
                      children: [
                        const Icon(
                          Icons.bug_report_rounded,
                          color: redNeon,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Exception Signature',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share_rounded, color: textDim, size: 20),
                          tooltip: 'Copy Bug Report',
                          onPressed: () {
                            final report = BugReportBuilder.build(type: 'ESS EXCEPTION', data: doc);
                            controller.copyToClipboard(report, 'Markdown bug report copied');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Metadata Section
                    _buildMetaRow('Function', fn, highlightValue: true),
                    const SizedBox(height: 12),
                    _buildMetaRow('Time', timeStr),
                    const SizedBox(height: 12),
                    _buildMetaRow('App Version', appVer),
                    const SizedBox(height: 18),
                    const Divider(color: borderDark, height: 1),
                    const SizedBox(height: 18),
                    _buildMetaRow('Employee', empName),
                    const SizedBox(height: 12),
                    _buildMetaRow('Employee ID', empId),
                    const SizedBox(height: 12),
                    _buildMetaRow('Branch ID', branchId),
                    const SizedBox(height: 24),

                    // ERROR MESSAGE Section
                    const Text(
                      'ERROR MESSAGE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: redPinkNeon,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderDark),
                      ),
                      child: SelectableText(
                        errorMsg,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFF1F5F9),
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // STACK TRACE Section
                    if (stack.isNotEmpty) ...[
                      const Text(
                        'STACK TRACE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: redPinkNeon,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF4A1828)),
                        ),
                        child: SelectableText(
                          stack,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: redNeon,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Close Button (Matching Screenshot 1)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF251F3D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Get.back(),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    if (docId.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                          label: const Text('Delete this log from Firestore', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                          onPressed: () {
                            Get.defaultDialog(
                              title: 'Delete Exception Record',
                              titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                              middleText: 'Delete this exception document from ESS_exception_logs?',
                              textCancel: 'Cancel',
                              textConfirm: 'Delete',
                              confirmTextColor: Colors.white,
                              buttonColor: Colors.red,
                              onConfirm: () {
                                Get.back(); // close dialog
                                Get.back(); // close sheet
                                controller.deleteException(docId);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ℹ️ Bottom Sheet 2: API Error Info (Screenshot 3)
  void _showApiErrorInfoBottomSheet(Map<String, dynamic> doc) {
    final fn = (doc['functionName'] ?? doc['Function'] ?? 'UNKNOWN').toString();
    final date = (doc['date'] ?? '').toString();
    final time = (doc['time'] ?? '').toString();
    final timeStr = date.isNotEmpty && time.isNotEmpty ? '$date $time' : (date.isNotEmpty ? date : time);
    final appVer = (doc['appVersion'] ?? doc['appversion'] ?? 'N/A').toString();
    final empName = (doc['empName'] ?? 'Unknown').toString();
    final empId = (doc['empId'] ?? 'Unknown').toString();
    final branchId = (doc['branchId'] ?? 'Unknown').toString();
    final errorMsg = (doc['errorDetails'] ?? doc['error'] ?? doc['message'] ?? 'N/A').toString();
    final params = (doc['params'] ?? doc['Params'] ?? '').toString();
    final docId = (doc['id'] ?? '').toString();

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.9),
        decoration: const BoxDecoration(
          color: Color(0xFF120E22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF332D50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Teal Info/Exclamation Icon + API Error Info
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: tealNeon,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'API Error Info',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share_rounded, color: textDim, size: 20),
                          tooltip: 'Copy Bug Report',
                          onPressed: () {
                            final report = BugReportBuilder.build(type: 'ESS API ERROR', data: doc);
                            controller.copyToClipboard(report, 'Markdown bug report copied');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Metadata Section
                    _buildMetaRow('Function', fn, highlightValue: true),
                    const SizedBox(height: 12),
                    _buildMetaRow('Time', timeStr),
                    const SizedBox(height: 12),
                    _buildMetaRow('App Version', appVer),
                    const SizedBox(height: 18),
                    const Divider(color: borderDark, height: 1),
                    const SizedBox(height: 18),
                    _buildMetaRow('Employee', empName),
                    const SizedBox(height: 12),
                    _buildMetaRow('Employee ID', empId),
                    const SizedBox(height: 12),
                    _buildMetaRow('Branch ID', branchId),
                    const SizedBox(height: 24),

                    // ERROR MESSAGE Section
                    const Text(
                      'ERROR MESSAGE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: tealNeon,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderDark),
                      ),
                      child: SelectableText(
                        errorMsg,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFF1F5F9),
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // PARAMETERS Section
                    if (params.isNotEmpty) ...[
                      const Text(
                        'PARAMETERS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: tealNeon,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderDark),
                        ),
                        child: SelectableText(
                          params,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFFCBD5E1),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Close Button (Matching Screenshot 3)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF251F3D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Get.back(),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    if (docId.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                          label: const Text('Delete this log from Firestore', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                          onPressed: () {
                            Get.defaultDialog(
                              title: 'Delete API Record',
                              titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                              middleText: 'Delete this API error document from ESS_error_logs?',
                              textCancel: 'Cancel',
                              textConfirm: 'Delete',
                              confirmTextColor: Colors.white,
                              buttonColor: Colors.red,
                              onConfirm: () {
                                Get.back(); // close dialog
                                Get.back(); // close sheet
                                controller.deleteApiError(docId);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // 🎛️ Bottom Sheet 3: Advanced Filters (Screenshot 2)
  void _showAdvancedFiltersBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF141026),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF332D50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title: Advanced Filters
              const Text(
                'Advanced Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Field 1: Date (yyyy-mm-dd)
              _buildFilterInputField(
                controller: controller.filterDateController,
                hintText: 'Date (yyyy-mm-dd)',
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(height: 14),

              // Field 2: Employee Name
              _buildFilterInputField(
                controller: controller.filterEmpNameController,
                hintText: 'Employee Name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),

              // Row: Employee ID & Branch ID
              Row(
                children: [
                  Expanded(
                    child: _buildFilterInputField(
                      controller: controller.filterEmpIdController,
                      hintText: 'Employee ID',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFilterInputField(
                      controller: controller.filterBranchIdController,
                      hintText: 'Branch ID',
                      icon: Icons.store_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Action Buttons Row: Clear & Apply Filters
              Row(
                children: [
                  // Clear button (Red outlined)
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: redNeon, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      onPressed: () {
                        controller.clearAdvancedFilters();
                        Get.back();
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: redNeon),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Apply Filters button (Purple Gradient filled)
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [purplePrimary, purpleDeep],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: purplePrimary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          controller.applyAdvancedFilters();
                          Get.back();
                        },
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // 📝 Helper for Advanced Filter Form Field
  Widget _buildFilterInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderDark),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: textDim, fontSize: 14),
          prefixIcon: Icon(icon, color: purpleLight, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }

  // 📌 Helper for Metadata Key-Value Row
  Widget _buildMetaRow(String label, String value, {bool highlightValue = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textDim,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value.isEmpty ? 'N/A' : value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: highlightValue ? Colors.white : const Color(0xFFE2E8F0),
            ),
          ),
        ),
      ],
    );
  }
}
