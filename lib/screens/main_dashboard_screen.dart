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
import '../models/cycle_settings.dart';
import '../widgets/cycle_phase_card.dart';
import '../widgets/statistic_card.dart';

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
      DashboardBody(onProfileTap: () => setState(() => _selectedIndex = 4)),
      const HomeScreen(),               
      const AnalyticsScreen(),
      const CalendarScreen(),
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
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Календарь',
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
    final cycleSettings = hiveService.getCycleSettings() ??
        CycleSettings(
          lastPeriodStart: DateTime.now().subtract(const Duration(days: 14)),
          cycleLength: 28,
          periodLength: 5,
        );
    
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
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2428),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8A4B8).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Принято: $takenCount из $totalCount лекарств',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE8A4B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildIconButton(Icons.notifications_outlined, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Уведомления настроены в системе'),
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    );
                  }),
                  const SizedBox(width: 10),
                  _buildIconButton(Icons.person_outline, onProfileTap),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),

          // 📊 ПРОГРЕСС БАР
          if (totalCount > 0)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE8A4B8).withOpacity(0.12),
                    const Color(0xFFF4B4C9).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE8A4B8).withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8A4B8).withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ваш прогресс сегодня',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D2428),
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE8A4B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFE8A4B8),
                      ),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 28),

          // 🔄 ФАЗА ЦИКЛА
          CyclePhaseCard(
            settings: cycleSettings,
            currentDate: DateTime.now(),
          ),

          const SizedBox(height: 28),

          // 📈 СТАТИСТИКА
          const Text(
            'Статистика',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2428),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              StatisticCard(
                title: 'Всего лекарств',
                value: totalCount.toString(),
                subtitle: 'активных',
                color: const Color(0xFFE8A4B8),
                icon: Icons.medication,
              ),
              StatisticCard(
                title: 'Принято сегодня',
                value: takenCount.toString(),
                subtitle: 'из $totalCount',
                color: const Color(0xFF4CAF50),
                icon: Icons.check_circle,
              ),
              StatisticCard(
                title: 'День цикла',
                value: cycleSettings.getCycleDayFor(DateTime.now()).toString(),
                subtitle: 'из ${cycleSettings.cycleLength}',
                color: const Color(0xFF9C27B0),
                icon: Icons.calendar_today,
              ),
              StatisticCard(
                title: 'Приверженность',
                value: '${(progress * 100).toInt()}%',
                subtitle: 'за сегодня',
                color: const Color(0xFFFFC107),
                icon: Icons.trending_up,
              ),
            ],
          ),
          
          const SizedBox(height: 28),

          // 🎯 ДВЕ БОЛЬШИЕ КНОПКИ
          const Text(
            'Быстрый доступ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2428),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          
          Row(
            children: [
              Expanded(
                child: _buildLargeMenuCard(
                  context,
                  icon: Icons.list_alt,
                  title: 'Мои\nлекарства',
                  subtitle: 'Полный список',
                  color: const Color(0xFF00BCD4),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                  },
                ),
              ),
              const SizedBox(width: 15),
              
              Expanded(
                child: _buildLargeMenuCard(
                  context,
                  icon: Icons.calendar_month,
                  title: 'Календарь\nцикла',
                  subtitle: 'Фазы и симптомы',
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

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildLargeMenuCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Аналитика',
                  subtitle: 'Статистика',
                  color: const Color(0xFFFFCC80),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 15),
              
              Expanded(
                child: _buildLargeMenuCard(
                  context,
                  icon: Icons.note_alt,
                  title: 'Побочные\nэффекты',
                  subtitle: 'Дневник',
                  color: const Color(0xFFEF9A9A),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SideEffectsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          Center(
            child: Text(
              '💡 Отмечайте лекарства вовремя,\nчтобы поддерживать ваше здоровье!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 20),
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
