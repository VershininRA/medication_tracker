// lib/services/hive_service.dart
import 'package:hive/hive.dart';
import '../models/models.dart';
import '../models/cycle_settings.dart';
import '../models/user_profile.dart';
import '../models/cycle_day.dart'; 

class HiveService {
  late final Box<Medicine> _medicinesBox;
  late final Box<Reminder> _remindersBox;
  late final Box<SideEffect> _sideEffectsBox;
  late final Box<CycleDay> _cycleDaysBox;
  late final Box<CycleSettings> _cycleSettingsBox;
  late final Box<UserProfile> _profileBox;

  HiveService() {
    _medicinesBox = Hive.box<Medicine>('medicines');
    _remindersBox = Hive.box<Reminder>('reminders');
    _sideEffectsBox = Hive.box<SideEffect>('side_effects');
    _cycleDaysBox = Hive.box<CycleDay>('cycle_days');
    _cycleSettingsBox = Hive.box<CycleSettings>('cycle_settings');
    _profileBox = Hive.box<UserProfile>('user_profile');
  }

  // --- Medicine ---
  Box<Medicine> get medicineBox => _medicinesBox;
  Future<void> addMedicine(Medicine medicine) async => await _medicinesBox.put(medicine.id, medicine);
  List<Medicine> getActiveMedicines() => _medicinesBox.values.where((m) => m.isActive).toList();
  Medicine? getMedicineById(String id) => _medicinesBox.get(id);
  Future<void> updateMedicine(Medicine medicine) async => await _medicinesBox.put(medicine.id, medicine);
  Future<void> deleteMedicine(String id) async => await _medicinesBox.delete(id);

  // --- Reminder ---
  Future<void> addReminder(Reminder reminder) async => await _remindersBox.put(reminder.id, reminder);
  List<Reminder> getRemindersForMedicine(String medicineId) => 
      _remindersBox.values.where((r) => r.medicineId == medicineId).toList();
  Future<void> deleteReminder(String id) async => await _remindersBox.delete(id);

  // --- SideEffect ---
  Future<void> addSideEffect(SideEffect sideEffect) async => await _sideEffectsBox.put(sideEffect.id, sideEffect);
  List<SideEffect> getSideEffectsByMedicine(String medicineId) => 
      _sideEffectsBox.values.where((s) => s.medicineId == medicineId).toList();
  List<SideEffect> getAllSideEffects() {
    final all = _sideEffectsBox.values.toList();
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all;
  }
  Future<void> deleteSideEffect(String id) async => await _sideEffectsBox.delete(id);

  // --- CycleDay & Mood ---
  Future<void> addCycleDay(CycleDay cycleDay) async => await _cycleDaysBox.put(cycleDay.id, cycleDay);
  
  CycleDay? getCycleDayByDate(DateTime date) {
    try {
      return _cycleDaysBox.values.firstWhere(
        (day) => day.date.year == date.year && 
                 day.date.month == date.month && 
                 day.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> updateMood(DateTime date, int score) async {
    CycleDay? existingDay = getCycleDayByDate(date);

    if (existingDay != null && existingDay.id.isNotEmpty) {
      final updated = existingDay.copyWith(moodScore: score);
      await _cycleDaysBox.put(existingDay.id, updated);
    } else {
      final newDay = CycleDay(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime(date.year, date.month, date.day), // Нормализуем дату
        cycleDayNumber: 1, 
        symptoms: [],
        createdAt: DateTime.now(),
        moodScore: score,
      );
      await _cycleDaysBox.put(newDay.id, newDay);
    }
  }
  
  List<CycleDay> getAllCycleDays() => _cycleDaysBox.values.toList();

  // --- Settings & Profile ---
  Box<CycleSettings> get cycleSettingsBox => _cycleSettingsBox;
  Future<void> saveCycleSettings(CycleSettings settings) async => await _cycleSettingsBox.put('current_settings', settings);
  CycleSettings? getCycleSettings() => _cycleSettingsBox.get('current_settings');

  Box<UserProfile> get profileBox => _profileBox;
  Future<void> saveProfile(UserProfile profile) async => await _profileBox.put('current_user', profile);
  UserProfile? getProfile() => _profileBox.get('current_user');

  Future<void> clearAllData() async {
    await _medicinesBox.clear();
    await _remindersBox.clear();
    await _sideEffectsBox.clear();
    await _cycleDaysBox.clear();
    await _cycleSettingsBox.clear();
    await _profileBox.clear();
  }
}