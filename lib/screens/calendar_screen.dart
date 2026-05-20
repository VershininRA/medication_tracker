import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/cycle_settings.dart';
import '../providers/medicine_provider.dart';
import '../providers/side_effect_provider.dart';
import '../services/hive_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ValueNotifier<List<CalendarEvent>> _selectedEvents =
      ValueNotifier<List<CalendarEvent>>([]);
  final HiveService _hiveService = HiveService();

  final List<Map<String, dynamic>> _moods = const [
    {'score': 1, 'icon': '😫', 'label': 'Плохо'},
    {'score': 2, 'icon': '😟', 'label': 'Тяжело'},
    {'score': 3, 'icon': '😐', 'label': 'Нормально'},
    {'score': 4, 'icon': '🙂', 'label': 'Хорошо'},
    {'score': 5, 'icon': '🤩', 'label': 'Отлично'},
  ];

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late CycleSettings _settings;
  bool _eventsLoaded = false;

  @override
  void initState() {
    super.initState();
    _settings = _hiveService.getCycleSettings() ??
        CycleSettings(
          lastPeriodStart: DateTime.now().subtract(const Duration(days: 14)),
          cycleLength: 28,
          periodLength: 5,
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_eventsLoaded) {
      _selectedEvents.value = _getEventsForDay(_selectedDay);
      _eventsLoaded = true;
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPhase = _settings.getPhaseFor(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь цикла'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Настройки цикла',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Месяц',
              CalendarFormat.twoWeeks: '2 недели',
              CalendarFormat.week: 'Неделя',
            },
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              outsideDaysVisible: false,
              todayDecoration: const BoxDecoration(
                color: Color(0xFFE8A4B8),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders<CalendarEvent>(
              defaultBuilder: (context, date, _) => _buildPhaseDay(date),
              markerBuilder: _buildMarkers,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents.value = _getEventsForDay(selectedDay);
              });
              _showMoodDialog(selectedDay);
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() => _calendarFormat = format);
              }
            },
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markPeriodStart(_selectedDay),
                    icon: const Icon(Icons.water_drop_outlined),
                    label: const Text('Начало цикла'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showSettingsDialog,
                    icon: const Icon(Icons.tune),
                    label: const Text('Параметры'),
                  ),
                ),
              ],
            ),
          ),
          _DaySummary(
            dayNumber: _settings.getCycleDayFor(_selectedDay),
            phaseName: _phaseName(selectedPhase),
            phaseColor: _phaseColor(selectedPhase),
          ),
          const Divider(height: 24),
          Expanded(
            child: ValueListenableBuilder<List<CalendarEvent>>(
              valueListenable: _selectedEvents,
              builder: (context, events, _) {
                if (events.isEmpty) {
                  return Center(
                    child: Text(
                      'На выбранный день записей нет',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return ListTile(
                      tileColor: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        event.isMedicine
                            ? Icons.medication_outlined
                            : Icons.note_alt_outlined,
                        color: event.isMedicine ? Colors.blue : Colors.orange,
                      ),
                      title: Text(event.title),
                      subtitle: Text(event.description),
                      trailing: event.isTaken == null
                          ? null
                          : Icon(
                              event.isTaken!
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: event.isTaken!
                                  ? Colors.green
                                  : Colors.grey.shade400,
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildPhaseDay(DateTime date) {
    if (isSameDay(date, DateTime.now()) || isSameDay(date, _selectedDay)) {
      return null;
    }

    final phase = _settings.getPhaseFor(date);
    final color = _phaseColor(phase);
    if (color == null) return null;

    return Container(
      margin: const EdgeInsets.all(6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        shape: BoxShape.circle,
      ),
      child: Text(
        '${date.day}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildMarkers(
    BuildContext context,
    DateTime date,
    List<CalendarEvent> events,
  ) {
    final day = _hiveService.getCycleDayByDate(date);
    final moodScore = day?.moodScore;
    final mood = moodScore == null || moodScore <= 0
        ? null
        : _moods.firstWhere(
            (item) => item['score'] == moodScore,
            orElse: () => _moods[2],
          );

    if (mood != null) {
      return Positioned(
        bottom: 0,
        child: Text(mood['icon'], style: const TextStyle(fontSize: 14)),
      );
    }

    if (events.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: events.take(3).map((event) {
          return Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: event.isMedicine ? Colors.blue : Colors.orange,
              shape: BoxShape.circle,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMoodDialog(DateTime date) {
    final currentMood = _hiveService.getCycleDayByDate(date)?.moodScore;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Самочувствие за день'),
          content: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: _moods.map((mood) {
              final isSelected = currentMood == mood['score'];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  await _hiveService.updateMood(date, mood['score']);
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  setState(() {});
                },
                child: Container(
                  width: 76,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE8A4B8).withOpacity(0.2)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE8A4B8)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mood['icon'], style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        mood['label'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            if (currentMood != null && currentMood > 0)
              TextButton(
                onPressed: () async {
                  await _hiveService.updateMood(date, 0);
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  setState(() {});
                },
                child: const Text('Сбросить'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  void _markPeriodStart(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Обновить цикл?'),
        content: Text(
          'Установить ${normalizedDate.day}.${normalizedDate.month}.${normalizedDate.year} как первый день цикла?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newSettings = CycleSettings(
                lastPeriodStart: normalizedDate,
                cycleLength: _settings.cycleLength,
                periodLength: _settings.periodLength,
              );
              await _hiveService.saveCycleSettings(newSettings);
              if (!mounted) return;
              setState(() => _settings = newSettings);
              Navigator.pop(dialogContext);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    final cycleController =
        TextEditingController(text: _settings.cycleLength.toString());
    final periodController =
        TextEditingController(text: _settings.periodLength.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Настройки цикла'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cycleController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Длина цикла, дни'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: periodController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Длительность месячных'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cycleLength =
                  (int.tryParse(cycleController.text) ?? 28).clamp(21, 45);
              final periodLength =
                  (int.tryParse(periodController.text) ?? 5).clamp(2, 10);
              final newSettings = CycleSettings(
                lastPeriodStart: _settings.lastPeriodStart,
                cycleLength: cycleLength,
                periodLength: periodLength,
              );
              await _hiveService.saveCycleSettings(newSettings);
              if (!mounted) return;
              setState(() => _settings = newSettings);
              Navigator.pop(dialogContext);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    ).whenComplete(() {
      cycleController.dispose();
      periodController.dispose();
    });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final medProvider = Provider.of<MedicineProvider>(context, listen: false);
    final sideProvider = Provider.of<SideEffectProvider>(context, listen: false);
    final events = <CalendarEvent>[];
    final dateKey = _dateKey(day);

    for (final medicine in medProvider.medicines) {
      if (medicine.daysOfWeek.contains(day.weekday)) {
        events.add(
          CalendarEvent(
            title: medicine.name,
            description: medicine.dosage?.isNotEmpty == true
                ? medicine.dosage!
                : 'По расписанию: ${medicine.schedule.join(', ')}',
            isMedicine: true,
            isTaken: medicine.takenDates.contains(dateKey),
          ),
        );
      }
    }

    for (final effect in sideProvider.sideEffects) {
      if (_isSameDate(effect.timestamp, day)) {
        events.add(
          CalendarEvent(
            title: 'Симптом',
            description: '${effect.description} · тяжесть ${effect.severity}/3',
            isMedicine: false,
          ),
        );
      }
    }

    return events;
  }

  Color? _phaseColor(String phase) {
    switch (phase) {
      case 'menstruation':
        return Colors.red.shade600;
      case 'ovulation':
        return Colors.green.shade700;
      case 'follicular':
        return Colors.teal.shade600;
      case 'luteal':
        return Colors.deepPurple.shade400;
      default:
        return null;
    }
  }

  String _phaseName(String phase) {
    switch (phase) {
      case 'menstruation':
        return 'Менструация';
      case 'ovulation':
        return 'Овуляция';
      case 'follicular':
        return 'Фолликулярная фаза';
      case 'luteal':
        return 'Лютеиновая фаза';
      default:
        return 'Неизвестно';
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({
    required this.dayNumber,
    required this.phaseName,
    required this.phaseColor,
  });

  final int dayNumber;
  final String phaseName;
  final Color? phaseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (phaseColor ?? const Color(0xFFE8A4B8)).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (phaseColor ?? const Color(0xFFE8A4B8)).withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            color: phaseColor ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'День цикла: ${dayNumber == 0 ? '-' : dayNumber}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            phaseName,
            style: TextStyle(
              color: phaseColor ?? Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.description,
    required this.isMedicine,
    this.isTaken,
  });

  final String title;
  final String description;
  final bool isMedicine;
  final bool? isTaken;
}
