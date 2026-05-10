import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/colors.dart';

class MedicalParameterChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String parameter; // 'glucose' or 'temperature'
  final String unit;

  const MedicalParameterChart({
    super.key,
    required this.data,
    required this.parameter,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Aucune donnée disponible'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart title
        Row(
          children: [
            Icon(
              parameter == 'glucose' ? Icons.science : Icons.thermostat,
              color: AppColors.medicalBlue,
            ),
            const SizedBox(width: 8),
            Text(
              parameter == 'glucose' ? 'Évolution de la glycémie' : 'Évolution de la température',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Chart
        SizedBox(
          height: 250,
          child: LineChart(
            _buildChartData(),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          children: [
            _buildLegendItem('Normale', AppColors.stableGreen),
            _buildLegendItem('Alerte modérée', AppColors.mediumYellow),
            _buildLegendItem('Surveillance', AppColors.warningOrange),
            _buildLegendItem('Urgence', AppColors.emergencyRed),
          ],
        ),
      ],
    );
  }

  LineChartData _buildChartData() {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final value = data[i]['value'];
      final numericValue = value is double ? value : double.tryParse(value.toString()) ?? 0;
      spots.add(FlSpot(i.toDouble(), numericValue));
    }

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: _buildTitlesData(),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.medicalBlue,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            // ✅ Correction: withOpacity → withValues
            color: AppColors.medicalBlue.withValues(alpha: 0.1),
          ),
        ),
      ],
      minX: 0,
      maxX: spots.length - 1 > 0 ? spots.length - 1 : 1,
      minY: _getMinY(),
      maxY: _getMaxY(),
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              '${value.toInt()}$unit',
              style: const TextStyle(fontSize: 10),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < data.length) {
              final date = data[index]['recordedAt'];
              if (date != null) {
                // ✅ Correction: utiliser Timestamp من cloud_firestore
                final dt = date is Timestamp ? date.toDate() : DateTime.parse(date.toString());
                return Text(
                  '${dt.day}/${dt.month}',
                  style: const TextStyle(fontSize: 10),
                );
              }
            }
            return const Text('');
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  // ✅ بناء خطوط العتبة يدويًا بدون ExtraLinesData
  List<LineChartBarData> _getThresholdLines() {
    if (parameter == 'glucose') {
      return [
        // Critical low line (hypoglycémie sévère)
        LineChartBarData(
          spots: const [
            FlSpot(0, 40),
            FlSpot(100, 40),
          ],
          isCurved: false,
          color: AppColors.emergencyRed,
          barWidth: 2,
          isStepLineChart: false,
          dashArray: [5, 5],
          dotData: const FlDotData(show: false),
        ),
        // Warning low line (hypoglycémie modérée)
        LineChartBarData(
          spots: const [
            FlSpot(0, 45),
            FlSpot(100, 45),
          ],
          isCurved: false,
          color: AppColors.warningOrange,
          barWidth: 2,
          dashArray: [5, 5],
          dotData: const FlDotData(show: false),
        ),
        // High line (hyperglycémie)
        LineChartBarData(
          spots: const [
            FlSpot(0, 150),
            FlSpot(100, 150),
          ],
          isCurved: false,
          color: AppColors.mediumYellow,
          barWidth: 2,
          dashArray: [5, 5],
          dotData: const FlDotData(show: false),
        ),
      ];
    } else {
      // Temperature thresholds
      return [
        // Emergency low (hypothermie sévère)
        LineChartBarData(
          spots: const [
            FlSpot(0, 32),
            FlSpot(100, 32),
          ],
          isCurved: false,
          color: AppColors.emergencyRed,
          barWidth: 2,
          dashArray: [5, 5],
          dotData: const FlDotData(show: false),
        ),
        // Warning low (hypothermie)
        LineChartBarData(
          spots: const [
            FlSpot(0, 36),
            FlSpot(100, 36),
          ],
          isCurved: false,
          color: AppColors.warningOrange,
          barWidth: 2,
          dashArray: [5, 5],
          dotData: const FlDotData(show: false),
        ),
        // Fever line (fièvre)
        LineChartBarData(
          spots: const [
            FlSpot(0, 37.5),
            FlSpot(100, 37.5),
          ],
          isCurved: false,
          color: AppColors.emergencyRed,
          barWidth: 2,
          dashArray: [5, 5],
          dotData: const FlDotData(show: false),
        ),
      ];
    }
  }

  double _getMinY() {
    final values = data.map((d) {
      final v = d['value'];
      return v is double ? v : double.tryParse(v.toString()) ?? 0;
    }).toList();
    final min = values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
    if (parameter == 'glucose') {
      return (min - 10).clamp(0, double.infinity).toDouble(); // ✅ إرجاع double
    }
    return (min - 2).clamp(25, double.infinity).toDouble(); // ✅ إرجاع double
  }

  double _getMaxY() {
    final values = data.map((d) {
      final v = d['value'];
      return v is double ? v : double.tryParse(v.toString()) ?? 0;
    }).toList();
    final max = values.isEmpty ? 100 : values.reduce((a, b) => a > b ? a : b);
    if (parameter == 'glucose') {
      return max + 20;
    }
    return max + 2;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}