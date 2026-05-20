import 'package:hive/hive.dart';

part 'side_effect.g.dart';

@HiveType(typeId: 2)
class SideEffect extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String? medicineId;
  @HiveField(2) final String description;
  @HiveField(3) final int severity; // 1=Лёгкий, 2=Средний, 3=Тяжёлый
  @HiveField(4) final DateTime timestamp;
  @HiveField(5) final String? notes;
  @HiveField(6) final int? cycleDay;
  
  // 👇 НОВОЕ ПОЛЕ для фото (опционально)
  @HiveField(7) final String? imagePath;

  SideEffect({
    required this.id,
    this.medicineId,
    required this.description,
    required this.severity,
    required this.timestamp,
    this.notes,
    this.cycleDay,
    this.imagePath,
  });

  // Вспомогательный метод для получения цвета тяжести
  String get severityLabel {
    switch (severity) {
      case 1: return 'Лёгкий';
      case 2: return 'Средний';
      case 3: return 'Тяжёлый';
      default: return 'Не указано';
    }
  }
}