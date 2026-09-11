import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';

class FunctionEroor404Controller extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxBool isLoading = false.obs;
  RxList errors = [].obs;
  RxList unfilteredErrors = [].obs;
  RxInt limit = 100.obs;

  RxString selectedRsnId = ''.obs;
  RxString selectedRouteName = ''.obs;
  RxString selectedDateKey = ''.obs;
  RxString failedFunctionName = "".obs;
  RxString selectedAppVersion = "".obs;
  RxInt totalEntries = 0.obs;

  final TextEditingController rsnController = TextEditingController();
  final TextEditingController routeController = TextEditingController();
  final TextEditingController failedFunctionNameController = TextEditingController();
  final TextEditingController appVersionController = TextEditingController();

  @override
  void onInit() {
    fetchErrors();
    super.onInit();
  }

  Future<void> fetchErrors() async {
    try {
      isLoading.value = true;
      errors.clear();

      Query query = _firestore.collection('FunctionError-404').orderBy('Servertimestamp', descending: true);

      QuerySnapshot snap;

      if (limit.value == 0) {
        snap = await query.get();
      } else {
        snap = await query.limit(limit.value).get();
      }

      unfilteredErrors.value = snap.docs.map((e) => e.data()).toList();

      filter();
    } catch (e, s) {
      log('fetchErrors error: $e', stackTrace: s);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> filter() async {
    try {
      List data = List.from(unfilteredErrors);

      // Filter by RSNID
      if (selectedRsnId.value.isNotEmpty) {
        data = data.where((e) {
          return (e['RSNID'] ?? '').toString() == selectedRsnId.value;
        }).toList();
      }

      // Filter by Route
      if (selectedRouteName.value.isNotEmpty) {
        data = data.where((e) {
          final route = (e['Route'] ?? '').toString().toUpperCase();
          final input = selectedRouteName.value.toUpperCase();
          return route.contains(input);
        }).toList();
      }

      // Filter by Date
      if (selectedDateKey.value.isNotEmpty) {
        data = data.where((e) {
          return (e['date'] ?? '').toString() == selectedDateKey.value;
        }).toList();
      }
      if (failedFunctionName.value.isNotEmpty) {
        data = data.where((e) {
          final functionName = (e['Function'] ?? '').toString().toLowerCase().replaceAll(' ', '');
          final input = failedFunctionName.value.toLowerCase().replaceAll(' ', '');

          return functionName.contains(input);
        }).toList();
      }
      if (selectedAppVersion.value.isNotEmpty) {
        data = data.where((e) {
          final appVersion = (e['appVersion'] ?? '').toString().toLowerCase().replaceAll(' ', '');
          final input = selectedAppVersion.value.toLowerCase().replaceAll(' ', '');

          return appVersion.contains(input);
        }).toList();
      }

      errors.value = data;
    } catch (e) {
      log("Filter error: $e");
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: Get.context!,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      selectedDateKey.value = DateFormat('MMMM dd, yyyy').format(date);
    }
  }

  void clearFilters() {
    selectedRsnId.value = '';
    selectedDateKey.value = '';
    selectedRouteName.value = '';
    rsnController.text = "";
    routeController.text = "";
    fetchErrors();
  }

  Future<void> deleteError(String docId) async {
    try {
      await _firestore.collection('FunctionError-404').doc(docId).delete();

      // Remove locally (fast UI update)
      errors.removeWhere((e) => e['id'] == docId);
      unfilteredErrors.removeWhere((e) => e['id'] == docId);

      Get.snackbar(
        'Deleted',
        'Error deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void confirmDelete(String docId) {
    Get.defaultDialog(
      title: 'Delete Error',
      middleText: 'Are you sure you want to delete this error?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        deleteError(docId);
      },
    );
  }

  Future<void> deleteAllErrors() async {
    try {
      isLoading.value = true;

      final batch = _firestore.batch();

      for (var item in unfilteredErrors) {
        final docId = item['id'];
        final ref = _firestore.collection('FunctionError-404').doc(docId);

        batch.delete(ref);
      }

      await batch.commit();

      errors.clear();
      unfilteredErrors.clear();

      Get.snackbar(
        'Deleted',
        'All errors deleted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete all',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void confirmDeleteAll() {
    Get.defaultDialog(
      title: 'Delete All Errors',
      middleText: 'This action cannot be undone. Continue?',
      textConfirm: 'Delete All',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        deleteAllErrors();
      },
    );
  }

  Future<void> exportToCsv() async {
    try {
      if (errors.isEmpty) {
        Get.snackbar(
          'Export Failed',
          'No errors to export for the selected filter.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      isLoading.value = true;

      StringBuffer csv = StringBuffer();

      // Header
      csv.writeln('ID,Function,Message,Date,Time,Route,RSNID,App Version');

      // Rows
      for (var item in errors) {
        csv.writeln('${item['id'] ?? ''},'
            '${item['Function'] ?? ''},'
            '${item['message'] ?? ''},'
            '${item['date'] ?? ''},'
            '${item['time'] ?? ''},'
            '${item['Route'] ?? ''},'
            '${item['RSNID'] ?? ''},'
            '${item['appversion'] ?? ''}');
      }

      // 📂 Downloads folder
      Directory downloadsDir = Directory('/storage/emulated/0/Download');

      // 📂 App folder
      Directory appFolder = Directory('${downloadsDir.path}/FunctionErrors');

      if (!await appFolder.exists()) {
        await appFolder.create(recursive: true);
      }

      String fileName = "FunctionErrors_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";

      String path = "${appFolder.path}/$fileName";

      File file = File(path);
      await file.writeAsString(csv.toString());

      Get.snackbar(
        'Success',
        'CSV saved to:\n$path',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      log("CSV saved to $path");
    } catch (e) {
      log("CSV Export error: $e");

      Get.snackbar(
        'Error',
        'Failed to export CSV',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportToExcel() async {
    try {
      if (errors.isEmpty) {
        Get.snackbar(
          'Export Failed',
          'No errors to export.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;

      var excel = Excel.createExcel();
      Sheet sheet = excel['Errors'];

      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Function'),
        TextCellValue('Message'),
        TextCellValue('Date'),
        TextCellValue('Time'),
        TextCellValue('Route'),
        TextCellValue('RSNID'),
        TextCellValue('App Version')
      ]);

      for (var item in errors) {
        sheet.appendRow([
          TextCellValue(item['id']?.toString() ?? ''),
          TextCellValue(item['Function']?.toString() ?? ''),
          TextCellValue(item['message']?.toString() ?? ''),
          TextCellValue(item['date']?.toString() ?? ''),
          TextCellValue(item['time']?.toString() ?? ''),
          TextCellValue(item['Route']?.toString() ?? ''),
          TextCellValue(item['RSNID']?.toString() ?? ''),
          TextCellValue(item['appversion']?.toString() ?? '')
        ]);
      }

      Directory downloadsDir = Directory('/storage/emulated/0/Download');

      Directory appFolder = Directory('${downloadsDir.path}/FunctionErrors');

      if (!await appFolder.exists()) {
        await appFolder.create(recursive: true);
      }

      String fileName = "FunctionErrors_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";

      String path = "${appFolder.path}/$fileName";

      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      Get.snackbar(
        'Success',
        'Excel saved to:\n$path',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      log("Excel export error $e");

      Get.snackbar(
        'Error',
        'Excel export failed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
