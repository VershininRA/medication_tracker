import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Для красивого формата даты
import '../providers/side_effect_provider.dart';
import '../providers/medicine_provider.dart';
import '../models/side_effect.dart';

class SideEffectsScreen extends StatelessWidget {
  const SideEffectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дневник симптомов'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Consumer<SideEffectProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final effects = provider.sideEffects;

          if (effects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Записей пока нет',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Здесь вы можете отслеживать побочные эффекты и симптомы в привязке к циклу.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: effects.length,
            itemBuilder: (context, index) {
              final effect = effects[index];
              return _buildEffectCard(context, effect, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEffectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Записать симптом'),
        backgroundColor: const Color(0xFFE8A4B8),
      ),
    );
  }

  Widget _buildEffectCard(BuildContext context, SideEffect effect, SideEffectProvider provider) {
    // Цвета для тяжести
    Color severityColor;
    String severityText;
    IconData severityIcon;

    switch (effect.severity) {
      case 1:
        severityColor = Colors.green;
        severityText = 'Лёгкий';
        severityIcon = Icons.sentiment_satisfied;
        break;
      case 2:
        severityColor = Colors.orange;
        severityText = 'Средний';
        severityIcon = Icons.sentiment_neutral;
        break;
      case 3:
        severityColor = Colors.red;
        severityText = 'Тяжёлый';
        severityIcon = Icons.sentiment_very_dissatisfied;
        break;
      default:
        severityColor = Colors.grey;
        severityText = 'Не указано';
        severityIcon = Icons.help_outline;
    }

    // Находим имя лекарства, если есть ID
    String medicineName = 'Общее состояние';
    if (effect.medicineId != null) {
      final medProvider = Provider.of<MedicineProvider>(context, listen: false);
      final med = medProvider.getMedicine(effect.medicineId!);
      if (med != null) medicineName = med.name;
    }

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя строка: Дата + Удалить
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(effect.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.redAccent,
                  onPressed: () => _confirmDelete(context, effect, provider),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Заголовок: Лекарство + Тяжесть
            Row(
              children: [
                Expanded(
                  child: Text(
                    medicineName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: severityColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(severityIcon, size: 16, color: severityColor),
                      const SizedBox(width: 4),
                      Text(
                        severityText,
                        style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Описание
            Text(
              effect.description,
              style: const TextStyle(fontSize: 15),
            ),
            
            // Примечания (если есть)
            if (effect.notes != null && effect.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  effect.notes!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                ),
              ),
            ],

            // День цикла (если есть)
            if (effect.cycleDay != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.pink[300]),
                  const SizedBox(width: 4),
                  Text(
                    '${effect.cycleDay}-й день цикла',
                    style: TextStyle(fontSize: 12, color: Colors.pink[400], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SideEffect effect, SideEffectProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: const Text('Эта запись о симптоме будет удалена безвозвратно.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              provider.deleteSideEffect(effect.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Запись удалена'), backgroundColor: Colors.red),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // 🔹 ДИАЛОГ ДОБАВЛЕНИЯ
  void _showAddEffectDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    final notesController = TextEditingController();
    int selectedSeverity = 1;
    int? selectedCycleDay;
    String? selectedMedicineId;

    final medProvider = Provider.of<MedicineProvider>(context, listen: false);
    final medicines = medProvider.medicines; // Все лекарства (можно фильтровать активные)

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Новый симптом'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Выбор лекарства (опционально)
                const Text('Лекарство (если связано):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedMedicineId,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Не связано'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Общее состояние')),
                    ...medicines.map((med) => DropdownMenuItem(value: med.id, child: Text(med.name))),
                  ],
                  onChanged: (val) => setDialogState(() => selectedMedicineId = val),
                ),
                
                const SizedBox(height: 16),
                
                // Тяжесть
                const Text('Тяжесть:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('🟢 Лёгкий'),
                        selected: selectedSeverity == 1,
                        onSelected: (val) => setDialogState(() => selectedSeverity = 1),
                        backgroundColor: Colors.green[50],
                        selectedColor: Colors.green[200],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('🟡 Средний'),
                        selected: selectedSeverity == 2,
                        onSelected: (val) => setDialogState(() => selectedSeverity = 2),
                        backgroundColor: Colors.orange[50],
                        selectedColor: Colors.orange[200],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('🔴 Тяжёлый'),
                        selected: selectedSeverity == 3,
                        onSelected: (val) => setDialogState(() => selectedSeverity = 3),
                        backgroundColor: Colors.red[50],
                        selectedColor: Colors.red[200],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // День цикла
                const Text('День цикла (опционально):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Например: 14',
                  ),
                  onChanged: (val) {
                    selectedCycleDay = int.tryParse(val);
                  },
                ),

                const SizedBox(height: 16),

                // Описание
                const Text('Описание:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Что вы чувствуете?',
                  ),
                ),

                const SizedBox(height: 16),

                // Заметки
                const Text('Заметки (опционально):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Дополнительная информация...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () {
                if (descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Введите описание симптома')),
                  );
                  return;
                }

                // Добавляем через провайдер
                Provider.of<SideEffectProvider>(context, listen: false).addSideEffect(
                  medicineId: selectedMedicineId,
                  description: descriptionController.text.trim(),
                  severity: selectedSeverity,
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  cycleDay: selectedCycleDay,
                );

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Симптом записан'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}