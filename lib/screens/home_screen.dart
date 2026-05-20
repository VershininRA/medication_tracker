import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import 'add_medicine_screen.dart';
import 'side_effects_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои лекарства'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.note_alt_outlined),
            tooltip: 'Дневник симптомов',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SideEffectsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Календарь цикла',
            onPressed: () {
              // TODO: Навигация на экран календаря
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Календарь в разработке')),
              );
            },
          ),
        ],
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Получаем лекарства НА СЕГОДНЯ, которые ЕЩЕ НЕ ПРИНЯТЫ
          final today = DateTime.now();
          final todaysMeds = provider.medicines
              .where((med) => med.shouldTakeToday(today) && !med.isTakenToday())
              .toList();

          if (todaysMeds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.green.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'На сегодня всё готово!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Все лекарства приняты или их нет в расписании.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => provider.refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: todaysMeds.length,
              itemBuilder: (context, index) {
                final medicine = todaysMeds[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    // 👈 ЛЕВАЯ ЧАСТЬ: Галочка для отметки
                    leading: Checkbox(
                      value: false, // Всегда false, так как если принято, оно исчезнет из списка
                      onChanged: (val) async {
                        if (val == true) {
                          await provider.markAsTaken(medicine.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${medicine.name} принято!'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        }
                      },
                      activeColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // 👈 ЦЕНТР: Информация
                    title: Text(
                      medicine.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (medicine.dosage != null && medicine.dosage!.isNotEmpty)
                          Text(
                            medicine.dosage!,
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                medicine.schedule.join(', '),
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // 👈 ПРАВАЯ ЧАСТЬ: Кнопки действий
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          color: Theme.of(context).primaryColor,
                          tooltip: 'Редактировать',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddMedicineScreen(medicine: medicine),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.redAccent.shade400,
                          tooltip: 'Удалить',
                          onPressed: () => _showDeleteDialog(context, medicine),
                        ),
                      ],
                    ),
                    onTap: null, // Отключаем реакцию на нажатие всей карточки
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMedicineScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
        backgroundColor: const Color(0xFFE8A4B8),
      ),
    );
  }

  // Диалог удаления
  void _showDeleteDialog(BuildContext context, dynamic medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить лекарство?'),
        content: Text('Вы уверены, что хотите удалить «${medicine.name}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<MedicineProvider>(context, listen: false)
                  .deleteMedicine(medicine.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent.shade400),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}