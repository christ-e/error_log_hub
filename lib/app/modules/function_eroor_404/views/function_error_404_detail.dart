import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class FunctionEroor404DetailView extends StatelessWidget {
  const FunctionEroor404DetailView({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Details'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.copy),
            onSelected: (value) {
              _copyToClipboard(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'full',
                child: Text('Copy Full'),
              ),
              PopupMenuItem(
                value: 'error',
                child: Text('Copy Error'),
              ),
              PopupMenuItem(
                value: 'message',
                child: Text('Copy Message'),
              ),
              PopupMenuItem(
                value: 'params',
                child: Text('Copy Params'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _info('Function', data['Function']),
            _info('RSN ID', data['RSNID']),
            _info('Route', data['Route']),
            _info('GUID', data['GUID']),
            _info('Date', data['date']),
            _info('Time', data['time']),
            _info('Version', data['appVersion'] ?? ""),
            const SizedBox(height: 16),
            _title('Error'),
            _box(data['error']),
            const SizedBox(height: 16),
            _title('Message'),
            _box(data['message']),
            const SizedBox(height: 16),
            _title('Params'),
            ExpandableText(text: data['Params'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          t,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );

  Widget _info(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _box(String? value) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(value ?? ''),
      );
  void _copyToClipboard(String type) {
    String textToCopy = '';

    switch (type) {
      case 'full':
        textToCopy = data.toString();
        break;

      case 'error':
        textToCopy = data['error']?.toString() ?? '';
        break;

      case 'message':
        textToCopy = data['message']?.toString() ?? '';
        break;

      case 'params':
        textToCopy = data['Params']?.toString() ?? '';
        break;
    }

    if (textToCopy.isEmpty) {
      Get.snackbar(
        'Nothing to copy',
        'Selected field is empty',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: textToCopy));

    Get.snackbar(
      'Copied',
      'Content copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}

class ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;

  const ExpandableText({
    super.key,
    required this.text,
    this.trimLines = 5,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => expanded = !expanded);
      },
      child: Container(
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
            Text(
              widget.text,
              maxLines: expanded ? null : widget.trimLines,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              expanded ? 'Show less ▲' : 'Show more ▼',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
