import 'package:flutter_test/flutter_test.dart';
import 'package:vansales_firebase_erorrs/app/data/utils/error_utils.dart';

void main() {
  group('StackTraceHelper Tests', () {
    test('Correctly identifies culprit frame from mixed stack trace', () {
      const sampleStack = '''
#0      _AssertionError._doThrowNew (dart:core-patch/errors_patch.dart:51:61)
#1      _AssertionError._throwNew (dart:core-patch/errors_patch.dart:40:5)
#2      OrderSyncService.uploadOrders (package:vansales/services/order_sync_service.dart:142:15)
#3      OrderSyncService.syncAll (package:vansales/services/order_sync_service.dart:55:7)
#4      _InkResponseState.handleTap (package:flutter/src/material/ink_well.dart:1183:21)
''';

      final culprit = StackTraceHelper.getCulpritFrame(sampleStack);
      expect(culprit, isNotNull);
      expect(culprit!.isProjectCode, isTrue);
      expect(culprit.function, 'OrderSyncService.uploadOrders');
      expect(culprit.location, 'package:vansales/services/order_sync_service.dart:142:15');
    });

    test('Handles empty stack trace gracefully', () {
      final culprit = StackTraceHelper.getCulpritFrame('');
      expect(culprit, isNull);
    });
  });

  group('GroupedErrorItem Tests', () {
    test('Groups duplicate errors by Function and Error message', () {
      final rawDocs = [
        {
          'id': 'doc1',
          'Function': 'syncOrders',
          'error': 'Null check operator used on null value',
          'Route': 'Route1',
          'RSNID': '101',
        },
        {
          'id': 'doc2',
          'Function': 'syncOrders',
          'error': 'Null check operator used on null value',
          'Route': 'Route2',
          'RSNID': '102',
        },
        {
          'id': 'doc3',
          'Function': 'fetchCustomers',
          'error': 'SocketException: Failed host lookup',
          'Route': 'Route1',
          'RSNID': '101',
        },
      ];

      final grouped = GroupedErrorItem.group(rawDocs);
      expect(grouped.length, 2);

      // Most frequent first
      expect(grouped.first.functionName, 'syncOrders');
      expect(grouped.first.count, 2);
      expect(grouped.first.affectedRoutes, {'Route1', 'Route2'});
      expect(grouped.first.affectedRsnIds, {'101', '102'});

      expect(grouped.last.functionName, 'fetchCustomers');
      expect(grouped.last.count, 1);
    });
  });

  group('DateTimeHelper Tests', () {
    test('Recognizes today dates', () {
      final now = DateTime.now();
      expect(DateTimeHelper.isToday(now), isTrue);
      expect(DateTimeHelper.isToday(now.subtract(const Duration(days: 2))), isFalse);
    });

    test('Relative time formatting produces friendly outputs', () {
      final now = DateTime.now();
      expect(DateTimeHelper.formatRelative(now), 'Just now');
      expect(DateTimeHelper.formatRelative(now.subtract(const Duration(minutes: 5))), '5m ago');
      expect(DateTimeHelper.formatRelative(now.subtract(const Duration(hours: 3))), '3h ago');
    });
  });

  group('VersionRouteAnalyzer Tests', () {
    test('Calculates routes using each version accurately', () {
      final sampleDocs = [
        {
          'Route': 'Route 74',
          'appVersion': 'v1.1.21+10',
          'RSNID': '101',
          'date': 'September 11, 2026',
        },
        {
          'Route': 'Route 12',
          'appVersion': 'v1.1.21+10',
          'RSNID': '102',
          'date': 'September 11, 2026',
        },
        {
          'Route': 'Route 74',
          'appVersion': 'v1.1.21+10', // duplicate route on same version
          'RSNID': '101',
          'date': 'September 11, 2026',
        },
        {
          'Route': 'Route 5',
          'appversion': 'v1.1.20+9', // older version with lowercase key
          'RSNID': '103',
          'date': 'September 10, 2026',
        },
      ];

      final groups = VersionRouteAnalyzer.analyze(sampleDocs);
      expect(groups.length, 2);

      final v21 = groups.firstWhere((g) => g.version == 'v1.1.21+10');
      expect(v21.routeCount, 2); // Route 74, Route 12
      expect(v21.routes, {'Route 74', 'Route 12'});
      expect(v21.errorCount, 3);

      final v20 = groups.firstWhere((g) => g.version == 'v1.1.20+9');
      expect(v20.routeCount, 1);
      expect(v20.routes, {'Route 5'});
      expect(v20.errorCount, 1);
    });
  });
}
