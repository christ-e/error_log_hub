import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vansales_firebase_erorrs/app/modules/function_eroor_404/views/function_error_404_detail.dart';
import '../controllers/function_eroor_404_controller.dart';

class FunctionEroor404View extends GetView<FunctionEroor404Controller> {
  const FunctionEroor404View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Function Errors'),
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
        if (controller.isLoading.value && controller.errors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errors.isEmpty) {
          return const Center(child: Text('No errors found'));
        }

        return RefreshIndicator(
          onRefresh: controller.fetchErrors,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: controller.errors.length,
            itemBuilder: (context, index) {
              final item = controller.errors[index];

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Get.to(FunctionEroor404DetailView(data: item));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bug_report, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['Function'] ?? '',
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
                                  controller.confirmDelete(item['id'] ?? '');
                                } catch (e) {
                                  log("Error: $e");
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['message'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['date'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              item['time'] ?? '',
                              style: const TextStyle(fontSize: 12),
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
      }),
    );
  }

  // 🔍 Filter Bottom Sheet
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
                'Filter Errors',
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
                controller: controller.failedFunctionNameController,
                decoration: const InputDecoration(
                  labelText: 'Function name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => controller.failedFunctionName.value = v.trim(),
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
                    DropdownMenuItem(value: 100, child: Text('100')),
                    DropdownMenuItem(value: 200, child: Text('200')),
                    DropdownMenuItem(value: 500, child: Text('500')),
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
                        controller.fetchErrors();
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
