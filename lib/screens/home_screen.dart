import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import 'add_medicine_screen.dart';
import 'calendar_screen.dart';
import 'side_effects_screen.dart';
import '../widgets/medicine_card_premium.dart';
import '../widgets/confirmation_dialog.dart';

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalendarScreen(),
                ),
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
                
                return MedicineCardPremium(
                  medicine: medicine,
                  isTaken: medicine.isTakenToday(),
                  onTake: () async {
                    await provider.markAsTaken(medicine.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ ${medicine.name} принято!'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMedicineScreen(medicine: medicine),
                      ),
                    );
                  },
                  onDelete: () => _showDeleteDialog(context, medicine),
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
      builder: (context) => ConfirmationDialog(
        title: 'Удалить лекарство?',
        message: 'Вы уверены, что хотите удалить «${medicine.name}»?\n\nЭто действие нельзя отменить.',
        confirmText: 'Удалить',
        cancelText: 'Отмена',
        icon: Icons.warning_rounded,
        confirmColor: Colors.redAccent,
        onConfirm: () {
          Provider.of<MedicineProvider>(context, listen: false)
              .deleteMedicine(medicine.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${medicine.name} удалено'),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
