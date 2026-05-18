import 'package:hive/hive.dart';
part 'medicine.g.dart';

@HiveType(typeId: 0)
class Medicine extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final String? dosage;
  @HiveField(3) final String? description;
  @HiveField(4) final List<String> schedule;
  @HiveField(5) final List<int> daysOfWeek;
  @HiveField(6) final bool isCyclic;
  @HiveField(7) final int? cycleStartDay;
  @HiveField(8) final int? cycleEndDay;
  @HiveField(9) final DateTime createdAt;
  @HiveField(10) final bool isActive;

  Medicine({
    required this.id,
    required this.name,
    this.dosage,
    this.description,
    required this.schedule,
    required this.daysOfWeek,
    this.isCyclic = false,
    this.cycleStartDay,
    this.cycleEndDay,
    required this.createdAt,
    this.isActive = true,
  });

  bool shouldTakeToday(DateTime today) {
    if (!isActive) return false;
    return daysOfWeek.contains(today.weekday);
  }
}