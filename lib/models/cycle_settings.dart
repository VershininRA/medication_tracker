import 'package:hive/hive.dart';

part 'cycle_settings.g.dart';

@HiveType(typeId: 4)
class CycleSettings extends HiveObject {
  @HiveField(0) final DateTime lastPeriodStart;
  @HiveField(1) final int cycleLength;
  @HiveField(2) final int periodLength;

  CycleSettings({
    required this.lastPeriodStart,
    this.cycleLength = 28,
    this.periodLength = 5,
  });

  // 🔥 FIX: Вспомогательный метод для обрезки времени до полуночи
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int getCycleDayFor(DateTime date) {
    // Нормализуем обе даты, убирая часы/минуты/секунды
    final start = _normalizeDate(lastPeriodStart);
    final target = _normalizeDate(date);

    final difference = target.difference(start).inDays;

    if (difference < 0) return 0; // Дата до начала цикла

    // Формула: (разница дней % длина цикла) + 1
    // Если разница 0 -> день 1. Если разница 27 (при цикле 28) -> день 28.
    final dayInCycle = (difference % cycleLength) + 1;
    return dayInCycle;
  }

  String getPhaseFor(DateTime date) {
    final day = getCycleDayFor(date);
    
    if (day == 0) return 'unknown';
    if (day >= 1 && day <= periodLength) return 'menstruation';
    
    // Овуляция обычно за 14 дней до конца цикла
    // Для цикла 28 дней это дни 13-15
    final ovulationStart = cycleLength - 16; 
    final ovulationEnd = cycleLength - 12;
    
    if (day >= ovulationStart && day <= ovulationEnd) return 'ovulation';
    
    if (day > periodLength && day < ovulationStart) return 'follicular';
    return 'luteal';
  }
  
  DateTime getNextPeriodStart() {
    return lastPeriodStart.add(Duration(days: cycleLength));
  }
}