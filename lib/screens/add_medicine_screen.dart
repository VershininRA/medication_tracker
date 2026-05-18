// lib/screens/add_medicine_screen.dart
// Экран добавления/редактирования лекарства — ИСПРАВЛЕННАЯ ВЕРСИЯ

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../models/models.dart';
import '../services/notification_service.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicine; // Если передали — режим редактирования

  const AddMedicineScreen({super.key, this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для полей формы
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _descriptionController;

  // Выбранные значения
  final List<String> _selectedTimes = [];
  final List<int> _selectedDays = [];
  bool _isCyclic = false;
  int? _cycleStartDay;
  int? _cycleEndDay;
  bool _enableNotifications = true; // Переключатель уведомлений

  @override
  void initState() {
    super.initState();
    // Если редактируем — заполняем форму существующими данными
    _nameController = TextEditingController(text: widget.medicine?.name);
    _dosageController = TextEditingController(text: widget.medicine?.dosage);
    _descriptionController = TextEditingController(text: widget.medicine?.description);
    _selectedTimes.addAll(widget.medicine?.schedule ?? []);
    _selectedDays.addAll(widget.medicine?.daysOfWeek ?? [1, 2, 3, 4, 5, 6, 7]);
    _isCyclic = widget.medicine?.isCyclic ?? false;
    _cycleStartDay = widget.medicine?.cycleStartDay;
    _cycleEndDay = widget.medicine?.cycleEndDay;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 🔹 Диалог выбора времени
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (!_selectedTimes.contains(timeString)) {
          _selectedTimes.add(timeString);
          _selectedTimes.sort();
        }
      });
    }
  }

  // 🔹 Переключение дня недели
  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
        _selectedDays.sort();
      }
    });
  }

  // 🔹 Сохранение лекарства
  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы одно время приёма')),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы один день')),
      );
      return;
    }

    final provider = Provider.of<MedicineProvider>(context, listen: false);

    bool success;

    if (widget.medicine != null) {
      // 🔹 РЕДАКТИРОВАНИЕ существующего лекарства
      success = await provider.updateMedicine(
        id: widget.medicine!.id,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        description: _descriptionController.text.trim(),
        schedule: _selectedTimes,
        daysOfWeek: _selectedDays,
        isCyclic: _isCyclic,
        cycleStartDay: _isCyclic ? _cycleStartDay : null,
        cycleEndDay: _isCyclic ? _cycleEndDay : null,
      );
    } else {
      // 🔹 СОЗДАНИЕ нового лекарства
      success = await provider.addMedicine(
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        description: _descriptionController.text.trim(),
        schedule: _selectedTimes,
        daysOfWeek: _selectedDays,
        isCyclic: _isCyclic,
        cycleStartDay: _isCyclic ? _cycleStartDay : null,
        cycleEndDay: _isCyclic ? _cycleEndDay : null,
      );

      // 🔹 Планируем уведомления (только для новых лекарств)
      if (success && _enableNotifications && mounted) {
        final medName = _nameController.text.trim();
        final medDosage = _dosageController.text.trim();
        for (int i = 0; i < _selectedTimes.length; i++) {
          final parts = _selectedTimes[i].split(':');
          await NotificationService().scheduleMedicationReminder(
            id: DateTime.now().millisecondsSinceEpoch + i, // ✅ Исправлено: id вместо baseId
            title: '💊 Время принять лекарство',
            body: medDosage.isNotEmpty ? '$medName ($medDosage)' : medName,
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
            daysOfWeek: _selectedDays,
          );
        }
      }
    }

    if (success && mounted) {
      Navigator.pop(context); // Возвращаемся назад
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить. Попробуйте ещё раз.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicine == null ? 'Новое лекарство' : 'Редактировать'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveMedicine,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🔹 Название препарата (обязательное)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название препарата *',
                prefixIcon: Icon(Icons.medication),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.trim().isEmpty == true 
                ? 'Введите название' 
                : null,
            ),
            const SizedBox(height: 16),

            // 🔹 Дозировка
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Дозировка',
                prefixIcon: Icon(Icons.scale),
                hintText: 'например: 10 мг, 1 таблетка',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Описание
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание / Инструкция',
                prefixIcon: Icon(Icons.info_outline),
                hintText: 'Принимать после еды, запивать водой...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // 🔹 Время приёма
            const Text('Время приёма *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._selectedTimes.map((time) => Chip(
                  label: Text(time),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => setState(() => _selectedTimes.remove(time)),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                )),
                // ✅ ИСПРАВЛЕНО: используем ActionChip вместо Chip с onPressed
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Добавить'),
                  onPressed: _pickTime,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 🔹 Дни недели
            const Text('Дни недели *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                for (int i = 1; i <= 7; i++)
                  ChoiceChip(
                    label: Text(['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][i - 1]),
                    selected: _selectedDays.contains(i),
                    onSelected: (_) => _toggleDay(i),
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: _selectedDays.contains(i) ? Colors.white : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // 🔹 Циклическая терапия
            SwitchListTile(
              title: const Text('Привязать к менструальному циклу'),
              subtitle: const Text('Приём только в определённые дни цикла'),
              value: _isCyclic,
              onChanged: (value) => setState(() => _isCyclic = value),
              secondary: const Icon(Icons.repeat),
            ),
            
            if (_isCyclic) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'День начала',
                        border: OutlineInputBorder(),
                        hintText: '1-35',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _cycleStartDay = int.tryParse(v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'День окончания',
                        border: OutlineInputBorder(),
                        hintText: '1-35',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _cycleEndDay = int.tryParse(v),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // 🔹 Переключатель уведомлений
            SwitchListTile(
              title: const Text('Включить напоминания'),
              subtitle: const Text('Получать уведомления в заданное время'),
              value: _enableNotifications,
              onChanged: (value) => setState(() => _enableNotifications = value),
              secondary: const Icon(Icons.notifications_active),
            ),
            const SizedBox(height: 24),

            // 🔹 Кнопка сохранения
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveMedicine,
                icon: const Icon(Icons.save),
                label: const Text('Сохранить лекарство'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}