// lib/screens/home_screen.dart
// Главный экран: список активных лекарств

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import 'add_medicine_screen.dart'; // Убедись, что путь верный

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
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Календарь цикла',
            onPressed: () {
              // TODO: Навигация на экран календаря/цикла
            },
          ),
        ],
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          // 🔹 Состояние загрузки
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔹 Пустой список
          if (provider.medicines.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 80,
                      color: Theme.of(context).primaryColor.withOpacity(0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Список лекарств пуст',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Нажмите кнопку "+", чтобы добавить первый препарат',
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

          // 🔹 Список лекарств с pull-to-refresh
          return RefreshIndicator(
            onRefresh: () async => provider.refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.medicines.length,
              itemBuilder: (context, index) {
                final medicine = provider.medicines[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                      radius: 24,
                      child: Icon(
                        Icons.medication,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      medicine.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (medicine.dosage != null && medicine.dosage!.isNotEmpty)
                            Text(
                              medicine.dosage!,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  medicine.schedule.join(', '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                    onTap: () {
                      // TODO: Переход на детальный экран / настройку напоминаний
                    },
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
            MaterialPageRoute(
              builder: (context) => const AddMedicineScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }

  // 🔹 Диалог подтверждения удаления
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