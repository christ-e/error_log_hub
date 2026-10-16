import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/error_utils.dart';
import '../controllers/ess_face_errors_controller.dart';

class EssFaceErrorsView extends GetView<EssFaceErrorsController> {
  const EssFaceErrorsView({super.key});

  static const Color tealPrimary = Color(0xFF0F766E);
  static const Color tealSecondary = Color(0xFF14B8A6);
  static const Color darkBackground = Color(0xFF042F2E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: tealPrimary,
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
                  tooltip: 'Refresh All',
                  onPressed: controller.fetchAllData,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tealPrimary, tealSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.face_unlock_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'ESS Face Diagnostics',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Obx(
                                      () => Text(
                                        controller.connectionStatus.value,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 📊 4 Interactive Stat Cards: 1-tap shortcuts
                          Obx(
                            () => Row(
                              children: [
                                Expanded(
                                  child: _buildMetricTile(
                                    title: 'Punch Err',
                                    today: controller.todayPunchErrors.value,
                                    total: controller.punchErrorsCount.value,
                                    color: Colors.orange.shade300,
                                    isSelected: controller.selectedTabIndex.value == 0 &&
                                        controller.punchSubFilter.value == PunchSubFilter.errors,
                                    onTap: () => controller.switchToPunchTab(subFilter: PunchSubFilter.errors),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildMetricTile(
                                    title: 'Punch Excep',
                                    today: controller.todayPunchExceptions.value,
                                    total: controller.punchExceptionsCount.value,
                                    color: Colors.amber.shade300,
                                    isSelected: controller.selectedTabIndex.value == 0 &&
                                        controller.punchSubFilter.value == PunchSubFilter.exceptions,
                                    onTap: () => controller.switchToPunchTab(subFilter: PunchSubFilter.exceptions),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildMetricTile(
                                    title: 'UI 404',
                                    today: controller.todayFunctionErrors.value,
                                    total: controller.functionErrorsCount.value,
                                    color: Colors.redAccent.shade100,
                                    isSelected: controller.selectedTabIndex.value == 1 &&
                                        controller.uiSubFilter.value == UiSubFilter.errors404,
                                    onTap: () => controller.switchToUiTab(subFilter: UiSubFilter.errors404),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildMetricTile(
                                    title: 'UI Excep',
                                    today: controller.todayFunctionExceptions.value,
                                    total: controller.functionExceptionsCount.value,
                                    color: Colors.purple.shade200,
                                    isSelected: controller.selectedTabIndex.value == 1 &&
                                        controller.uiSubFilter.value == UiSubFilter.exceptions,
                                    onTap: () => controller.switchToUiTab(subFilter: UiSubFilter.exceptions),
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
                    indicatorColor: tealPrimary,
                    indicatorWeight: 3,
                    labelColor: tealPrimary,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: [
                      // TAB 1: PUNCH ERROR TAB
                      Obx(
                        () => Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.fingerprint_rounded, size: 18),
                              const SizedBox(width: 6),
                              const Text('Punch Error'),
                              const SizedBox(width: 6),
                              _badge('${controller.totalPunchCount}', Colors.orange),
                            ],
                          ),
                        ),
                      ),
                      // TAB 2: UI ERROR TAB
                      Obx(
                        () => Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.desktop_windows_rounded, size: 18),
                              const SizedBox(width: 6),
                              const Text('UI Error'),
                              const SizedBox(width: 6),
                              _badge('${controller.totalUiCount}', Colors.teal),
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
            // ⚠️ Error Banner if any
            Obx(() {
              if (controller.errorMessage.value.isEmpty) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red.shade800, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage.value,
                        style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: controller.fetchAllData,
                      child: const Text('Retry', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            }),

            // 🔎 Search Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: 'Search employee, function, error, branch, company...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: tealPrimary),
                      suffixIcon: Obx(
                        () => controller.searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: controller.searchController.clear,
                              )
                            : const SizedBox.shrink(),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF0FDFA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: tealSecondary.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: tealSecondary.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: tealPrimary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Obx(
                      () => Row(
                        children: [
                          _buildFilterChip('All Time', EssTimeFilter.all),
                          const SizedBox(width: 6),
                          _buildFilterChip('Today', EssTimeFilter.today),
                          const SizedBox(width: 6),
                          _buildFilterChip('Last 24 Hours', EssTimeFilter.last24h),
                          const SizedBox(width: 6),
                          _buildFilterChip('Last 7 Days', EssTimeFilter.last7d),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // 📱 Tab Views (Punch Errors & UI Errors)
            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: const [
                  PunchErrorsTabView(),
                  UiErrorsTabView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _badge(String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required int today,
    required int total,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white24,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                '$today td | $total',
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String title, EssTimeFilter filter) {
    final isSelected = controller.selectedTimeFilter.value == filter;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      selectedColor: tealPrimary.withValues(alpha: 0.15),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? tealPrimary : Colors.grey.shade700,
      ),
      side: BorderSide(color: isSelected ? tealPrimary : Colors.grey.shade300),
      onSelected: (_) => controller.setTimeFilter(filter),
    );
  }
}

// ============================================================================
// 🥊 TAB 1: PUNCH ERRORS VIEW
// ============================================================================
class PunchErrorsTabView extends GetView<EssFaceErrorsController> {
  const PunchErrorsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🎛️ Sub-Filter Pill Bar for Punch (All, Errors, Exceptions)
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Obx(() {
            final current = controller.punchSubFilter.value;
            final errCount = controller.filteredPunchErrors.length;
            final excCount = controller.filteredPunchExceptions.length;
            final totalCount = errCount + excCount;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _subChip(
                    label: 'All Punch ($totalCount)',
                    isSelected: current == PunchSubFilter.all,
                    color: Colors.teal,
                    onTap: () => controller.setPunchSubFilter(PunchSubFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _subChip(
                    label: '⚠️ Punch Errors ($errCount)',
                    isSelected: current == PunchSubFilter.errors,
                    color: Colors.orange,
                    onTap: () => controller.setPunchSubFilter(PunchSubFilter.errors),
                  ),
                  const SizedBox(width: 8),
                  _subChip(
                    label: '💥 Punch Exceptions ($excCount)',
                    isSelected: current == PunchSubFilter.exceptions,
                    color: Colors.amber.shade800,
                    onTap: () => controller.setPunchSubFilter(PunchSubFilter.exceptions),
                  ),
                ],
              ),
            );
          }),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Document List
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.displayedPunchDocs.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: EssFaceErrorsView.tealPrimary));
            }

            if (controller.displayedPunchDocs.isEmpty) {
              return _buildEmptyState(
                icon: Icons.fingerprint_rounded,
                title: 'No Punch Errors Found',
                subtitle: 'No punch logs matching your current filters in Punch_Error or Punch_Exception_Error.',
              );
            }

            return RefreshIndicator(
              onRefresh: controller.fetchAllData,
              color: EssFaceErrorsView.tealPrimary,
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: controller.displayedPunchDocs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = controller.displayedPunchDocs[index];
                  final col = (doc['_col'] ?? '').toString();
                  if (col == EssFaceErrorsController.colPunchException) {
                    return _buildPunchExceptionCard(context, doc);
                  }
                  return _buildPunchErrorCard(context, doc);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _subChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? color : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildPunchErrorCard(BuildContext context, Map<String, dynamic> doc) {
    final empCode = (doc['EmpCode'] ?? doc['empCode'] ?? doc['employeeId'] ?? 'No EmpCode').toString();
    final branch = (doc['Branch'] ?? doc['branch'] ?? '').toString();
    final company = (doc['Comapany'] ?? doc['comapany'] ?? doc['company'] ?? '').toString();
    final punchStatus = (doc['Punch_Status'] ?? doc['punchStatus'] ?? '').toString();
    final punchTime = (doc['Punch_Time/Date'] ?? doc['timestamp'] ?? '').toString();
    final message = (doc['message'] ?? doc['error'] ?? 'Punch failed').toString();
    final error = (doc['error'] ?? '').toString();
    final appVersion = (doc['AppVersion'] ?? doc['appVersion'] ?? '').toString();

    final dt = DateTimeHelper.extractDateTime(doc);
    final relativeTime = DateTimeHelper.formatRelative(dt, fallbackDate: punchTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showGenericDetailSheet(
            context: context,
            title: 'Punch Error Details',
            doc: doc,
            collection: EssFaceErrorsController.colPunchError,
            accentColor: Colors.orange,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Text(
                        'PUNCH ERROR',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Emp: $empCode',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Text(
                      relativeTime,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                if (error.isNotEmpty && error != message) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      error,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.orange.shade900),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (punchStatus.isNotEmpty) _tag('Status: $punchStatus', Colors.teal),
                    if (branch.isNotEmpty) _tag('Branch: $branch', Colors.blue),
                    if (company.isNotEmpty) _tag('RSN: $company', Colors.indigo),
                    if (appVersion.isNotEmpty) _tag(appVersion, Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPunchExceptionCard(BuildContext context, Map<String, dynamic> doc) {
    final empCode = (doc['EmpCode'] ?? doc['empCode'] ?? doc['employeeId'] ?? '').toString();
    final branch = (doc['Branch'] ?? doc['branch'] ?? '').toString();
    final company = (doc['Comapany'] ?? doc['comapany'] ?? doc['company'] ?? '').toString();
    final message = (doc['message'] ?? doc['error'] ?? 'Punch crash / exception').toString();
    final error = (doc['error'] ?? '').toString();
    final stack = (doc['stack'] ?? doc['stack_trace'] ?? '').toString();
    final appVersion = (doc['AppVersion'] ?? doc['appVersion'] ?? '').toString();
    final punchTime = (doc['Punch_Time/Date'] ?? doc['timestamp'] ?? '').toString();

    final dt = DateTimeHelper.extractDateTime(doc);
    final relativeTime = DateTimeHelper.formatRelative(dt, fallbackDate: punchTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showGenericDetailSheet(
            context: context,
            title: 'Punch Exception Details',
            doc: doc,
            collection: EssFaceErrorsController.colPunchException,
            accentColor: Colors.amber.shade800,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Text(
                        'PUNCH EXCEPTION',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        empCode.isNotEmpty ? 'Emp: $empCode' : 'Punch Crash',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Text(
                      relativeTime,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                if (error.isNotEmpty && error != message) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      error,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
                if (stack.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Stack trace available (${stack.split('\n').length} lines)',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (branch.isNotEmpty) _tag('Branch: $branch', Colors.blue),
                    if (company.isNotEmpty) _tag('RSN: $company', Colors.indigo),
                    if (appVersion.isNotEmpty) _tag(appVersion, Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 💻 TAB 2: UI ERRORS VIEW
// ============================================================================
class UiErrorsTabView extends GetView<EssFaceErrorsController> {
  const UiErrorsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🎛️ Sub-Filter Pill Bar for UI (All, 404, Exceptions)
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Obx(() {
            final current = controller.uiSubFilter.value;
            final err404Count = controller.filteredFunctionErrors.length;
            final excCount = controller.filteredFunctionExceptions.length;
            final totalCount = err404Count + excCount;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _subChip(
                    label: 'All UI ($totalCount)',
                    isSelected: current == UiSubFilter.all,
                    color: Colors.teal,
                    onTap: () => controller.setUiSubFilter(UiSubFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _subChip(
                    label: '🚫 404 Errors ($err404Count)',
                    isSelected: current == UiSubFilter.errors404,
                    color: Colors.redAccent,
                    onTap: () => controller.setUiSubFilter(UiSubFilter.errors404),
                  ),
                  const SizedBox(width: 8),
                  _subChip(
                    label: '⚡ UI Exceptions ($excCount)',
                    isSelected: current == UiSubFilter.exceptions,
                    color: Colors.purple,
                    onTap: () => controller.setUiSubFilter(UiSubFilter.exceptions),
                  ),
                ],
              ),
            );
          }),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Document List
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.displayedUiDocs.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: EssFaceErrorsView.tealPrimary));
            }

            if (controller.displayedUiDocs.isEmpty) {
              return _buildEmptyState(
                icon: Icons.desktop_windows_rounded,
                title: 'No UI Errors Found',
                subtitle: 'No records matching your current filters in Function_404_Error or Function_Exception_Error.',
              );
            }

            return RefreshIndicator(
              onRefresh: controller.fetchAllData,
              color: EssFaceErrorsView.tealPrimary,
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: controller.displayedUiDocs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = controller.displayedUiDocs[index];
                  final col = (doc['_col'] ?? '').toString();
                  if (col == EssFaceErrorsController.colFunctionException) {
                    return _buildFunctionExceptionCard(context, doc);
                  }
                  return _buildFunction404Card(context, doc);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _subChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? color : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildFunction404Card(BuildContext context, Map<String, dynamic> doc) {
    final fn = (doc['function'] ?? doc['Function'] ?? doc['name'] ?? 'Unknown Function').toString();
    final error = (doc['error'] ?? doc['message'] ?? '404 API Error').toString();
    final company = (doc['comapany'] ?? doc['Comapany'] ?? doc['company'] ?? '').toString();
    final appVersion = (doc['AppVersion'] ?? doc['appVersion'] ?? '').toString();
    final params = (doc['params'] ?? '').toString();
    final timestamp = (doc['timestamp'] ?? '').toString();

    final dt = DateTimeHelper.extractDateTime(doc);
    final relativeTime = DateTimeHelper.formatRelative(dt, fallbackDate: timestamp);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showGenericDetailSheet(
            context: context,
            title: 'Function 404 Details',
            doc: doc,
            collection: EssFaceErrorsController.colFunction404,
            accentColor: Colors.redAccent,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Text(
                        'UI 404 ERROR',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fn,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Text(
                      relativeTime,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    error,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.red.shade900),
                  ),
                ),
                if (params.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Params: $params',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (company.isNotEmpty) _tag('RSN: $company', Colors.indigo),
                    if (appVersion.isNotEmpty) _tag(appVersion, Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionExceptionCard(BuildContext context, Map<String, dynamic> doc) {
    final fn = (doc['function'] ?? doc['Function'] ?? doc['name'] ?? 'Unknown Function').toString();
    final error = (doc['error'] ?? doc['message'] ?? 'UI Exception occurred').toString();
    final stack = (doc['stack'] ?? doc['stack_trace'] ?? '').toString();
    final company = (doc['comapany'] ?? doc['Comapany'] ?? doc['company'] ?? '').toString();
    final appVersion = (doc['AppVersion'] ?? doc['appVersion'] ?? '').toString();
    final params = (doc['params'] ?? '').toString();
    final timestamp = (doc['timestamp'] ?? '').toString();

    final dt = DateTimeHelper.extractDateTime(doc);
    final relativeTime = DateTimeHelper.formatRelative(dt, fallbackDate: timestamp);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showGenericDetailSheet(
            context: context,
            title: 'UI Exception Details',
            doc: doc,
            collection: EssFaceErrorsController.colFunctionException,
            accentColor: Colors.purple,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.purple.shade300),
                      ),
                      child: Text(
                        'UI EXCEPTION',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fn,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Text(
                      relativeTime,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    error,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF991B1B)),
                  ),
                ),
                if (stack.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Stack trace available (${stack.split('\n').length} lines)',
                    style: TextStyle(fontSize: 11, color: Colors.purple.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
                if (params.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Params: $params',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (company.isNotEmpty) _tag('RSN: $company', Colors.indigo),
                    if (appVersion.isNotEmpty) _tag(appVersion, Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED UTILITY & DETAIL SHEET WIDGETS
// ============================================================================
Widget _tag(String label, MaterialColor palette) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: palette.shade50,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: palette.shade200),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, color: palette.shade900, fontWeight: FontWeight.w500),
    ),
  );
}

Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 54, color: Colors.teal.shade300),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    ),
  );
}

void _showGenericDetailSheet({
  required BuildContext context,
  required String title,
  required Map<String, dynamic> doc,
  required String collection,
  required Color accentColor,
}) {
  final docId = (doc['id'] ?? '').toString();
  final stack = (doc['stack'] ?? doc['stack_trace'] ?? '').toString();
  final params = (doc['params'] ?? '').toString();

  final ctrl = Get.find<EssFaceErrorsController>();

  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.info_outline_rounded, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Collection: $collection', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20),
                tooltip: 'Copy Payload',
                onPressed: () => ctrl.copyToClipboard(doc.toString()),
              ),
              if (docId.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  tooltip: 'Delete Document',
                  onPressed: () {
                    Get.back();
                    ctrl.deleteDocument(collection, docId);
                  },
                ),
            ],
          ),
          const Divider(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Value pairs
                  ...doc.entries.where((e) => !e.key.startsWith('_') && e.key != 'stack' && e.key != 'params').map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              e.key,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                          ),
                          Expanded(
                            child: SelectableText(
                              e.value?.toString() ?? '',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  if (params.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        params,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],

                  if (stack.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text('Stack Trace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        stack,
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF38BDF8)),
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
