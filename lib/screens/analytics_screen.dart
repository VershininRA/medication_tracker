import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../services/hive_service.dart';
import '../models/cycle_day.dart';
import '../models/medicine.dart';
import '../models/side_effect.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final HiveService _hiveService = HiveService();
  
  List<FlSpot> _moodSpots = [];
  double _adherenceRate = 0.0;
  int _healthScore = 0;
  int _totalMedsTaken = 0;
  int _totalMedsExpected = 0;
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _calculateData();
  }

  void _calculateData() {
    setState(() {
      _moodSpots = [];
      _adherenceRate = 0.0;
      _healthScore = 0;
      _totalMedsTaken = 0;
      _totalMedsExpected = 0;
    });

    // 1. Настроение
    List<FlSpot> spots = [];
    int dayIndex = 0;
    
    for (var d = _startDate; d.isBefore(_endDate.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
      final dayRecord = _hiveService.getCycleDayByDate(d);
      if (dayRecord != null && dayRecord.moodScore != null) {
        spots.add(FlSpot(dayIndex.toDouble(), dayRecord.moodScore!.toDouble()));
      }
      dayIndex++;
    }
    
    // 2. Приверженность
    final meds = _hiveService.getActiveMedicines();
    int takenCount = 0;
    int expectedCount = 0;

    for (var d = _startDate; d.isBefore(_endDate.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
      final weekDay = d.weekday;
      final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      
      for (var med in meds) {
        if (med.daysOfWeek.contains(weekDay)) {
          expectedCount++;
          if (med.takenDates.contains(dateStr)) {
            takenCount++;
          }
        }
      }
    }

    setState(() {
      _moodSpots = spots;
      _totalMedsTaken = takenCount;
      _totalMedsExpected = expectedCount;
      _adherenceRate = expectedCount == 0 ? 0 : (takenCount / expectedCount) * 100;
      
      double avgMood = spots.isEmpty ? 3 : spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;
      double moodScoreNormalized = (avgMood / 5) * 100;
      _healthScore = ((_adherenceRate * 0.6) + (moodScoreNormalized * 0.4)).round();
      if (_healthScore > 100) _healthScore = 100;
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFE8A4B8), // Ваш розовый цвет
            ),
          ),
          child: child!, // Явно указываем имя аргумента
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _calculateData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range), // ИСПРАВЛЕНО: было calendar_range
            tooltip: 'Выбрать период',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Экспорт в PDF',
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Период: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 15),

            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFFE8A4B8), Colors.pink.shade200]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    const Text('Индекс здоровья', style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(
                      '$_healthScore / 100',
                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _getHealthComment(_healthScore),
                      style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 25),

            const Text('Динамика настроения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: _moodSpots.isEmpty 
                ? Center(child: Text('Нет данных о настроении за этот период', style: TextStyle(color: Colors.grey[500]), textAlign: TextAlign.center))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              if (val.toInt() % 2 == 0 || val.toInt() == _moodSpots.length - 1) {
                                final date = _startDate.add(Duration(days: val.toInt()));
                                return Padding(padding: const EdgeInsets.only(top: 8), child: Text('${date.day}.${date.month}', style: const TextStyle(fontSize: 10)));
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _moodSpots,
                          isCurved: true,
                          color: const Color(0xFFE8A4B8),
                          barWidth: 4,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: const Color(0xFFE8A4B8).withOpacity(0.2)),
                        ),
                      ],
                    ),
                  ),
            ),

            const SizedBox(height: 25),

            const Text('Прием лекарств', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: _adherenceRate > 0 ? _adherenceRate : 0.1,
                            title: '${_adherenceRate.toInt()}%',
                            color: Colors.green,
                            radius: 60,
                            titleStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: (100 - _adherenceRate) > 0 ? (100 - _adherenceRate) : 0.1,
                            title: '',
                            color: Colors.red.shade100,
                            radius: 60,
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(Colors.green, 'Принято ($_totalMedsTaken)'),
                        const SizedBox(height: 8),
                        _buildLegendItem(Colors.red.shade100, 'Пропущено (${_totalMedsExpected - _totalMedsTaken})'),
                        const SizedBox(height: 8),
                        Text('Всего назначено: $_totalMedsExpected', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  String _getHealthComment(int score) {
    if (score >= 90) return '🌟 Отличное состояние!';
    if (score >= 70) return '🙂 Хорошая динамика';
    if (score >= 50) return '😐 Требует внимания';
    return '⚠️ Нужно скорректировать терапию';
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy');
    final meds = _hiveService.getActiveMedicines();
    final allDays = _hiveService.getAllCycleDays();
    final allSideEffects = _hiveService.getAllSideEffects();

    final filteredDays = allDays.where((d) => 
      !d.date.isBefore(_startDate) && !d.date.isAfter(_endDate)
    ).toList();
    
    final filteredSideEffects = allSideEffects.where((s) => 
      !s.timestamp.isBefore(_startDate) && !s.timestamp.isAfter(_endDate)
    ).toList();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Отчет о здоровье', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.pink700)),
              pw.SizedBox(height: 10),
              pw.Text('Период: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}', style: const pw.TextStyle(fontSize: 12)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Индекс здоровья:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('$_healthScore / 100', style: pw.TextStyle(fontSize: 16, color: PdfColors.pink700, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Text(_getHealthComment(_healthScore), style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
              
              pw.SizedBox(height: 20),
              pw.Text('Статистика приема лекарств', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('Принято: $_totalMedsTaken из $_totalMedsExpected назначений (${_adherenceRate.toInt()}%)',style: const pw.TextStyle(fontSize: 12)),
              
              pw.SizedBox(height: 15),
              pw.Text('Детальный журнал приема:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(children: [
                    _pdfCell('Дата', bold: true),
                    _pdfCell('Препарат', bold: true),
                    _pdfCell('Статус', bold: true),
                  ]),
                  ..._buildPdfTableRows(meds, filteredDays),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Text('Дневник симптомов и настроения', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              
              if (filteredDays.isEmpty) 
                pw.Text('Записей нет', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey))
              else
                pw.Column(
                  children: filteredDays.map((day) {
                    final moodIcon = day.moodScore != null ? _getMoodEmoji(day.moodScore!) : '';
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text('${dateFormat.format(day.date)} | Настроение: $moodIcon ${day.moodScore ?? "-"} | Симптомы: ${day.symptoms.isNotEmpty ? day.symptoms.join(", ") : "нет"}',style: const pw.TextStyle(fontSize: 10)),
                    );
                  }).toList(),
                ),
                
              if (filteredSideEffects.isNotEmpty) ...[
                pw.SizedBox(height: 15),
                pw.Text('Побочные эффекты:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Column(
                  children: filteredSideEffects.map((e) {
                     return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text('- ${dateFormat.format(e.timestamp)}: ${e.description} (Тяжесть: ${e.severity})',style: const pw.TextStyle(fontSize: 10)),
                    );
                  }).toList(),
                ),
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // ИСПРАВЛЕНО: Возвращаем pw.Padding, а не TableCell
  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text, 
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, 
          fontSize: 10
        ),
      ),
    );
  }

  List<pw.TableRow> _buildPdfTableRows(List<Medicine> meds, List<CycleDay> days) {
    List<pw.TableRow> rows = [];
    for (var d = _startDate; d.isBefore(_endDate.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
      final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final dayRecord = days.firstWhere(
        (day) => day.date.year == d.year && day.date.month == d.month && day.date.day == d.day, 
        orElse: () => CycleDay(id:'', date:d, cycleDayNumber:0, symptoms:[], createdAt: DateTime.now())
      );
      
      bool hasEntry = false;
      for (var med in meds) {
        if (med.daysOfWeek.contains(d.weekday)) {
          hasEntry = true;
          final isTaken = med.takenDates.contains(dateStr);
          rows.add(pw.TableRow(children: [
            _pdfCell(dateStr.split('-').reversed.join('.')),
            _pdfCell(med.name),
            _pdfCell(isTaken ? '✅ Принято' : '❌ Пропущено'),
          ]));
        }
      }
      if (!hasEntry) {
         rows.add(pw.TableRow(children: [
            _pdfCell(dateStr.split('-').reversed.join('.')),
            _pdfCell('Нет назначений', bold: false),
            _pdfCell('-'),
          ]));
      }
    }
    return rows;
  }

  String _getMoodEmoji(int score) {
    switch(score) {
      case 1: return '😫';
      case 2: return '😟';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '🤩';
      default: return '';
    }
  }
}