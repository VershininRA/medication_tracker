import 'package:flutter/material.dart';
import '../models/cycle_settings.dart';

class CyclePhaseCard extends StatelessWidget {
  final CycleSettings settings;
  final DateTime currentDate;

  const CyclePhaseCard({
    Key? key,
    required this.settings,
    required this.currentDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cycleDay = settings.getCycleDayFor(currentDate);
    final phase = settings.getPhaseFor(currentDate);
    final phaseData = _getPhaseData(phase);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            phaseData['color']!.withOpacity(0.2),
            phaseData['color']!.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: phaseData['color']!.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: phaseData['color']!.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Фаза цикла',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    phaseData['name']!,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: phaseData['color'],
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: phaseData['color']!.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  phaseData['emoji']!,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // День цикла
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: phaseData['color']!.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'День цикла',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '$cycleDay / ${settings.cycleLength}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: phaseData['color'],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: cycleDay / settings.cycleLength,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                phaseData['color']!,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Описание фазы
          Text(
            phaseData['description']!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPhaseData(String phase) {
    switch (phase) {
      case 'menstruation':
        return {
          'name': 'Менструация',
          'emoji': '🩸',
          'color': const Color(0xFFEF5350),
          'description':
              'Период менструации. Рекомендуется больше отдыха и водного баланса.',
        };
      case 'follicular':
        return {
          'name': 'Фолликулярная',
          'emoji': '🌱',
          'color': const Color(0xFF66BB6A),
          'description':
              'Подъем энергии. Хорошее время для новых проектов и физической активности.',
        };
      case 'ovulation':
        return {
          'name': 'Овуляция',
          'emoji': '✨',
          'color': const Color(0xFFFFC107),
          'description':
              'Пик энергии и социальности. Оптимальное время для встреч и новых знакомств.',
        };
      case 'luteal':
        return {
          'name': 'Лютеиновая',
          'emoji': '🌙',
          'color': const Color(0xFF5C6BC0),
          'description':
              'Период интроспекции. Время для планирования и глубокой работы.',
        };
      default:
        return {
          'name': 'Неизвестно',
          'emoji': '❓',
          'color': Colors.grey,
          'description': 'Информация о фазе недоступна.',
        };
    }
  }
}
