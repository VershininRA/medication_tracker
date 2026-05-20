// lib/providers/medicine_provider.dart
// lib/providers/medicine_provider.dart
import 'package:flutter/foundation.dart';
import '../repositories/medication_repository.dart';
import '../models/models.dart';

class MedicineProvider with ChangeNotifier {
  final MedicationRepository _repo;
  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String? _error;

  MedicineProvider(this._repo) {
    loadAllMedicines();
  }

  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Загрузить только те лекарства, которые нужно принять сегодня (и еще не приняты)
  void loadTodaysMedicines() {
    try {
      _medicines = _repo.getTodaysMedicines();
      _error = null;
    } catch (e) { 
      _error = 'Ошибка загрузки: $e'; 
    }
    notifyListeners();
  }

  /// Загрузить все активные лекарства (для полного списка)
  void loadAllMedicines() {
    try {
      _medicines = _repo.getAllActiveMedicines();
      _error = null;
    } catch (e) { 
      _error = 'Ошибка загрузки: $e'; 
    }
    notifyListeners();
  }

  Future<bool> addMedicine({
    required String name, String? dosage, String? description,
    required List<String> schedule, required List<int> daysOfWeek,
    bool isCyclic = false, int? cycleStartDay, int? cycleEndDay,
  }) async {
    _isLoading = true; notifyListeners();
    try {
      final ok = await _repo.addMedicine(
        name: name, dosage: dosage, description: description, 
        schedule: schedule, daysOfWeek: daysOfWeek, 
        isCyclic: isCyclic, cycleStartDay: cycleStartDay, cycleEndDay: cycleEndDay,
      );
      if (ok) loadAllMedicines();
      else _error = 'Не удалось добавить';
      return ok;
    } catch (e) { 
      _error = 'Ошибка: $e'; 
      return false; 
    } finally { 
      _isLoading = false; 
      notifyListeners(); 
    }
  }

  Future<bool> updateMedicine({
    required String id, required String name, String? dosage, String? description,
    required List<String> schedule, required List<int> daysOfWeek,
    bool isCyclic = false, int? cycleStartDay, int? cycleEndDay,
  }) async {
    _isLoading = true; notifyListeners();
    try {
      final existing = _repo.getMedicine(id);
      if (existing == null) { _error = 'Не найдено'; return false; }
      
      final updated = Medicine(
        id: existing.id, 
        name: name.trim(), 
        dosage: dosage?.trim(), 
        description: description?.trim(), 
        schedule: schedule, 
        daysOfWeek: daysOfWeek, 
        isCyclic: isCyclic, 
        cycleStartDay: cycleStartDay, 
        cycleEndDay: cycleEndDay, 
        createdAt: existing.createdAt, 
        isActive: true,
        takenDates: existing.takenDates, // Сохраняем историю приемов!
      );
      
      final ok = await _repo.updateMedicine(updated);
      if (ok) loadAllMedicines();
      else _error = 'Ошибка обновления';
      return ok;
    } catch (e) { 
      _error = 'Ошибка: $e'; 
      return false; 
    } finally { 
      _isLoading = false; 
      notifyListeners(); 
    }
  }

  /// 🔹 НОВЫЙ МЕТОД: Отметить как принятое
  Future<bool> markAsTaken(String id) async {
    try {
      final ok = await _repo.markMedicineAsTaken(id);
      if (ok) {
        loadAllMedicines();
      } else {
        _error = 'Ошибка отметки';
      }
      return ok;
    } catch (e) {
      _error = 'Ошибка: $e';
      return false;
    }
  }

  Future<bool> deleteMedicine(String id) async {
    _isLoading = true; notifyListeners();
    try {
      final ok = await _repo.deleteMedicine(id);
      if (ok) loadAllMedicines();
      else _error = 'Ошибка удаления';
      return ok;
    } catch (e) { 
      _error = 'Ошибка: $e'; 
      return false; 
    } finally { 
      _isLoading = false; 
      notifyListeners(); 
    }
  }

  Medicine? getMedicine(String id) => _repo.getMedicine(id);
  List<Reminder> getReminders(String medId) => _repo.getRemindersForMedicine(medId);
  void refresh() => loadAllMedicines();
}
