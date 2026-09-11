import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/exception_eroor_controller.dart';
import 'exception_eroor_detail.dart';

class ExceptionEroorView extends GetView<ExceptionEroorController> {
  const ExceptionEroorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exceptions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: _openFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: controller.confirmDeleteAll,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showDownloadOptions,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.exceptions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.exceptions.isEmpty) {
          return const Center(child: Text('No exceptions found'));
        }

        return RefreshIndicator(
          onRefresh: controller.fetchExceptions,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: controller.exceptions.length,
            itemBuilder: (context, index) {
              final item = controller.exceptions[index];

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Get.to(ExceptionEroorDetail(data: item));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['Function'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
                        const SizedBox(height: 4),
                        Text(
                          item['Route'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['error'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item['time'] ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                item['date'] ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  // 🔍 FILTER SHEET (unchanged logic)
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
                'Filter Exceptions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.rsnController,
                decoration: const InputDecoration(
                  labelText: 'RSN ID',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => controller.selectedRsnId.value = v.trim(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.functionController,
                decoration: const InputDecoration(
                  labelText: 'Function name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => controller.selectedFunction.value = v.trim(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.routeController,
                decoration: const InputDecoration(
                  labelText: 'Route',
                  hintText: 'Route74',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => controller.selectedRouteName.value = v.trim().replaceAll(' ', ''),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              TextField(
                controller: controller.appVersionController,
                decoration: const InputDecoration(
                  labelText: 'App Version',
                  hintText: 'V1.1.21+10',
                  border: OutlineInputBorder(),
                ),
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
                  value: controller.limit.value,
                  decoration: const InputDecoration(
                    labelText: 'Show records',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('All')),
                    DropdownMenuItem(value: 50, child: Text('50')),
                    DropdownMenuItem(value: 100, child: Text('100')),
                    DropdownMenuItem(value: 200, child: Text('200')),
                  ],
                  onChanged: (v) {
                    if (v != null) controller.limit.value = v;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.clearFilters,
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.fetchExceptions();
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
              "Download File",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text("Download Excel (.xlsx)"),
              onTap: () {
                Get.back();
                controller.exportToExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text("Download CSV (.csv)"),
              onTap: () {
                Get.back();
                controller.exportToCsv();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
