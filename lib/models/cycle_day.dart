import 'package:hive/hive.dart';

part 'cycle_day.g.dart';

@HiveType(typeId: 3) // Проверь в main.dart, что typeId совпадает с регистрацией! 
                     // Если у SideEffect typeId=2, то CycleDay должен быть 3 или другим уникальным.
                     // В твоем коде выше SideEffect был typeId=2. 
                     // Давай сделаем CycleDay = 3, чтобы не конфликтовать.
class CycleDay extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final DateTime date;
  @HiveField(2) final int cycleDayNumber;
  @HiveField(3) final String? phase;
  @HiveField(4) final List<String> symptoms;
  @HiveField(5) final String? notes;
  @HiveField(6) final DateTime createdAt;
  
  // 👇 НОВОЕ ПОЛЕ: Настроение (1-Ужасно, 5-Отлично)
  @HiveField(7) final int? moodScore;

  CycleDay({
    required this.id,
    required this.date,
    required this.cycleDayNumber,
    this.phase,
    required this.symptoms,
    this.notes,
    required this.createdAt,
    this.moodScore,
  });

  // Метод для обновления настроения (возвращает новую копию объекта)
  CycleDay copyWith({int? moodScore}) {
    return CycleDay(
      id: id,
      date: date,
      cycleDayNumber: cycleDayNumber,
      phase: phase,
      symptoms: symptoms,
      notes: notes,
      createdAt: createdAt,
      moodScore: moodScore ?? this.moodScore,
    );
  }
}