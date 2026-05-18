import 'package:hive/hive.dart';
part 'cycle_day.g.dart';

@HiveType(typeId: 3)
class CycleDay extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final DateTime date;
  @HiveField(2) final int cycleDayNumber;
  @HiveField(3) final String? phase;
  @HiveField(4) final List<String> symptoms;
  @HiveField(5) final String? notes;
  @HiveField(6) final DateTime createdAt;

  CycleDay({
    required this.id,
    required this.date,
    required this.cycleDayNumber,
    this.phase,
    required this.symptoms,
    this.notes,
    required this.createdAt,
  });
}