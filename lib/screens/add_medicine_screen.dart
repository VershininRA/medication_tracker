import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../models/models.dart';
import '../services/notification_service.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicine;

  const AddMedicineScreen({super.key, this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Контроллеры
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _descriptionController;
  final _searchController = TextEditingController();

  // Данные
  final List<String> _selectedTimes = [];
  final List<int> _selectedDays = [];
  bool _isCyclic = false;
  int? _cycleStartDay;
  int? _cycleEndDay;
  bool _enableNotifications = true;

  // Для имитации поиска (удалить при подключении реальной БД)
  final List<String> _mockDatabase = [
    'Аспирин', 'Ибупрофен', 'Парацетамол', 'Магне B6', 
    'Фолиевая кислота', 'Дюфастон', 'Железо', 'Витамин D'
  ];
  List<String> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medicine?.name ?? '');
    _dosageController = TextEditingController(text: widget.medicine?.dosage ?? '');
    _descriptionController = TextEditingController(text: widget.medicine?.description ?? '');
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
    _searchController.dispose();
    super.dispose();
  }

  // 🔹 Поиск (Имитация)
  void _runSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _searchResults = _mockDatabase
          .where((name) => name.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();
    });
  }

  // 🔹 Выбор из базы
  void _selectFromDatabase(String name) {
    setState(() {
      _nameController.text = name;
      _searchResults = [];
      _searchController.clear();
      // Тут в будущем можно подтянуть описание из БД
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Препарат "$name" найден в базе'), duration: const Duration(seconds: 1)),
      );
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (!_selectedTimes.contains(timeString)) {
        setState(() {
          _selectedTimes.add(timeString);
          _selectedTimes.sort();
        });
      }
    }
  }

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

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏰ Добавьте время приёма')),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📅 Выберите дни недели')),
      );
      return;
    }

    final provider = Provider.of<MedicineProvider>(context, listen: false);
    bool success;

    if (widget.medicine != null) {
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

      if (success && _enableNotifications && mounted) {
        final medName = _nameController.text.trim();
        final medDosage = _dosageController.text.trim();
        for (int i = 0; i < _selectedTimes.length; i++) {
          final parts = _selectedTimes[i].split(':');
          await NotificationService().scheduleMedicationReminder(
            id: DateTime.now().millisecondsSinceEpoch + i,
            title: '💊 Пора принимать лекарство',
            body: medDosage.isNotEmpty ? '$medName ($medDosage)' : medName,
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
            daysOfWeek: _selectedDays,
          );
        }
      }
    }

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка сохранения')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medicine != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать' : 'Новый препарат'),
        centerTitle: true,
        // Убрали галочку отсюда
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1️⃣ ПОИСК ПРЕПАРАТА (Для будущей БД)
            if (!isEditing) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🔍 Найти в базе препаратов', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Начните вводить название...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: _runSearch,
                      ),
                      if (_searchResults.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (ctx, i) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.medication, color: Colors.blue),
                              title: Text(_searchResults[i]),
                              onTap: () => _selectFromDatabase(_searchResults[i]),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2️⃣ ОСНОВНАЯ ИНФОРМАЦИЯ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название препарата *',
                        prefixIcon: Icon(Icons.medication_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.trim().isEmpty == true ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dosageController,
                            decoration: const InputDecoration(
                              labelText: 'Дозировка',
                              prefixIcon: Icon(Icons.scale_outlined),
                              hintText: 'напр. 10 мг',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Инструкция / Заметки',
                        prefixIcon: Icon(Icons.note_outlined),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3️⃣ РАСПИСАНИЕ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Время приёма *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (_selectedTimes.isEmpty)
                      const Text('Нет выбранного времени', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedTimes.map((t) => Chip(
                          label: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white70),
                          onDeleted: () => setState(() => _selectedTimes.remove(t)),
                          backgroundColor: Theme.of(context).primaryColor,
                        )).toList(),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time_filled),
                        label: const Text('Добавить время'),
                      ),
                    ),
                    const Divider(height: 32),
                    const Text('Дни недели *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (i) {
                        final dayNum = i + 1;
                        final isSelected = _selectedDays.contains(dayNum);
                        return ChoiceChip(
                          label: Text(['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][i]),
                          selected: isSelected,
                          onSelected: (_) => _toggleDay(dayNum),
                          selectedColor: Theme.of(context).primaryColor,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4️⃣ НАСТРОЙКИ (Цикл и Уведомления)
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.repeat, color: Colors.pink),
                    title: const Text('Привязка к циклу'),
                    subtitle: const Text('Приём в определённые дни цикла'),
                    value: _isCyclic,
                    onChanged: (v) => setState(() => _isCyclic = v),
                  ),
                  if (_isCyclic)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Начало (день)', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => _cycleStartDay = int.tryParse(v))),
                          const SizedBox(width: 16),
                          Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Конец (день)', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => _cycleEndDay = int.tryParse(v))),
                        ],
                      ),
                    ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active, color: Colors.orange),
                    title: const Text('Напоминания'),
                    subtitle: const Text('Push-уведомления в заданное время'),
                    value: _enableNotifications,
                    onChanged: (v) => setState(() => _enableNotifications = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5️⃣ КНОПКА СОХРАНЕНИЯ (Единственная)
            ElevatedButton(
              onPressed: _saveMedicine,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_alt),
                  const SizedBox(width: 8),
                  Text(isEditing ? 'Сохранить изменения' : 'Добавить препарат', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}