import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/error_utils.dart';
import 'package:vansales_firebase_erorrs/app/modules/exception_eroor/views/exception_eroor_detail.dart';

class FunctionEroor404DetailView extends StatelessWidget {
  const FunctionEroor404DetailView({
    super.key,
    required this.data,
    this.occurrenceCount,
    this.instances,
  });

  final Map<String, dynamic> data;
  final int? occurrenceCount;
  final List<Map<String, dynamic>>? instances;

  @override
  Widget build(BuildContext context) {
    final stack = (data['Stack'] ?? '').toString();
    final culprit = StackTraceHelper.getCulpritFrame(stack);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Function Error Details', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Copy Bug Report',
            onPressed: () => _copyBugReport(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _copyField,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('Copy Markdown Bug Report')),
              PopupMenuItem(value: 'message', child: Text('Copy Error Message')),
              PopupMenuItem(value: 'params', child: Text('Copy Parameters')),
              PopupMenuItem(value: 'json', child: Text('Copy Raw JSON')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 Culprit Root Cause Card (if project frame detected)
            if (culprit != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade900, Colors.deepOrange.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.gps_fixed, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'PRIMARY CULPRIT / ROOT CAUSE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      culprit.function,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (culprit.location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        culprit.location,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 📊 Occurrence & Metadata Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (occurrenceCount != null && occurrenceCount! > 1) ...[
                      Row(
                        children: [
                          const Icon(Icons.bug_report, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Occurred $occurrenceCount times across live devices',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                    ],
                    _infoRow(Icons.functions, 'Function', data['Function']),
                    _infoRow(Icons.route, 'Route', data['Route']),
                    _infoRow(Icons.badge, 'RSN ID', data['RSNID']),
                    _infoRow(Icons.fingerprint, 'GUID', data['GUID']),
                    _infoRow(Icons.system_update, 'App Version', data['appVersion'] ?? data['appversion']),
                    _infoRow(Icons.calendar_today, 'Date', data['date']),
                    _infoRow(Icons.access_time, 'Time', data['time']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ⚠️ Error Message Box
            _sectionHeader('Message / Error', Icons.error_outline),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: SelectableText(
                (data['message'] ?? data['error'] ?? 'No message text available').toString(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade900,
                ),
              ),
            ),

            // 📦 Parameters Section
            if (data['Params'] != null && data['Params'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionHeader('Parameters (Payload)', Icons.data_object),
              ExpandableCodeBox(text: data['Params'].toString()),
            ],

            const SizedBox(height: 24),

            // 📋 1-Tap Copy Bug Report Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.copy_all),
                label: const Text('Copy Formatted Bug Report for Devs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3C72),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _copyBugReport,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E3C72)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.toString(),
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _copyBugReport() {
    final report = BugReportBuilder.build(
      type: 'FunctionError-404',
      data: data,
      occurrenceCount: occurrenceCount,
    );
    Clipboard.setData(ClipboardData(text: report));
    Get.snackbar(
      'Copied Bug Report',
      'Formatted Markdown report copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _copyField(String type) {
    String text = '';
    switch (type) {
      case 'report':
        _copyBugReport();
        return;
      case 'message':
        text = (data['message'] ?? data['error'] ?? '').toString();
        break;
      case 'params':
        text = data['Params']?.toString() ?? '';
        break;
      case 'json':
        text = data.toString();
        break;
    }

    if (text.isEmpty) {
      Get.snackbar('Nothing to Copy', 'This field is empty', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied to Clipboard',
      text.length > 60 ? '${text.substring(0, 60)}...' : text,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
    );
  }
}
