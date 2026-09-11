import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/error_utils.dart';
import '../controllers/exception_eroor_controller.dart';
import 'exception_eroor_detail.dart';

class ExceptionEroorView extends GetView<ExceptionEroorController> {
  const ExceptionEroorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Exceptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  controller.isGroupedMode.value
                      ? '${controller.groupedExceptions.length} issue clusters'
                      : '${controller.exceptions.length} exceptions',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            )),
        centerTitle: true,
        actions: [
          // 🟢 Live Mode Toggle
          Obx(
            () => IconButton(
              tooltip: controller.isLiveMode.value ? 'Live Monitoring Active' : 'Enable Live Stream',
              icon: Stack(
                alignment: Alignment.topRight,
                children: [
                  Icon(
                    controller.isLiveMode.value ? Icons.sensors : Icons.sensors_off,
                    color: controller.isLiveMode.value ? Colors.green : Colors.grey,
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
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: 'Filter',
            onPressed: _openFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: _showDownloadOptions,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete All',
            onPressed: controller.confirmDeleteAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔎 Instant Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search function, error, route, RSN...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          controller.searchController.clear();
                          controller.onSearchChanged('');
                        },
                      )
                    : const SizedBox.shrink()),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),

          // 🏷️ Quick Filter Chips & Mode Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Obx(
                      () => Row(
                        children: [
                          _buildFilterChip('All', TimeFilter.all),
                          const SizedBox(width: 6),
                          _buildFilterChip('Today', TimeFilter.today),
                          const SizedBox(width: 6),
                          _buildFilterChip('Last 24h', TimeFilter.last24h),
                          const SizedBox(width: 6),
                          _buildFilterChip('Last 7 Days', TimeFilter.last7d),
                          if (controller.availableVersions.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(width: 1, height: 20, color: Colors.grey.shade300),
                            const SizedBox(width: 8),
                            for (final ver in controller.availableVersions) ...[
                              _buildVersionChip(ver),
                              const SizedBox(width: 6),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Mode Toggle Button (Grouped vs Raw)
                Obx(
                  () => OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      backgroundColor: controller.isGroupedMode.value
                          ? const Color(0xFF1E3C72).withValues(alpha: 0.1)
                          : Colors.transparent,
                      side: BorderSide(
                        color: controller.isGroupedMode.value ? const Color(0xFF1E3C72) : Colors.grey.shade300,
                      ),
                    ),
                    onPressed: controller.toggleViewMode,
                    icon: Icon(
                      controller.isGroupedMode.value ? Icons.auto_awesome_motion : Icons.format_list_bulleted,
                      size: 16,
                      color: controller.isGroupedMode.value ? const Color(0xFF1E3C72) : Colors.black87,
                    ),
                    label: Text(
                      controller.isGroupedMode.value ? 'Grouped' : 'Raw',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: controller.isGroupedMode.value ? const Color(0xFF1E3C72) : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 📋 List View
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.exceptions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.isGroupedMode.value) {
                if (controller.groupedExceptions.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildGroupedList();
              } else {
                if (controller.exceptions.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildRawList();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TimeFilter filter) {
    final isSelected = controller.selectedTimeFilter.value == filter;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: const Color(0xFF1E3C72),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? const Color(0xFF1E3C72) : Colors.grey.shade300),
      onSelected: (_) => controller.setTimeFilter(filter),
    );
  }

  Widget _buildVersionChip(String version) {
    final isSelected = controller.selectedAppVersion.value == version;
    return FilterChip(
      avatar: Icon(Icons.tag, size: 14, color: isSelected ? Colors.white : const Color(0xFF1E3C72)),
      label: Text(
        version,
        style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF1E3C72),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? const Color(0xFF1E3C72) : Colors.grey.shade300),
      onSelected: (_) => controller.setVersionFilter(version),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
          const SizedBox(height: 12),
          const Text(
            'No exceptions match your criteria',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Try clearing filters or searching for another term',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.clearFilters,
            child: const Text('Reset All Filters'),
          ),
        ],
      ),
    );
  }

  // 📦 GROUPED LIST VIEW (Crashlytics Style)
  Widget _buildGroupedList() {
    return RefreshIndicator(
      onRefresh: controller.fetchExceptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.groupedExceptions.length,
        itemBuilder: (context, index) {
          final group = controller.groupedExceptions[index];
          final latest = group.latestDoc;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Get.to(() => ExceptionEroorDetail(
                      data: latest,
                      occurrenceCount: group.count,
                      instances: group.instances,
                    ));
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Function + Occurrences Badge + Delete Group
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.functionName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3C72),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last seen: ${group.relativeTime}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        // Count Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: group.count > 10
                                ? Colors.red.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: group.count > 10 ? Colors.red.shade300 : Colors.orange.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 14,
                                color: group.count > 10 ? Colors.red : Colors.deepOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${group.count} events',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: group.count > 10 ? Colors.red.shade800 : Colors.deepOrange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                          tooltip: 'Delete Issue Cluster',
                          onPressed: () => controller.confirmDeleteGroup(group),
                        ),
                      ],
                    ),

                    const Divider(height: 16),

                    // Error Message Preview
                    Text(
                      group.errorMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Affected Routes & Users metadata
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (group.affectedRoutes.isNotEmpty)
                          _metadataTag(
                            Icons.route,
                            '${group.affectedRoutes.length} routes (${group.affectedRoutes.take(2).join(', ')}${group.affectedRoutes.length > 2 ? '...' : ''})',
                          ),
                        if (group.affectedRsnIds.isNotEmpty)
                          _metadataTag(
                            Icons.person_pin,
                            '${group.affectedRsnIds.length} RSNs',
                          ),
                        if (latest['appVersion'] != null || latest['appversion'] != null)
                          _metadataTag(
                            Icons.system_update,
                            'v${latest['appVersion'] ?? latest['appversion']}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 📄 RAW LIST VIEW
  Widget _buildRawList() {
    return RefreshIndicator(
      onRefresh: controller.fetchExceptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.exceptions.length,
        itemBuilder: (context, index) {
          final item = controller.exceptions[index];
          final dt = DateTimeHelper.extractDateTime(item);
          final relativeTime = DateTimeHelper.formatRelative(
            dt,
            fallbackDate: (item['date'] ?? '').toString(),
            fallbackTime: (item['time'] ?? '').toString(),
          );

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Get.to(() => ExceptionEroorDetail(data: item));
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['Function'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          relativeTime,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: () {
                            try {
                              controller.confirmDelete(item['id']);
                            } catch (e) {
                              log('Delete error: $e');
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (item['Route'] != null && item['Route'].toString().isNotEmpty)
                          _badge(item['Route'], Colors.blue.shade50, Colors.blue.shade700),
                        if (item['RSNID'] != null && item['RSNID'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _badge('RSN ${item['RSNID']}', Colors.purple.shade50, Colors.purple.shade700),
                          ),
                        if (item['appVersion'] != null || item['appversion'] != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _badge('${item['appVersion'] ?? item['appversion']}', Colors.teal.shade50, Colors.teal.shade700),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['error'] ?? item['message'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _metadataTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textCol),
      ),
    );
  }

  // 🔍 ADVANCED FILTER SHEET
  void _openFilterSheet() {
    Get.bottomSheet(
      SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Advanced Filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.rsnController,
                decoration: const InputDecoration(labelText: 'RSN ID', border: OutlineInputBorder()),
                onChanged: (v) => controller.selectedRsnId.value = v.trim(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.functionController,
                decoration: const InputDecoration(labelText: 'Function name', border: OutlineInputBorder()),
                onChanged: (v) => controller.selectedFunction.value = v.trim(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.routeController,
                decoration: const InputDecoration(labelText: 'Route', border: OutlineInputBorder()),
                onChanged: (v) => controller.selectedRouteName.value = v.trim().replaceAll(' ', ''),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.appVersionController,
                decoration: const InputDecoration(labelText: 'App Version', border: OutlineInputBorder()),
                onChanged: (v) => controller.selectedAppVersion.value = v.trim().replaceAll(' ', ''),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: controller.pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Obx(
                    () => Text(
                      controller.selectedDateKey.value.isEmpty ? 'Select Date' : controller.selectedDateKey.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => DropdownButtonFormField<int>(
                  initialValue: controller.limit.value,
                  decoration: const InputDecoration(
                    labelText: 'Fetch Limit',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 50, child: Text('50 records')),
                    DropdownMenuItem(value: 100, child: Text('100 records')),
                    DropdownMenuItem(value: 200, child: Text('200 records')),
                    DropdownMenuItem(value: 0, child: Text('All records')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      controller.limit.value = v;
                      controller.fetchExceptions();
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        controller.clearFilters();
                        Get.back();
                      },
                      child: const Text('Reset All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.filter();
                        Get.back();
                      },
                      child: const Text('Apply'),
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

  void _showDownloadOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Download Report",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text("Export Excel (.xlsx)"),
              subtitle: Text('${controller.exceptions.length} filtered items'),
              onTap: () {
                Get.back();
                controller.exportToExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text("Export CSV (.csv)"),
              subtitle: Text('${controller.exceptions.length} filtered items'),
              onTap: () {
                Get.back();
                controller.exportToCsv();
              },
            ),
          ],
        ),
      ),
    );
  }
}
