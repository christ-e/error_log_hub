import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/error_utils.dart';
import '../controllers/bsms_errors_controller.dart';

class BsmsErrorsView extends GetView<BsmsErrorsController> {
  const BsmsErrorsView({super.key});

  static const Color purplePrimary = Color(0xFF6D28D9);
  static const Color purpleSecondary = Color(0xFF7C3AED);
  static const Color purpleAccent = Color(0xFFA78BFA);
  static const Color darkBackground = Color(0xFF2E1065);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF), // Subtle violet tint
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: purplePrimary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                tooltip: 'Back',
                onPressed: () => Get.back(),
              ),
              actions: [
                Obx(
                  () => IconButton(
                    tooltip: controller.isLiveMode.value ? 'Live Stream Active' : 'Live Stream Paused',
                    icon: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Icon(
                          controller.isLiveMode.value ? Icons.sensors : Icons.sensors_off,
                          color: controller.isLiveMode.value ? Colors.greenAccent : Colors.white70,
                        ),
                        if (controller.isLiveMode.value)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    onPressed: controller.toggleLiveMode,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  tooltip: 'Refresh',
                  onPressed: controller.fetchAllData,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [purplePrimary, purpleSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'BSMS Diagnostics',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Bed Space Management Error & API Tracking',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 📊 Quick Metric Row
                          Obx(
                            () => Row(
                              children: [
                                Expanded(
                                  child: _buildMetricBadge(
                                    label: 'Exceptions',
                                    todayCount: controller.todayExceptions.value,
                                    totalCount: controller.totalExceptions.value,
                                    color: Colors.amber.shade300,
                                    icon: Icons.warning_amber_rounded,
                                    isSelected: controller.selectedTabIndex.value == 0,
                                    onTap: () => controller.tabController.animateTo(0),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMetricBadge(
                                    label: '404 Errors',
                                    todayCount: controller.today404Errors.value,
                                    totalCount: controller.total404Errors.value,
                                    color: Colors.redAccent.shade100,
                                    icon: Icons.link_off_rounded,
                                    isSelected: controller.selectedTabIndex.value == 1,
                                    onTap: () => controller.tabController.animateTo(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: TabBar(
                    controller: controller.tabController,
                    indicatorColor: purplePrimary,
                    indicatorWeight: 3,
                    labelColor: purplePrimary,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: [
                      Tab(
                        child: Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.flash_on_rounded, size: 18),
                              const SizedBox(width: 6),
                              const Text('Exceptions'),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: purplePrimary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${controller.filteredExceptions.length}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 18),
                              const SizedBox(width: 6),
                              const Text('Error 404'),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${controller.filtered404Errors.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // 🔎 Search & Filter Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: 'Search functions, errors, rooms, routes...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: purplePrimary),
                      suffixIcon: Obx(
                        () => controller.searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: controller.searchController.clear,
                              )
                            : const SizedBox.shrink(),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAF5FF),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: purpleSecondary.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: purpleSecondary.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: purplePrimary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Time Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Obx(
                      () => Row(
                        children: [
                          _buildFilterChip('All', BsmsTimeFilter.all),
                          const SizedBox(width: 6),
                          _buildFilterChip('Today', BsmsTimeFilter.today),
                          const SizedBox(width: 6),
                          _buildFilterChip('Last 24 Hours', BsmsTimeFilter.last24h),
                          const SizedBox(width: 6),
                          _buildFilterChip('Last 7 Days', BsmsTimeFilter.last7d),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // 📱 Tab Views with the 2 DIFFERENT Widgets
            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: const [
                  // ⚡ WIDGET 1: Dedicated Exceptions Widget for BSMS
                  BsmsExceptionWidget(),

                  // 🌐 WIDGET 2: Dedicated 404 Errors Widget for BSMS
                  Bsms404Widget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBadge({
    required String label,
    required int todayCount,
    required int totalCount,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white24,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$todayCount today ($totalCount total)',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String title, BsmsTimeFilter filter) {
    final isSelected = controller.selectedTimeFilter.value == filter;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      selectedColor: purplePrimary.withValues(alpha: 0.15),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? purplePrimary : Colors.grey.shade700,
      ),
      side: BorderSide(color: isSelected ? purplePrimary : Colors.grey.shade300),
      onSelected: (_) => controller.setTimeFilter(filter),
    );
  }
}

// ============================================================================
// ⚡ WIDGET 1: DEDICATED EXCEPTION WIDGET FOR BSMS
// ============================================================================
class BsmsExceptionWidget extends GetView<BsmsErrorsController> {
  const BsmsExceptionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.filteredExceptions.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: BsmsErrorsView.purplePrimary));
      }

      if (controller.filteredExceptions.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apartment_rounded, size: 64, color: Colors.purple.shade200),
                const SizedBox(height: 16),
                const Text(
                  'No BSMS Exceptions Logged',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                ),
                const SizedBox(height: 6),
                Text(
                  controller.searchQuery.value.isNotEmpty
                      ? 'No exceptions match "${controller.searchQuery.value}"'
                      : 'Bed Space Management services, tenant billing & booking functions are clean.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchAllData,
        color: BsmsErrorsView.purplePrimary,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.filteredExceptions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = controller.filteredExceptions[index];
            return _buildExceptionCard(context, doc);
          },
        ),
      );
    });
  }

  Widget _buildExceptionCard(BuildContext context, Map<String, dynamic> doc) {
    final fn = (doc['Function'] ?? 'Unknown Function').toString().trim();
    final error = (doc['error'] ?? doc['message'] ?? 'No error details recorded').toString().trim();
    final stack = (doc['stack_trace'] ?? doc['stackTrace'] ?? '').toString();
    final roomNo = (doc['roomNo'] ?? doc['bedId'] ?? doc['tenantId'] ?? doc['property'] ?? '').toString();
    final route = (doc['Route'] ?? doc['route'] ?? '').toString();

    final dt = DateTimeHelper.extractDateTime(doc);
    final relativeTime = DateTimeHelper.formatRelative(
      dt,
      fallbackDate: (doc['date'] ?? '').toString(),
      fallbackTime: (doc['time'] ?? '').toString(),
    );

    final culprit = StackTraceHelper.getCulpritFrame(stack);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showExceptionDetails(context, doc),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Tag, Function Name & Timestamp
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 14, color: Colors.purple.shade800),
                          const SizedBox(width: 4),
                          Text(
                            'EXCEPTION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fn,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Text(
                      relativeTime,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Error Message Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    error,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF991B1B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Culprit Frame / Stack Root
                if (culprit != null) ...[
                  Row(
                    children: [
                      Icon(Icons.code_rounded, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          culprit.function,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Metadata Chips: Room / Bed / Tenant / Route
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (roomNo.isNotEmpty)
                      _buildChip(Icons.meeting_room_outlined, 'Unit: $roomNo', Colors.purple),
                    if (route.isNotEmpty)
                      _buildChip(Icons.alt_route_rounded, route, Colors.indigo),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, MaterialColor palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: palette.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: palette.shade900, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showExceptionDetails(BuildContext context, Map<String, dynamic> doc) {
    final fn = (doc['Function'] ?? 'Unknown Function').toString();
    final error = (doc['error'] ?? doc['message'] ?? '').toString();
    final stack = (doc['stack_trace'] ?? doc['stackTrace'] ?? '').toString();
    final docId = (doc['id'] ?? '').toString();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: Colors.purple.shade900),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BSMS Exception Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(fn, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Copy Error',
                  onPressed: () => controller.copyToClipboard('$fn\n$error\n$stack'),
                ),
                if (docId.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    tooltip: 'Delete',
                    onPressed: () {
                      Get.back();
                      controller.deleteException(docId);
                    },
                  ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Error Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: SelectableText(
                        error,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF991B1B)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (stack.isNotEmpty) ...[
                      const Text('Stack Trace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          stack,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF38BDF8)),
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
}

// ============================================================================
// 🌐 WIDGET 2: DEDICATED 404 ERROR WIDGET FOR BSMS
// ============================================================================
class Bsms404Widget extends GetView<BsmsErrorsController> {
  const Bsms404Widget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.filtered404Errors.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
      }

      if (controller.filtered404Errors.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_done_outlined, size: 64, color: Colors.purple.shade200),
                const SizedBox(height: 16),
                const Text(
                  'No BSMS 404 Errors Found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                ),
                const SizedBox(height: 6),
                Text(
                  controller.searchQuery.value.isNotEmpty
                      ? 'No 404 records match "${controller.searchQuery.value}"'
                      : 'All Bed Space Management API endpoints and routes responded normally.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchAllData,
        color: Colors.redAccent,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.filtered404Errors.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = controller.filtered404Errors[index];
            return _build404Card(context, doc);
          },
        ),
      );
    });
  }

  Widget _build404Card(BuildContext context, Map<String, dynamic> doc) {
    final fn = (doc['Function'] ?? 'Unknown Function').toString().trim();
    final url = (doc['url'] ?? doc['Url'] ?? doc['endpoint'] ?? doc['Route'] ?? 'Missing Endpoint Path').toString().trim();
    final message = (doc['message'] ?? doc['error'] ?? doc['response'] ?? 'HTTP 404 Not Found').toString().trim();
    final statusCode = (doc['statusCode'] ?? doc['status'] ?? '404').toString();

    final dt = DateTimeHelper.extractDateTime(doc);
    final relativeTime = DateTimeHelper.formatRelative(
      dt,
      fallbackDate: (doc['date'] ?? '').toString(),
      fallbackTime: (doc['time'] ?? '').toString(),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _show404Details(context, doc),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: 404 Badge, Function & Time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_off_rounded, size: 14, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'HTTP $statusCode',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fn,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Text(
                      relativeTime,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Endpoint Path Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.http_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Server Response Message
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _show404Details(BuildContext context, Map<String, dynamic> doc) {
    final fn = (doc['Function'] ?? 'Unknown Function').toString();
    final url = (doc['url'] ?? doc['Url'] ?? doc['endpoint'] ?? doc['Route'] ?? '').toString();
    final message = (doc['message'] ?? doc['error'] ?? doc['response'] ?? '').toString();
    final docId = (doc['id'] ?? '').toString();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.link_off_rounded, color: Colors.red.shade800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BSMS 404 Endpoint Failure',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(fn, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Copy 404 Info',
                  onPressed: () => controller.copyToClipboard('Function: $fn\nURL: $url\nResponse: $message'),
                ),
                if (docId.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    tooltip: 'Delete',
                    onPressed: () {
                      Get.back();
                      controller.delete404Error(docId);
                    },
                  ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Requested URL / Endpoint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        url.isNotEmpty ? url : 'No URL recorded',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Server Response / Error Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: SelectableText(
                        message.isNotEmpty ? message : 'HTTP 404 Not Found',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF991B1B)),
                      ),
                    ),
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
}
