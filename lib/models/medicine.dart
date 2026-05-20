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
  
  // 🔹 НОВОЕ ПОЛЕ: Даты, когда лекарство было принято (формат "YYYY-MM-DD")
  @HiveField(11) final List<String> takenDates;

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
    List<String>? takenDates,
  }) : takenDates = takenDates ?? [];

  /// Проверяет, нужно ли принимать лекарство сегодня
  bool shouldTakeToday(DateTime today) {
    if (!isActive) return false;
    
    // 1. Проверка дня недели
    if (!daysOfWeek.contains(today.weekday)) return false;

    // 2. Проверка цикличности
    if (isCyclic && cycleStartDay != null && cycleEndDay != null) {
      // TODO: Здесь нужна логика получения текущего дня цикла из отдельного сервиса
      // Пока считаем, что если день подходит по дню недели, то ок.
      // В полной версии нужно передавать currentCycleDay аргументом
    }

    return true;
  }

  /// Проверяет, принято ли лекарство СЕГОДНЯ
  bool isTakenToday() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return takenDates.contains(todayStr);
  }

  /// Возвращает новую копию объекта с добавленной датой приема
  Medicine markAsTaken() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    if (takenDates.contains(todayStr)) {
      return this; // Уже отмечено
    }

    final updatedDates = List<String>.from(takenDates)..add(todayStr);
    
    return Medicine(
      id: id,
      name: name,
      dosage: dosage,
      description: description,
      schedule: schedule,
      daysOfWeek: daysOfWeek,
      isCyclic: isCyclic,
      cycleStartDay: cycleStartDay,
      cycleEndDay: cycleEndDay,
      createdAt: createdAt,
      isActive: isActive,
      takenDates: updatedDates,
    );
  }
  
  /// Получить отформатированное время следующего приема (упрощенно)
  String getNextScheduleTime() {
    if (schedule.isEmpty) return '';
    // Находим ближайшее время относительно сейчас (упрощенно берем первое)
    return schedule.first;
  }
}