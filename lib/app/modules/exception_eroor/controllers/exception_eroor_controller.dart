import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';

class ExceptionEroorController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxBool isLoading = false.obs;

  RxList<Map<String, dynamic>> exceptions = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> unfilteredExceptions = <Map<String, dynamic>>[].obs;

  RxInt limit = 50.obs;
  RxString selectedFunction = ''.obs;
  RxString selectedRouteName = ''.obs;
  RxString selectedDateKey = ''.obs;
  RxString selectedRsnId = ''.obs;
  RxString selectedAppVersion = "".obs;

  final TextEditingController functionController = TextEditingController();
  final TextEditingController routeController = TextEditingController();
  final TextEditingController rsnController = TextEditingController();
  final TextEditingController appVersionController = TextEditingController();

  @override
  void onInit() {
    fetchExceptions();
    super.onInit();
  }

  @override
  void onClose() {
    functionController.dispose();
    routeController.dispose();
    rsnController.dispose();
    super.onClose();
  }

  // 🔄 FETCH
  Future<void> fetchExceptions() async {
    try {
      isLoading.value = true;

      Query query = _firestore.collection('Exception').orderBy('timestamp', descending: true);

      QuerySnapshot snap;

      if (limit.value == 0) {
        snap = await query.get();
      } else {
        snap = await query.limit(limit.value).get();
      }

      unfilteredExceptions.value = snap.docs.map((doc) {
        return {
          'id': doc.id, // 🔑 IMPORTANT
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      filter();
    } catch (e, s) {
      log('fetchExceptions error: $e', stackTrace: s);
    } finally {
      isLoading.value = false;
    }
  }

  // 🔍 FILTER
  void filter() {
    List<Map<String, dynamic>> data = List.from(unfilteredExceptions);

    if (selectedFunction.value.isNotEmpty) {
      final input = selectedFunction.value.toUpperCase();
      data = data.where((e) {
        final fn = (e['Function'] ?? '').toString().toUpperCase();
        return fn.contains(input);
      }).toList();
    }

    if (selectedRouteName.value.isNotEmpty) {
      data = data.where((e) {
        final route = (e['Route'] ?? '').toString().toUpperCase();
        final input = selectedRouteName.value.toUpperCase();
        return route.contains(input);
      }).toList();
    }

    if (selectedRsnId.value.isNotEmpty) {
      data = data.where((e) {
        return (e['RSNID'] ?? '').toString() == selectedRsnId.value;
      }).toList();
    }

    if (selectedDateKey.value.isNotEmpty) {
      data = data.where((e) {
        return (e['date'] ?? '').toString() == selectedDateKey.value;
      }).toList();
    }
    if (selectedAppVersion.value.isNotEmpty) {
      data = data.where((e) {
        final appVersion = (e['appVersion'] ?? '').toString().toLowerCase().replaceAll(' ', '');
        final input = selectedAppVersion.value.toLowerCase().replaceAll(' ', '');

        return appVersion.contains(input);
      }).toList();
    }

    exceptions.value = data;
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
    selectedFunction.value = '';
    selectedRouteName.value = '';
    selectedRsnId.value = '';
    selectedDateKey.value = '';
    functionController.clear();
    routeController.clear();
    rsnController.clear();
    fetchExceptions();
  }

  // 🗑️ DELETE ONE
  Future<void> deleteException(String docId) async {
    try {
      await _firestore.collection('Exception').doc(docId).delete();

      exceptions.removeWhere((e) => e['id'] == docId);
      unfilteredExceptions.removeWhere((e) => e['id'] == docId);

      Get.snackbar('Deleted', 'Exception deleted');
    } catch (e) {
      Get.snackbar('Error', 'Delete failed');
    }
  }

  void confirmDelete(String docId) {
    Get.defaultDialog(
      title: 'Delete Exception',
      middleText: 'Are you sure you want to delete this exception?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        deleteException(docId);
      },
    );
  }

  // 🧨 DELETE ALL
  Future<void> deleteAllExceptions() async {
    try {
      isLoading.value = true;

      final batch = _firestore.batch();

      for (var item in unfilteredExceptions) {
        final ref = _firestore.collection('Exception').doc(item['id']);
        batch.delete(ref);
      }

      await batch.commit();

      exceptions.clear();
      unfilteredExceptions.clear();

      Get.snackbar('Deleted', 'All exceptions deleted');
    } catch (e) {
      Get.snackbar('Error', 'Delete all failed');
    } finally {
      isLoading.value = false;
    }
  }

  void confirmDeleteAll() {
    Get.defaultDialog(
      title: 'Delete All Exceptions',
      middleText: 'This action cannot be undone. Continue?',
      textConfirm: 'Delete All',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        deleteAllExceptions();
      },
    );
  }

  Future<void> exportToCsv() async {
    try {
      if (exceptions.isEmpty) {
        Get.snackbar(
          'Export Failed',
          'No exceptions to export for the selected filter.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      isLoading.value = true;

      StringBuffer csv = StringBuffer();

      // Header
      csv.writeln('ID,Function,Error,Date,Time,Route,RSNID,App Version');

      // Rows
      for (var item in exceptions) {
        csv.writeln('${item['id'] ?? ''},'
            '${item['Function'] ?? ''},'
            '${item['error']?.toString().replaceAll(',', ' ') ?? ''},'
            '${item['date'] ?? ''},'
            '${item['time'] ?? ''},'
            '${item['Route'] ?? ''},'
            '${item['RSNID'] ?? ''},'
            '${item['appversion'] ?? ''}');
      }

      // 📂 Downloads folder
      Directory downloadsDir = Directory('/storage/emulated/0/Download');

      // 📂 App folder
      Directory appFolder = Directory('${downloadsDir.path}/ExceptionErrors');

      if (!await appFolder.exists()) {
        await appFolder.create(recursive: true);
      }

      String fileName = "ExceptionErrors_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";

      String path = "${appFolder.path}/$fileName";

      File file = File(path);
      await file.writeAsString(csv.toString());

      Get.snackbar(
        'Success',
        'CSV saved to:\n$path',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );

      log("CSV saved to $path");
    } catch (e) {
      log("CSV Export error: $e");

      Get.snackbar(
        'Error',
        'Failed to export CSV',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportToExcel() async {
    try {
      if (exceptions.isEmpty) {
        Get.snackbar(
          'Export Failed',
          'No exceptions to export.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      isLoading.value = true;

      var excel = Excel.createExcel();
      Sheet sheet = excel['Exceptions'];

      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Function'),
        TextCellValue('Error'),
        TextCellValue('Date'),
        TextCellValue('Time'),
        TextCellValue('Route'),
        TextCellValue('RSNID'),
        TextCellValue('App Version')
      ]);

      for (var item in exceptions) {
        sheet.appendRow([
          TextCellValue(item['id']?.toString() ?? ''),
          TextCellValue(item['Function']?.toString() ?? ''),
          TextCellValue(item['error']?.toString() ?? ''),
          TextCellValue(item['date']?.toString() ?? ''),
          TextCellValue(item['time']?.toString() ?? ''),
          TextCellValue(item['Route']?.toString() ?? ''),
          TextCellValue(item['RSNID']?.toString() ?? ''),
          TextCellValue(item['appversion']?.toString() ?? '')
        ]);
      }

      Directory downloadsDir = Directory('/storage/emulated/0/Download');

      Directory appFolder = Directory('${downloadsDir.path}/ExceptionErrors');

      if (!await appFolder.exists()) {
        await appFolder.create(recursive: true);
      }

      String fileName = "ExceptionErrors_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";

      String path = "${appFolder.path}/$fileName";

      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      Get.snackbar(
        'Success',
        'Excel saved to:\n$path',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      log("Excel export error $e");

      Get.snackbar(
        'Error',
        'Excel export failed',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
