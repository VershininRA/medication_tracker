import 'package:hive/hive.dart';
part 'reminder.g.dart';

@HiveType(typeId: 1)
class Reminder extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String medicineId;
  @HiveField(2) final int hour;
  @HiveField(3) final int minute;
  @HiveField(4) final List<int> daysOfWeek;
  @HiveField(5) final bool isEnabled;
  @HiveField(6) final DateTime createdAt;

  Reminder({
    required this.id,
    required this.medicineId,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    this.isEnabled = true,
    required this.createdAt,
  });
}