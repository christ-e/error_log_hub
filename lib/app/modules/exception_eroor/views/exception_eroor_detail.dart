import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/error_utils.dart';

class ExceptionEroorDetail extends StatefulWidget {
  const ExceptionEroorDetail({
    super.key,
    required this.data,
    this.occurrenceCount,
    this.instances,
  });

  final Map<String, dynamic> data;
  final int? occurrenceCount;
  final List<Map<String, dynamic>>? instances;

  @override
  State<ExceptionEroorDetail> createState() => _ExceptionEroorDetailState();
}

class _ExceptionEroorDetailState extends State<ExceptionEroorDetail> {
  bool _showAllStackFrames = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final stack = (data['Stack'] ?? '').toString();
    final culprit = StackTraceHelper.getCulpritFrame(stack);
    final parsedFrames = StackTraceHelper.parse(stack);
    final projectFrames = parsedFrames.where((f) => f.isProjectCode).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exception Details', style: TextStyle(fontWeight: FontWeight.bold)),
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
              PopupMenuItem(value: 'culprit', child: Text('Copy Culprit Frame')),
              PopupMenuItem(value: 'error', child: Text('Copy Error Message')),
              PopupMenuItem(value: 'stack', child: Text('Copy Full Stack Trace')),
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
                    colors: [Colors.red.shade900, Colors.red.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.25),
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
                    if (widget.occurrenceCount != null && widget.occurrenceCount! > 1) ...[
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Occurred ${widget.occurrenceCount} times across live devices',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
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
            _sectionHeader('Error', Icons.error_outline),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: SelectableText(
                (data['error'] ?? 'No error text available').toString(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade900,
                ),
              ),
            ),

            if (data['message'] != null && data['message'].toString().isNotEmpty && data['message'] != data['error']) ...[
              const SizedBox(height: 16),
              _sectionHeader('Message', Icons.chat_bubble_outline),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  data['message'].toString(),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],

            // 📦 Parameters Section
            if (data['Params'] != null && data['Params'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionHeader('Parameters (Input Payload)', Icons.data_object),
              ExpandableCodeBox(text: data['Params'].toString()),
            ],

            // 📜 Stack Trace Section (Beautified)
            if (stack.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionHeader('Stack Trace', Icons.format_align_left),
                  if (parsedFrames.length > projectFrames.length)
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      icon: Icon(
                        _showAllStackFrames ? Icons.filter_alt : Icons.filter_alt_off,
                        size: 16,
                      ),
                      label: Text(
                        _showAllStackFrames
                            ? 'Hide framework noise'
                            : 'Show all (${parsedFrames.length} frames)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _showAllStackFrames = !_showAllStackFrames;
                        });
                      },
                    ),
                ],
              ),
              _buildStackFramesView(parsedFrames, projectFrames),
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

  Widget _buildStackFramesView(List<ParsedFrame> allFrames, List<ParsedFrame> projectFrames) {
    final framesToDisplay = _showAllStackFrames ? allFrames : (projectFrames.isNotEmpty ? projectFrames : allFrames);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_showAllStackFrames && projectFrames.isNotEmpty && allFrames.length > projectFrames.length)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Filtered to ${projectFrames.length} project frames (ignoring ${allFrames.length - projectFrames.length} Flutter frames)',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: framesToDisplay.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade800),
            itemBuilder: (context, idx) {
              final f = framesToDisplay[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${f.index}',
                      style: TextStyle(
                        color: f.isProjectCode ? Colors.amberAccent : Colors.grey.shade600,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            f.function,
                            style: TextStyle(
                              color: f.isProjectCode ? Colors.white : Colors.grey.shade400,
                              fontWeight: f.isProjectCode ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (f.location.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            SelectableText(
                              f.location,
                              style: TextStyle(
                                color: f.isProjectCode ? Colors.lightBlueAccent : Colors.grey.shade600,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _copyBugReport() {
    final report = BugReportBuilder.build(
      type: 'Exception',
      data: widget.data,
      occurrenceCount: widget.occurrenceCount,
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
      case 'culprit':
        final culprit = StackTraceHelper.getCulpritFrame(widget.data['Stack']);
        text = culprit?.raw ?? 'No culprit frame found';
        break;
      case 'error':
        text = widget.data['error']?.toString() ?? '';
        break;
      case 'stack':
        text = widget.data['Stack']?.toString() ?? '';
        break;
      case 'params':
        text = widget.data['Params']?.toString() ?? '';
        break;
      case 'json':
        text = widget.data.toString();
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

class ExpandableCodeBox extends StatefulWidget {
  final String text;
  const ExpandableCodeBox({super.key, required this.text});

  @override
  State<ExpandableCodeBox> createState() => _ExpandableCodeBoxState();
}

class _ExpandableCodeBoxState extends State<ExpandableCodeBox> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            widget.text,
            maxLines: expanded ? null : 6,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
          if (widget.text.length > 150) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => expanded = !expanded),
              child: Text(
                expanded ? '▲ Show less' : '▼ Show more',
                style: const TextStyle(color: Color(0xFF1E3C72), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
