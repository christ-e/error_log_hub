import 'package:csv/csv.dart';

void main() {
  final data = [
    ['Name', 'Age', 'City'],
    ['Alice', 30, 'New York'],
  ];
  final String csvString = csv.encode(data);
  print(csvString);
}
