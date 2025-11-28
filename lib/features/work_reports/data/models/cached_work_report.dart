import 'package:hive/hive.dart';
import 'dart:convert';

part 'cached_work_report.g.dart';

@HiveType(typeId: 0)
class CachedWorkReport {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String jsonString;

  @HiveField(2)
  final bool isPending; // True if created offline and not synced

  @HiveField(3)
  final bool isLocal; // True if created locally, false if from server

  CachedWorkReport({required this.id, required this.jsonString, this.isPending = false, this.isLocal = false});

  // Helper to get the map
  Map<String, dynamic> get json => jsonDecode(jsonString) as Map<String, dynamic>;
}