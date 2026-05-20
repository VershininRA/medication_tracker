import 'package:flutter/material.dart';
import '../providers/medicine_provider.dart';
import 'home_screen.dart'; 
import 'calendar_screen.dart';
import 'side_effects_screen.dart';
import 'profile_screen.dart';
import '../models/user_profile.dart';
import '../services/hive_service.dart';
import 'package:provider/provider.dart';
import 'analytics_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _selectedIndex = 0;

  // Экраны определяем теперь внутри build, чтобы иметь доступ к setState
  // Но сами виджеты (HomeScreen, ProfileScreen) можно оставить константами там, где это возможно
  
  @override
  Widget build(BuildContext context) {
    // Формируем список экранов здесь, где доступен setState
    final List<Widget> screens = [
      DashboardBody(onProfileTap: () => setState(() => _selectedIndex = 3)),
      const HomeScreen(),               
      const AnalyticsScreen(),
      const ProfileScreen(),            
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFE8A4B8),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication),
            label: 'Лекарства',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Аналитика',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ТЕЛО ГЛАВНОГО ЭКРАНА (DASHBOARD)
// ==========================================
class DashboardBody extends StatelessWidget {
  final VoidCallback onProfileTap;

  const DashboardBody({super.key, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MedicineProvider>(context);
    final allMeds = provider.medicines;
    final hiveService = HiveService();
    final profile = hiveService.getProfile();
    final userName = profile?.name ?? 'Анна';
    
    // Считаем статистику
    final takenCount = allMeds.where((m) => m.isTakenToday()).length;
    final totalCount = allMeds.length;
    final progress = totalCount == 0 ? 0.0 : takenCount / totalCount;

    // Приветствие по времени
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 6) {
      greeting = 'Доброй ночи';
    } else if (hour < 12) {
      greeting = 'Доброе утро';
    } else if (hour < 18) {
      greeting = 'Добрый день';
    } else {
      greeting = 'Добрый вечер';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // 👋 ВЕРХНЯЯ ЧАСТЬ: Приветствие + Кнопки
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $userName!', 
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Принято: $takenCount из $totalCount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildIconButton(Icons.notifications_outlined, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Уведомления настроены в системе')),
                    );
                  }),
                  const SizedBox(width: 10),
                  // 🔥 Теперь эта кнопка реально переключает вкладку
                  _buildIconButton(Icons.person_outline, onProfileTap),
                ],
              ),
            ],
          ),

          const SizedBox(height: 25),

          // 📊 ПРОГРЕСС БАР
          if (totalCount > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8A4B8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ваш прогресс сегодня',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white,
                    color: const Color(0xFFE8A4B8),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${(progress * 100).toInt()}% выполнено',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 30),

          // 🎯 ДВЕ БОЛЬШИЕ КНОПКИ
          const Text(
            'Быстрый доступ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          
          Row(
            children: [
              // Кнопка 1: Схема приема
              Expanded(
                child: _buildLargeMenuCard(
                  context,
                  icon: Icons.list_alt,
                  title: 'Схема\nприема',
                  subtitle: 'Все препараты',
                  color: const Color(0xFFB2EBF2),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                  },
                ),
              ),
              const SizedBox(width: 15),
              
              // Кнопка 2: Мой календарь
              Expanded(
                child: _buildLargeMenuCard(
                  context,
                  icon: Icons.calendar_month,
                  title: 'Мой\nкалендарь',
                  subtitle: 'Цикл и симптомы',
                  color: const Color(0xFFC5E1A5),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CalendarScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Center(
            child: Text(
              'Совет: Отмечайте лекарства вовремя,\nчтобы сохранить прогресс.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 24, color: const Color(0xFFE8A4B8)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildLargeMenuCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: const Color(0xFFE8A4B8)),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}