// lib/repositories/medication_repository.dart
// Репозиторий: бизнес-логика работы с лекарствами

import '../models/models.dart';
import '../services/hive_service.dart';

class MedicationRepository {
  final HiveService _hiveService;

  MedicationRepository(this._hiveService);

  // ==================== MEDICINE ====================
  
  /// Добавить лекарство с валидацией
  Future<bool> addMedicine({
    required String name,
    String? dosage,
    String? description,
    required List<String> schedule, // ["08:00", "20:00"]
    required List<int> daysOfWeek,  // [1, 2, 3] = Пн, Вт, Ср
    bool isCyclic = false,
    int? cycleStartDay,
    int? cycleEndDay,
  }) async {
    // 🔹 Валидация
    if (name.trim().isEmpty) return false;
    if (schedule.isEmpty) return false;
    if (daysOfWeek.isEmpty) return false;

    // 🔹 Генерируем уникальный ID
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final medicine = Medicine(
      id: id,
      name: name.trim(),
      dosage: dosage?.trim(),
      description: description?.trim(),
      schedule: schedule,
      daysOfWeek: daysOfWeek,
      isCyclic: isCyclic,
      cycleStartDay: cycleStartDay,
      cycleEndDay: cycleEndDay,
      createdAt: DateTime.now(),
      isActive: true,
    );

    try {
      await _hiveService.addMedicine(medicine);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Получить список лекарств на СЕГОДНЯ
  List<Medicine> getTodaysMedicines() {
    final today = DateTime.now();
    return _hiveService.getActiveMedicines()
        .where((med) => med.shouldTakeToday(today) && !med.isTakenToday())
        .toList()
        ..sort((a, b) {
          // Сортируем по времени в расписании
          if (a.schedule.isEmpty || b.schedule.isEmpty) return 0;
          return a.schedule.first.compareTo(b.schedule.first);
        });
  }

  /// Получить все активные лекарства
  List<Medicine> getAllActiveMedicines() {
    return _hiveService.getActiveMedicines();
  }

  /// Получить лекарство по ID
  Medicine? getMedicine(String id) {
    return _hiveService.getMedicineById(id);
  }

  /// Обновить лекарство
  Future<bool> updateMedicine(Medicine medicine) async {
    try {
      await _hiveService.updateMedicine(medicine);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Удалить лекарство (мягкое)
  Future<bool> deleteMedicine(String id) async {
    try {
      await _hiveService.deleteMedicine(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== REMINDER ====================
  
  Future<bool> addReminder({
    required String medicineId,
    required int hour,
    required int minute,
    required List<int> daysOfWeek,
    String? customMessage,
  }) async {
    if (hour < 0 || hour > 23) return false;
    if (minute < 0 || minute > 59) return false;
    if (daysOfWeek.isEmpty) return false;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    final reminder = Reminder(
      id: id,
      medicineId: medicineId,
      hour: hour,
      minute: minute,
      daysOfWeek: daysOfWeek,
      isEnabled: true,
      createdAt: DateTime.now(),
    );

    try {
      await _hiveService.addReminder(reminder);
      return true;
    } catch (e) {
      return false;
    }
  }

  List<Reminder> getRemindersForMedicine(String medicineId) {
    return _hiveService.getRemindersForMedicine(medicineId);
  }

  // ==================== SIDE EFFECT ====================
  
  Future<bool> addSideEffect({
    String? medicineId,
    required String description,
    required int severity, // 1=лёгкий, 2=средний, 3=тяжёлый
    String? notes,
    int? cycleDay,
  }) async {
    if (description.trim().isEmpty) return false;
    if (severity < 1 || severity > 3) return false;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    final sideEffect = SideEffect(
      id: id,
      medicineId: medicineId,
      description: description.trim(),
      severity: severity,
      timestamp: DateTime.now(),
      notes: notes?.trim(),
      cycleDay: cycleDay,
    );

    try {
      await _hiveService.addSideEffect(sideEffect);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveSideEffect(SideEffect sideEffect) async {
    if (sideEffect.description.trim().isEmpty) return false;
    if (sideEffect.severity < 1 || sideEffect.severity > 3) return false;

    try {
      await _hiveService.addSideEffect(sideEffect);
      return true;
    } catch (e) {
      return false;
    }
  }


  List<SideEffect> getSideEffectsByMedicine(String medicineId) {
    return _hiveService.getSideEffectsByMedicine(medicineId);
  }

  List<SideEffect> getAllSideEffects() {
    return _hiveService.getAllSideEffects();
  }

  /// Удалить побочный эффект
  Future<bool> deleteSideEffect(String id) async {
    try {
      await _hiveService.deleteSideEffect(id);
      return true;
    } catch (e) {
      return false;
    }
  }

 // ==================== CYCLE ====================
  
  Future<bool> addCycleDay({
    required DateTime date,
    required int dayNumber,
    String? phase,
    required List<String> symptoms,
    String? notes,
  }) async {
    if (dayNumber < 1 || dayNumber > 35) return false;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    final cycleDay = CycleDay(
      id: id,
      date: date,
      cycleDayNumber: dayNumber,
      phase: phase,
      symptoms: symptoms,
      notes: notes,
      createdAt: DateTime.now(),
    );

    try {
      await _hiveService.addCycleDay(cycleDay);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 👇 НОВЫЙ МЕТОД: Отметить лекарство как принятое
  Future<bool> markMedicineAsTaken(String id) async {
    try {
      final box = _hiveService.medicineBox; // Убедись, что в HiveService есть такой getter
      final medicine = box.get(id);
      
      if (medicine == null) return false;

      final updatedMedicine = medicine.markAsTaken();
      await box.put(id, updatedMedicine);
      
      return true;
    } catch (e) {
      return false;
    }
  }
}