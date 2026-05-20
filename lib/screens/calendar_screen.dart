import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../services/hive_service.dart';
import '../models/cycle_settings.dart';
import '../providers/medicine_provider.dart';
import '../providers/side_effect_provider.dart';
import '../models/medicine.dart';
import '../models/side_effect.dart';
import '../models/cycle_settings.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {

  final List<Map<String, dynamic>> _moods = [
    {'score': 1, 'icon': '😫', 'label': 'Ужасно'},
    {'score': 2, 'icon': '😟', 'label': 'Плохо'},
    {'score': 3, 'icon': '😐', 'label': 'Нормально'},
    {'score': 4, 'icon': '🙂', 'label': 'Хорошо'},
    {'score': 5, 'icon': '🤩', 'label': 'Отлично'},
  ];
  late final ValueNotifier<List<Todo>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  CycleSettings? _settings;

  _CalendarScreenState() {
    _selectedEvents = ValueNotifier([]);
  }
    void _showMoodDialog(DateTime date) {
    // Получаем текущее настроение за этот день (если есть)
    final hiveService = HiveService();
    // Нам нужно найти запись. Для простоты используем метод из сервиса
    // Но так как сервис не имеет геттера для поиска по дате в текущей реализации,
    // давайте просто переберем значения (или добавь геттер в сервис, как я писал выше).
    
    int? currentMood;
    try {
       final day = hiveService.getCycleDayByDate(date);
       if (day != null && day.id.isNotEmpty) {
         currentMood = day.moodScore;
       }
    } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Как вы себя чувствуете'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _moods.map((m) {
                final isSelected = currentMood == m['score'];
                return GestureDetector(
                  onTap: () async {
                    await hiveService.updateMood(date, m['score']);
                    Navigator.pop(ctx);
                    setState(() {}); // Обновить календарь (перерисовать маркер)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Настроение сохранено: ${m['label']}'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.pink[100] : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? Colors.pink : Colors.grey, width: 2),
                        ),
                        child: Text(m['icon'], style: TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(height: 4),
                      Text(m['label'], style: TextStyle(fontSize: 10, color: isSelected ? Colors.pink : Colors.grey)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          if (currentMood != null)
            TextButton(
              onPressed: () async {
                await hiveService.updateMood(date, 0); // 0 или null означает сброс
                Navigator.pop(ctx);
                setState(() {});
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Удалить'),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // Создаем экземпляр сервиса напрямую, без Provider
    final hiveService = HiveService(); 
    
    setState(() {
      _settings = hiveService.getCycleSettings();
      
      // Если настроек нет, берем дефолт
      if (_settings == null) {
        _settings = CycleSettings(
          lastPeriodStart: DateTime.now().subtract(const Duration(days: 10)),
          cycleLength: 28,
          periodLength: 5,
        );
      }
    });
    _updateSelectedEvents();
  }

  void _updateSelectedEvents() {
    if (_selectedDay != null) {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой цикл'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
            tooltip: 'Настройки цикла',
          ),
        ],
      ),
      body: Column(
        children: [
          // 📅 КАЛЕНДАРЬ С РАСКРАСКОЙ
          TableCalendar<Todo>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            
            // 🔥 ИСПРАВЛЕНИЕ: Используем calendarBuilders вместо cellDecoration
            calendarBuilders: CalendarBuilders(
              // 1. Раскраска дней (менструация/овуляция)
              defaultBuilder: (context, date, _) {
                final phase = _settings!.getPhaseFor(date);
                final dayNum = _settings!.getCycleDayFor(date);
                
                Color? bgColor;
                Color textColor = Colors.black;

                if (phase == 'menstruation') {
                  bgColor = Colors.red[100];
                  textColor = const Color.fromARGB(255, 213, 19, 19);
                } else if (phase == 'ovulation' && dayNum >= 13 && dayNum <= 15) {
                  bgColor = Colors.green[100];
                  textColor = const Color.fromARGB(255, 41, 180, 50);
                }

                if (isSameDay(_selectedDay, date) || isSameDay(DateTime.now(), date)) {
                  return null;
                }

                if (bgColor != null) {
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return null;
              },
              
              // 2. 🔥 ИСПРАВЛЕННЫЙ МАРКЕР: Теперь показывает и события, и НАСТРОЕНИЕ
              markerBuilder: (context, date, events) {
                // --- ЧАСТЬ А: Получаем настроение ---
                int? moodScore;
                try {
                   final hiveService = HiveService();
                   final day = hiveService.getCycleDayByDate(date);
                   if (day != null && day.id.isNotEmpty) {
                     moodScore = day.moodScore;
                   }
                } catch (_) {}

                // --- ЧАСТЬ Б: Формируем список виджетов ---
                List<Widget> markers = [];

                // Если есть настроение - добавляем смайлик
                if (moodScore != null && moodScore > 0) {
                  final moodData = _moods.firstWhere(
                    (m) => m['score'] == moodScore,
                    orElse: () => {'icon': '😐'}, 
                  );
                  markers.add(Text(moodData['icon'], style: const TextStyle(fontSize: 18)));
                } 
                // Если настроения нет, но есть события (лекарства/симптомы) - рисуем точки
                else if (events.isNotEmpty) {
                  markers.addAll(events.take(3).map((e) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: e.isMedicine ? Colors.blue : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList());
                }

                if (markers.isEmpty) return const SizedBox.shrink();
                
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: markers,
                  ),
                );
              },
            ),
            
            // Стандартные стили для сегодня и выбранного дня
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: const Color(0xFFE8A4B8),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(color: Colors.white),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(color: Colors.white),
              markersMaxCount: 3,
              outsideDaysVisible: false,
            ),

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _updateSelectedEvents();
              
              // Показываем диалог выбора настроения
              _showMoodDialog(selectedDay);
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          
          const SizedBox(height: 10),

          // 🎛️ КНОПКИ УПРАВЛЕНИЯ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markPeriodStart(_selectedDay ?? DateTime.now()),
                    icon: const Icon(Icons.water_drop, color: Colors.white),
                    label: const Text('Начало цикла', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSettingsDialog(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Настройки'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),
          
          // 📊 ИНФО О ВЫБРАННОМ ДНЕ
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.pink[200]!),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  'День цикла', 
                  _selectedDay != null ? '${_settings!.getCycleDayFor(_selectedDay!)}-й' : '-', 
                  Icons.calendar_today
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  'Фаза', 
                  _getPhaseName(_selectedDay != null ? _settings!.getPhaseFor(_selectedDay!) : ''), 
                  Icons.self_improvement
                ),
                if (_selectedDay != null && _settings!.getPhaseFor(_selectedDay!) == 'menstruation')
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text('⚠️ Сегодня день менструации', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          const Divider(height: 30),
          
          // 📝 СОБЫТИЯ ДНЯ (Лекарства и Симптомы)
          Expanded(
            child: ValueListenableBuilder<List<Todo>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty && _selectedDay == null) {
                   return const Center(child: Text('Выберите день в календаре'));
                }
                if (value.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text('Нет записей на этот день', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          event.isMedicine ? Icons.medication : Icons.note_alt,
                          color: event.isMedicine ? Colors.blue : Colors.orange,
                        ),
                        title: Text(event.title),
                        subtitle: Text(event.description),
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [Icon(icon, size: 18, color: Colors.pink[400]), const SizedBox(width: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w500))]),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  String _getPhaseName(String phase) {
    switch (phase) {
      case 'menstruation': return '🩸 Менструация';
      case 'ovulation': return '🥚 Овуляция';
      case 'follicular': return '🌱 Фолликулярная';
      case 'luteal': return '🍂 Лютеиновая';
      default: return 'Неизвестно';
    }
  }

  // 🔥 ОТМЕТИТЬ НАЧАЛО ЦИКЛА
  void _markPeriodStart(DateTime date) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Начало цикла?'),
        content: Text('Установить ${date.day}.${date.month}.${date.year} как первый день менструации?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              // 🔥 FIX: Создаем дату строго с полуночи
              final normalizedDate = DateTime(date.year, date.month, date.day);

              final newSettings = CycleSettings(
                lastPeriodStart: normalizedDate, // Сохраняем очищенную дату
                cycleLength: _settings!.cycleLength,
                periodLength: _settings!.periodLength,
              );
              
              final hiveService = HiveService(); // Или через провайдер, если уже починил
              hiveService.saveCycleSettings(newSettings);
              
              setState(() => _settings = newSettings);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Цикл обновлен!'), backgroundColor: Colors.green));
              _updateSelectedEvents();
            },
            child: const Text('Да'),
          ),
        ],
      ),
    );
  }

  // ⚙️ НАСТРОЙКИ ДЛИНЫ ЦИКЛА
  void _showSettingsDialog(BuildContext context) {
    final cycleCtrl = TextEditingController(text: _settings!.cycleLength.toString());
    final periodCtrl = TextEditingController(text: _settings!.periodLength.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Настройки цикла'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cycleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Длина цикла (дни)', hintText: '28')),
            TextField(controller: periodCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Длительность месячных (дни)', hintText: '5')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final cLen = int.tryParse(cycleCtrl.text) ?? 28;
              final pLen = int.tryParse(periodCtrl.text) ?? 5;
              
              final newSettings = CycleSettings(
                lastPeriodStart: _settings!.lastPeriodStart,
                cycleLength: cLen,
                periodLength: pLen,
              );
              
              // Прямой экземпляр
              final hiveService = HiveService();
              hiveService.saveCycleSettings(newSettings);
              
              setState(() => _settings = newSettings);
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  List<Todo> _getEventsForDay(DateTime day) {
    final medProvider = Provider.of<MedicineProvider>(context, listen: false);
    final sideProvider = Provider.of<SideEffectProvider>(context, listen: false);
    final events = <Todo>[];

    // Лекарства
    for (var med in medProvider.medicines) {
      if (med.daysOfWeek.contains(day.weekday)) {
        final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        events.add(Todo(title: med.name, description: med.dosage ?? '', isMedicine: true, isTaken: med.takenDates.contains(dateStr), severity: null));
      }
    }

    // Симптомы
    for (var effect in sideProvider.sideEffects) {
      if (effect.timestamp.year == day.year && effect.timestamp.month == day.month && effect.timestamp.day == day.day) {
        events.add(Todo(title: 'Симптом', description: effect.description, isMedicine: false, isTaken: null, severity: effect.severity));
      }
    }
    return events;
  }
}

class Todo {
  final String title;
  final String description;
  final bool isMedicine;
  final bool? isTaken;
  final int? severity;
  Todo({required this.title, required this.description, required this.isMedicine, required this.isTaken, required this.severity});
}