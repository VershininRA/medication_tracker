// lib/models/side_effect.dart
import 'package:hive/hive.dart';

part 'side_effect.g.dart';

@HiveType(typeId: 2)
class SideEffect extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String? medicineId;
  @HiveField(2) final String description;
  @HiveField(3) final int severity;
  @HiveField(4) final DateTime timestamp;
  @HiveField(5) final String? notes;
  @HiveField(6) final int? cycleDay;  // ← Добавлено!

  SideEffect({
    required this.id,
    this.medicineId,
    required this.description,
    required this.severity,
    required this.timestamp,
    this.notes,
    this.cycleDay,  // ← Добавлено!
  });
}