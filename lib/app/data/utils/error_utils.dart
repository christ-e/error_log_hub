import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Parsed frame from a stack trace
class ParsedFrame {
  final int index;
  final String raw;
  final String function;
  final String location;
  final bool isProjectCode;

  ParsedFrame({
    required this.index,
    required this.raw,
    required this.function,
    required this.location,
    required this.isProjectCode,
  });
}

/// Helper for parsing Dart/Flutter stack traces to extract the root cause
class StackTraceHelper {
  static final RegExp _frameRegex = RegExp(r'#(\d+)\s+(.+)\s+\((.+)\)');
  static final RegExp _altFrameRegex = RegExp(r'#(\d+)\s+(.+)');

  /// Parse lines of stack trace
  static List<ParsedFrame> parse(String? stackTrace) {
    if (stackTrace == null || stackTrace.trim().isEmpty) return [];

    final lines = stackTrace.split('\n');
    final frames = <ParsedFrame>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final match = _frameRegex.firstMatch(trimmed);
      if (match != null) {
        final index = int.tryParse(match.group(1) ?? '0') ?? 0;
        final fn = match.group(2)?.trim() ?? '';
        final loc = match.group(3)?.trim() ?? '';

        final isFramework = loc.contains('package:flutter/') ||
            loc.contains('dart-sdk') ||
            loc.startsWith('dart:') ||
            loc.contains('dart-patch') ||
            loc.contains('sky_engine') ||
            loc.contains('package:get/');

        frames.add(ParsedFrame(
          index: index,
          raw: trimmed,
          function: fn,
          location: loc,
          isProjectCode: !isFramework,
        ));
      } else {
        final altMatch = _altFrameRegex.firstMatch(trimmed);
        if (altMatch != null) {
          final index = int.tryParse(altMatch.group(1) ?? '0') ?? 0;
          final content = altMatch.group(2)?.trim() ?? '';
          final isFramework = content.contains('package:flutter/') ||
              content.startsWith('dart:') ||
              content.contains('dart-sdk') ||
              content.contains('sky_engine');

          frames.add(ParsedFrame(
            index: index,
            raw: trimmed,
            function: content,
            location: '',
            isProjectCode: !isFramework,
          ));
        }
      }
    }

    return frames;
  }

  /// Finds the primary culprit frame (first project-specific frame)
  static ParsedFrame? getCulpritFrame(String? stackTrace) {
    final frames = parse(stackTrace);
    for (final frame in frames) {
      if (frame.isProjectCode) {
        return frame;
      }
    }
    return frames.isNotEmpty ? frames.first : null;
  }
}

/// Helper for timestamps, relative times, and date filters
class DateTimeHelper {
  /// Extract a DateTime from whatever fields the document has
  static DateTime? extractDateTime(Map<String, dynamic> doc) {
    // 1. Check ServerTimestamp or timestamp (Firestore Timestamp)
    if (doc['Servertimestamp'] is Timestamp) {
      return (doc['Servertimestamp'] as Timestamp).toDate();
    }
    if (doc['timestamp'] is Timestamp) {
      return (doc['timestamp'] as Timestamp).toDate();
    }
    if (doc['timestamp'] is int) {
      return DateTime.fromMillisecondsSinceEpoch(doc['timestamp'] as int);
    }

    // 2. Check date & time string fields (e.g. "March 15, 2024" or "2024-03-15")
    final dateStr = (doc['date'] ?? '').toString().trim();
    final timeStr = (doc['time'] ?? '').toString().trim();

    if (dateStr.isNotEmpty) {
      try {
        final fullString = timeStr.isNotEmpty ? '$dateStr $timeStr' : dateStr;
        final parsed = DateTime.tryParse(fullString);
        if (parsed != null) return parsed;

        return DateFormat('MMMM dd, yyyy').parse(dateStr);
      } catch (_) {}
    }

    return null;
  }

  /// Check if date is today
  static bool isToday(DateTime? dt) {
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// Check if date is within the last 24 hours
  static bool isLast24Hours(DateTime? dt) {
    if (dt == null) return false;
    final now = DateTime.now();
    return now.difference(dt).inHours <= 24 && dt.isBefore(now.add(const Duration(minutes: 5)));
  }

  /// Check if date is within the last 7 days
  static bool isLast7Days(DateTime? dt) {
    if (dt == null) return false;
    final now = DateTime.now();
    return now.difference(dt).inDays <= 7 && dt.isBefore(now.add(const Duration(minutes: 5)));
  }

  /// Human friendly relative time: "Just now", "5m ago", "2h ago", "Yesterday", or "Oct 12"
  static String formatRelative(DateTime? dt, {String fallbackDate = '', String fallbackTime = ''}) {
    if (dt == null) {
      if (fallbackTime.isNotEmpty && fallbackDate.isNotEmpty) {
        return '$fallbackDate $fallbackTime';
      }
      return fallbackDate.isNotEmpty ? fallbackDate : fallbackTime;
    }

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return DateFormat('MMM dd, yyyy').format(dt);
  }
}

/// Represents a cluster of recurring errors
class GroupedErrorItem {
  final String key;
  final String functionName;
  final String errorMessage;
  final List<Map<String, dynamic>> instances;

  GroupedErrorItem({
    required this.key,
    required this.functionName,
    required this.errorMessage,
    required this.instances,
  });

  int get count => instances.length;

  Set<String> get affectedRoutes {
    return instances
        .map((e) => (e['Route'] ?? '').toString())
        .where((r) => r.isNotEmpty)
        .toSet();
  }

  Set<String> get affectedRsnIds {
    return instances
        .map((e) => (e['RSNID'] ?? '').toString())
        .where((r) => r.isNotEmpty)
        .toSet();
  }

  Map<String, dynamic> get latestDoc => instances.isNotEmpty ? instances.first : {};

  DateTime? get latestDateTime => DateTimeHelper.extractDateTime(latestDoc);

  String get relativeTime => DateTimeHelper.formatRelative(
        latestDateTime,
        fallbackDate: (latestDoc['date'] ?? '').toString(),
        fallbackTime: (latestDoc['time'] ?? '').toString(),
      );

  static List<GroupedErrorItem> group(List<Map<String, dynamic>> list, {bool isFunction404 = false}) {
    final Map<String, List<Map<String, dynamic>>> map = {};

    for (final doc in list) {
      final fn = (doc['Function'] ?? 'Unknown').toString().trim();
      final err = isFunction404
          ? (doc['message'] ?? doc['error'] ?? 'Unknown Error').toString().trim()
          : (doc['error'] ?? doc['message'] ?? 'Unknown Exception').toString().trim();

      final key = '$fn::$err';
      map.putIfAbsent(key, () => []).add(doc);
    }

    final result = map.entries.map((entry) {
      final first = entry.value.first;
      final fn = (first['Function'] ?? 'Unknown').toString();
      final err = isFunction404
          ? (first['message'] ?? first['error'] ?? '').toString()
          : (first['error'] ?? first['message'] ?? '').toString();

      return GroupedErrorItem(
        key: entry.key,
        functionName: fn,
        errorMessage: err,
        instances: entry.value,
      );
    }).toList();

    // Sort by count descending (most critical/frequent first)
    result.sort((a, b) => b.count.compareTo(a.count));
    return result;
  }
}

/// Markdown Bug Report Builder
class BugReportBuilder {
  static String build({
    required String type,
    required Map<String, dynamic> data,
    int? occurrenceCount,
  }) {
    final fn = data['Function'] ?? 'Unknown';
    final err = data['error'] ?? data['message'] ?? 'N/A';
    final msg = data['message'] ?? '';
    final route = data['Route'] ?? 'N/A';
    final rsn = data['RSNID'] ?? 'N/A';
    final version = data['appVersion'] ?? data['appversion'] ?? 'N/A';
    final date = data['date'] ?? '';
    final time = data['time'] ?? '';
    final stack = data['Stack'] ?? '';
    final params = data['Params'] ?? '';

    final culprit = StackTraceHelper.getCulpritFrame(stack);

    final sb = StringBuffer();
    sb.writeln('### 🚨 [$type] Error Report');
    if (occurrenceCount != null && occurrenceCount > 1) {
      sb.writeln('🔥 **Occurrences:** $occurrenceCount times');
    }
    sb.writeln('- **Function:** `$fn`');
    sb.writeln('- **Route:** `$route`');
    sb.writeln('- **RSN ID:** `$rsn`');
    sb.writeln('- **App Version:** `$version`');
    sb.writeln('- **Recorded At:** $date $time');
    if (culprit != null) {
      sb.writeln('- **Culprit Frame:** `${culprit.raw}`');
    }
    sb.writeln('');
    sb.writeln('#### ⚠️ Error Details:');
    sb.writeln('```');
    sb.writeln(err);
    if (msg.isNotEmpty && msg != err) {
      sb.writeln(msg);
    }
    sb.writeln('```');

    if (params.toString().isNotEmpty) {
      sb.writeln('#### 📦 Parameters:');
      sb.writeln('```json');
      sb.writeln(params);
      sb.writeln('```');
    }

    if (stack.toString().isNotEmpty) {
      sb.writeln('#### 📜 Stack Trace:');
      sb.writeln('```');
      sb.writeln(stack);
      sb.writeln('```');
    }

    return sb.toString();
  }
}

/// Represents an app version and the routes running it
class VersionRouteGroup {
  final String version;
  final Set<String> routes;
  final Set<String> rsnIds;
  final DateTime? latestSeen;
  final int errorCount;

  VersionRouteGroup({
    required this.version,
    required this.routes,
    required this.rsnIds,
    this.latestSeen,
    required this.errorCount,
  });

  int get routeCount => routes.length;
}

class VersionRouteAnalyzer {
  static List<VersionRouteGroup> analyze(List<Map<String, dynamic>> docs) {
    final Map<String, Set<String>> versionRoutes = {};
    final Map<String, Set<String>> versionRsns = {};
    final Map<String, DateTime?> versionLatestSeen = {};
    final Map<String, int> versionErrorCount = {};

    for (final doc in docs) {
      final rawVer = (doc['appVersion'] ?? doc['appversion'] ?? '').toString().trim();
      if (rawVer.isEmpty) continue;

      final route = (doc['Route'] ?? '').toString().trim();
      final rsn = (doc['RSNID'] ?? '').toString().trim();
      final dt = DateTimeHelper.extractDateTime(doc);

      versionRoutes.putIfAbsent(rawVer, () => <String>{});
      if (route.isNotEmpty) versionRoutes[rawVer]!.add(route);

      versionRsns.putIfAbsent(rawVer, () => <String>{});
      if (rsn.isNotEmpty) versionRsns[rawVer]!.add(rsn);

      versionErrorCount[rawVer] = (versionErrorCount[rawVer] ?? 0) + 1;

      if (dt != null) {
        final currentLatest = versionLatestSeen[rawVer];
        if (currentLatest == null || dt.isAfter(currentLatest)) {
          versionLatestSeen[rawVer] = dt;
        }
      }
    }

    final groups = versionRoutes.keys.map((ver) {
      return VersionRouteGroup(
        version: ver,
        routes: versionRoutes[ver] ?? {},
        rsnIds: versionRsns[ver] ?? {},
        latestSeen: versionLatestSeen[ver],
        errorCount: versionErrorCount[ver] ?? 0,
      );
    }).toList();

    // Sort by latest seen or route count descending
    groups.sort((a, b) {
      if (a.latestSeen != null && b.latestSeen != null) {
        return b.latestSeen!.compareTo(a.latestSeen!);
      }
      return b.routeCount.compareTo(a.routeCount);
    });

    return groups;
  }
}

