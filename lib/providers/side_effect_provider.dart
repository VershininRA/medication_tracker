// lib/providers/side_effect_provider.dart
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/medication_repository.dart';

class SideEffectProvider with ChangeNotifier {
  final MedicationRepository _repo;
  List<SideEffect> _sideEffects = [];
  bool _isLoading = false;
  String? _error;

  SideEffectProvider(this._repo) {
    loadSideEffects();
  }

  List<SideEffect> get sideEffects => _sideEffects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Загрузить все записи
  void loadSideEffects() {
    _isLoading = true;
    notifyListeners();
    
    try {
      // В репозитории пока нет метода getAllSideEffects, добавим его ниже
      // Пока берем заглушку или добавим метод в репозиторий
      _sideEffects = _repo.getAllSideEffects(); 
      _error = null;
    } catch (e) {
      _error = 'Ошибка загрузки: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Добавить новую запись
  Future<bool> addSideEffect({
    required String description,
    required int severity,
    String? notes,
    String? medicineId,
    int? cycleDay,
    String? imagePath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      
      final sideEffect = SideEffect(
        id: id,
        medicineId: medicineId,
        description: description,
        severity: severity,
        timestamp: DateTime.now(),
        notes: notes,
        cycleDay: cycleDay,
        // imagePath: imagePath, // Раскомментируй, когда добавишь поле в модель
      );

      final success = await _repo.saveSideEffect(sideEffect);
      
      if (success) {
        loadSideEffects(); // Обновляем список
        return true;
      } else {
        _error = 'Не удалось сохранить запись';
        return false;
      }
    } catch (e) {
      _error = 'Ошибка: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Удалить запись
  Future<void> deleteSideEffect(String id) async {
    try {
      await _repo.deleteSideEffect(id);
      loadSideEffects();
    } catch (e) {
      _error = 'Ошибка удаления: $e';
      notifyListeners();
    }
  }
}