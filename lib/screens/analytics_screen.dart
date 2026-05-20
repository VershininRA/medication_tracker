import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/medicine.dart';
import '../services/hive_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final HiveService _hiveService = HiveService();
  final DateFormat _shortDateFormat = DateFormat('dd.MM');
  final DateFormat _fullDateFormat = DateFormat('dd.MM.yyyy');

  DateTime _startDate = _dateOnly(
    DateTime.now().subtract(const Duration(days: 6)),
  );
  DateTime _endDate = _dateOnly(DateTime.now());

  List<FlSpot> _moodSpots = [];
  double _adherenceRate = 0;
  int _healthScore = 0;
  int _totalMedsTaken = 0;
  int _totalMedsExpected = 0;

  @override
  void initState() {
    super.initState();
    _calculateData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Выбрать период',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Экспорт в PDF',
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _calculateData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Text(
                'Период: ${_shortDateFormat.format(_startDate)} - ${_shortDateFormat.format(_endDate)}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _HealthScoreCard(
              score: _healthScore,
              comment: _healthComment(_healthScore),
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Динамика самочувствия',
              icon: Icons.show_chart,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: _moodSpots.isEmpty
                  ? const _EmptyAnalyticsState(
                      message: 'За выбранный период нет оценок самочувствия',
                    )
                  : LineChart(_moodChartData()),
            ),
            const SizedBox(height: 28),
            _SectionTitle(
              title: 'Прием лекарств',
              icon: Icons.medication_outlined,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 34,
                        sections: _adherenceSections(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendItem(
                          color: Colors.green.shade600,
                          text: 'Принято: $_totalMedsTaken',
                        ),
                        const SizedBox(height: 10),
                        _LegendItem(
                          color: Colors.red.shade100,
                          text:
                              'Пропущено: ${_totalMedsExpected - _totalMedsTaken}',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Всего назначений: $_totalMedsExpected',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _calculateData() {
    final medicines = _hiveService.getActiveMedicines();
    final spots = <FlSpot>[];
    var takenCount = 0;
    var expectedCount = 0;
    var dayIndex = 0;

    for (final day in _daysInRange()) {
      final dayRecord = _hiveService.getCycleDayByDate(day);
      final moodScore = dayRecord?.moodScore;
      if (moodScore != null && moodScore > 0) {
        spots.add(FlSpot(dayIndex.toDouble(), moodScore.toDouble()));
      }

      for (final medicine in medicines) {
        if (medicine.daysOfWeek.contains(day.weekday)) {
          expectedCount++;
          if (medicine.takenDates.contains(_dateKey(day))) {
            takenCount++;
          }
        }
      }

      dayIndex++;
    }

    final adherenceRate =
        expectedCount == 0 ? 0.0 : (takenCount / expectedCount) * 100;
    final avgMood = spots.isEmpty
        ? 3.0
        : spots.map((spot) => spot.y).reduce((a, b) => a + b) / spots.length;
    final moodScoreNormalized = (avgMood / 5) * 100;
    final healthScore =
        ((adherenceRate * 0.6) + (moodScoreNormalized * 0.4))
            .round()
            .clamp(0, 100);

    setState(() {
      _moodSpots = spots;
      _totalMedsTaken = takenCount;
      _totalMedsExpected = expectedCount;
      _adherenceRate = adherenceRate;
      _healthScore = healthScore;
    });
  }

  LineChartData _moodChartData() {
    final totalDays = _endDate.difference(_startDate).inDays + 1;

    return LineChartData(
      minX: 0,
      maxX: (totalDays - 1).toDouble(),
      minY: 1,
      maxY: 5,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (_) => FlLine(
          color: Colors.grey.shade200,
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 28,
            getTitlesWidget: (value, _) => Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, _) {
              final index = value.toInt();
              if (index < 0 || index >= totalDays) {
                return const SizedBox.shrink();
              }
              if (index % 2 != 0 && index != totalDays - 1) {
                return const SizedBox.shrink();
              }
              final date = _startDate.add(Duration(days: index));
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _shortDateFormat.format(date),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: _moodSpots,
          isCurved: true,
          color: const Color(0xFFE8A4B8),
          barWidth: 4,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFFE8A4B8).withOpacity(0.18),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _adherenceSections() {
    if (_totalMedsExpected == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: '0%',
          color: Colors.grey.shade200,
          radius: 62,
          titleStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ];
    }

    return [
      PieChartSectionData(
        value: _adherenceRate,
        title: '${_adherenceRate.round()}%',
        color: Colors.green.shade600,
        radius: 62,
        titleStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: (100 - _adherenceRate).clamp(0, 100).toDouble(),
        title: '',
        color: Colors.red.shade100,
        radius: 62,
      ),
    ];
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFFE8A4B8),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _startDate = _dateOnly(picked.start);
      _endDate = _dateOnly(picked.end);
    });
    _calculateData();
  }

  Future<void> _generatePdf() async {
    final pdfBytes = await _buildPdf();
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }

  Future<Uint8List> _buildPdf() async {
    final regularFontData =
        await rootBundle.load('assets/fonts/roboto-regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/roboto-bold.ttf');
    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);
    final medicines = _hiveService.getActiveMedicines();
    final sideEffects = _hiveService
        .getAllSideEffects()
        .where((effect) => _isWithinDateRange(effect.timestamp))
        .toList();
    final cycleDays = _hiveService
        .getAllCycleDays()
        .where((day) => _isWithinDateRange(day.date))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Text(
              'Отчет по терапии',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.pink700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Период: ${_fullDateFormat.format(_startDate)} - ${_fullDateFormat.format(_endDate)}',
            ),
            pw.Divider(),
            pw.SizedBox(height: 12),
            pw.Text(
              'Индекс здоровья: $_healthScore / 100',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(_healthComment(_healthScore)),
            pw.SizedBox(height: 16),
            pw.Text(
              'Прием лекарств',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Принято: $_totalMedsTaken из $_totalMedsExpected назначений (${_adherenceRate.round()}%)',
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: const {
                0: pw.FixedColumnWidth(72),
                1: pw.FlexColumnWidth(),
                2: pw.FixedColumnWidth(96),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('Дата', bold: true),
                    _pdfCell('Препарат', bold: true),
                    _pdfCell('Статус', bold: true),
                  ],
                ),
                ..._medicineRows(medicines),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              'Самочувствие и симптомы',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            if (cycleDays.isEmpty && sideEffects.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text('Записей за период нет.'),
              )
            else ...[
              ...cycleDays.map(
                (day) => pw.Text(
                  '${_fullDateFormat.format(day.date)}: самочувствие ${_moodText(day.moodScore)}; симптомы: ${day.symptoms.isEmpty ? 'нет' : day.symptoms.join(', ')}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              if (sideEffects.isNotEmpty) pw.SizedBox(height: 10),
              ...sideEffects.map(
                (effect) => pw.Text(
                  '${_fullDateFormat.format(effect.timestamp)}: ${effect.description} (тяжесть ${effect.severity}/3)',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ];
        },
      ),
    );

    return document.save();
  }

  List<pw.TableRow> _medicineRows(List<Medicine> medicines) {
    final rows = <pw.TableRow>[];

    for (final day in _daysInRange()) {
      var hasMedicine = false;

      for (final medicine in medicines) {
        if (!medicine.daysOfWeek.contains(day.weekday)) continue;

        hasMedicine = true;
        final taken = medicine.takenDates.contains(_dateKey(day));
        rows.add(
          pw.TableRow(
            children: [
              _pdfCell(_fullDateFormat.format(day)),
              _pdfCell(medicine.name),
              _pdfCell(taken ? 'Принято' : 'Пропущено'),
            ],
          ),
        );
      }

      if (!hasMedicine) {
        rows.add(
          pw.TableRow(
            children: [
              _pdfCell(_fullDateFormat.format(day)),
              _pdfCell('Нет назначений'),
              _pdfCell('-'),
            ],
          ),
        );
      }
    }

    return rows;
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Iterable<DateTime> _daysInRange() sync* {
    for (var day = _startDate;
        !day.isAfter(_endDate);
        day = day.add(const Duration(days: 1))) {
      yield day;
    }
  }

  bool _isWithinDateRange(DateTime date) {
    final normalized = _dateOnly(date);
    return !normalized.isBefore(_startDate) && !normalized.isAfter(_endDate);
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _healthComment(int score) {
    if (score >= 90) return 'Отличная динамика';
    if (score >= 70) return 'Хорошая стабильность';
    if (score >= 50) return 'Есть зоны внимания';
    return 'Нужно усилить контроль терапии';
  }

  String _moodText(int? score) {
    switch (score) {
      case 1:
        return '1/5, плохо';
      case 2:
        return '2/5, тяжело';
      case 3:
        return '3/5, нормально';
      case 4:
        return '4/5, хорошо';
      case 5:
        return '5/5, отлично';
      default:
        return 'не указано';
    }
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({
    required this.score,
    required this.comment,
  });

  final int score;
  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFE8A4B8), Colors.teal.shade300],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8A4B8).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Индекс здоровья',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '$score / 100',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(comment, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.text,
  });

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _EmptyAnalyticsState extends StatelessWidget {
  const _EmptyAnalyticsState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }
}
