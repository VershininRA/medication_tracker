// lib/services/hive_service.dart
import 'package:hive/hive.dart';
import '../models/models.dart';

class HiveService {
  late final Box<Medicine> _medicinesBox;
  late final Box<Reminder> _remindersBox;
  late final Box<SideEffect> _sideEffectsBox;
  late final Box<CycleDay> _cycleDaysBox;

  HiveService() {
    _medicinesBox = Hive.box<Medicine>('medicines');
    _remindersBox = Hive.box<Reminder>('reminders');
    _sideEffectsBox = Hive.box<SideEffect>('side_effects');
    _cycleDaysBox = Hive.box<CycleDay>('cycle_days');
  }

  // Medicine
  Future<void> addMedicine(Medicine medicine) async => 
      await _medicinesBox.put(medicine.id, medicine);
  List<Medicine> getActiveMedicines() => 
      _medicinesBox.values.where((m) => m.isActive).toList();
  Medicine? getMedicineById(String id) => _medicinesBox.get(id);
  Future<void> updateMedicine(Medicine medicine) async => 
      await _medicinesBox.put(medicine.id, medicine);
  Future<void> deleteMedicine(String id) async => 
      await _medicinesBox.delete(id);

  // Reminder
  Future<void> addReminder(Reminder reminder) async => 
      await _remindersBox.put(reminder.id, reminder);
  List<Reminder> getRemindersForMedicine(String medicineId) => 
      _remindersBox.values.where((r) => r.medicineId == medicineId).toList();
  Future<void> deleteReminder(String id) async => 
      await _remindersBox.delete(id);

  // SideEffect
  Future<void> addSideEffect(SideEffect sideEffect) async => 
      await _sideEffectsBox.put(sideEffect.id, sideEffect);
  List<SideEffect> getSideEffectsByMedicine(String medicineId) => 
      _sideEffectsBox.values.where((s) => s.medicineId == medicineId).toList();

  // CycleDay
  Future<void> addCycleDay(CycleDay cycleDay) async => 
      await _cycleDaysBox.put(cycleDay.id, cycleDay);
}