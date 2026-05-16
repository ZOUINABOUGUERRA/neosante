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
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              '📊 Aucune donnée disponible',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              'Ajoutez des mesures pour voir le graphique',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ عنوان الرسم البياني
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.medicalBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  parameter == 'glucose' ? Icons.science : Icons.thermostat,
                  color: AppColors.medicalBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                parameter == 'glucose'
                    ? '📈 Évolution de la glycémie'
                    : '🌡️ Évolution de la température',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ✅ الرسم البياني
          SizedBox(height: 280, child: LineChart(_buildChartData())),

          const SizedBox(height: 20),

          // ✅ Legend
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem('🟢 Normale', AppColors.stableGreen),
                _buildLegendItem('🟡 Attention', AppColors.mediumYellow),
                _buildLegendItem('🟠 Surveillance', AppColors.warningOrange),
                _buildLegendItem('🔴 Urgence', AppColors.emergencyRed),
                _buildLegendItem('📏 Seuils (pointillés)', Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final value = data[i]['value'];
      final numericValue = value is double
          ? value
          : double.tryParse(value.toString()) ?? 0;
      spots.add(FlSpot(i.toDouble(), numericValue));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: _buildTitlesData(),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      lineBarsData: [
        // ✅ الخط الرئيسي للبيانات
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.medicalBlue,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.medicalBlue.withValues(alpha: 0.1),
          ),
        ),
        // ✅ خطوط العتبة
        ..._getThresholdLines(),
      ],
      minX: -0.5,
      maxX: spots.length - 0.5,
      minY: _getMinY(),
      maxY: _getMaxY(),
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < data.length) {
              final date = data[index]['recordedAt'];
              String label = '';
              if (date != null) {
                final dt = date is Timestamp
                    ? date.toDate()
                    : DateTime.parse(date.toString());
                label = '${dt.day}/${dt.month}';
                if (data.length <= 10) {
                  label +=
                      '\n${dt.hour}h${dt.minute.toString().padLeft(2, '0')}';
                }
              } else {
                label = 'J${index + 1}';
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return const Text('');
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  List<LineChartBarData> _getThresholdLines() {
    final spots = List.generate(data.length, (i) => FlSpot(i.toDouble(), 0));

    if (parameter == 'glucose') {
      return [
        // 🔴 Hypoglycémie sévère (< 40)
        LineChartBarData(
          spots: spots.map((spot) => FlSpot(spot.x, 40)).toList(),
          isCurved: false,
          color: AppColors.emergencyRed,
          barWidth: 2,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
        ),
        // 🟠 Hypoglycémie modérée (40-45)
        LineChartBarData(
          spots: spots.map((spot) => FlSpot(spot.x, 45)).toList(),
          isCurved: false,
          color: AppColors.warningOrange,
          barWidth: 2,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
        ),
        // 🟡 Hyperglycémie (> 150)
        LineChartBarData(
          spots: spots.map((spot) => FlSpot(spot.x, 150)).toList(),
          isCurved: false,
          color: AppColors.mediumYellow,
          barWidth: 2,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
        ),
      ];
    } else {
      // Temperature thresholds
      return [
        // 🔴 Hypothermie sévère (< 32°C)
        LineChartBarData(
          spots: spots.map((spot) => FlSpot(spot.x, 32)).toList(),
          isCurved: false,
          color: AppColors.emergencyRed,
          barWidth: 2,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
        ),
        // 🟠 Hypothermie modérée (32-36°C)
        LineChartBarData(
          spots: spots.map((spot) => FlSpot(spot.x, 36)).toList(),
          isCurved: false,
          color: AppColors.warningOrange,
          barWidth: 2,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
        ),
        // 🔴 Fièvre (> 37.5°C)
        LineChartBarData(
          spots: spots.map((spot) => FlSpot(spot.x, 37.5)).toList(),
          isCurved: false,
          color: AppColors.emergencyRed,
          barWidth: 2,
          dashArray: [6, 4],
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
      return (min - 10).clamp(0, double.infinity).toDouble();
    }
    return (min - 2).clamp(20, double.infinity).toDouble();
  }

  double _getMaxY() {
    final values = data.map((d) {
      final v = d['value'];
      return v is double ? v : double.tryParse(v.toString()) ?? 0;
    }).toList();
    final max = values.isEmpty ? 100 : values.reduce((a, b) => a > b ? a : b);
    if (parameter == 'glucose') {
      return max + 30;
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
            color: color == Colors.grey ? null : color,
            shape: BoxShape.circle,
            border: color == Colors.grey
                ? Border.all(color: Colors.grey, width: 1.5)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color == Colors.grey ? Colors.grey : color,
          ),
        ),
      ],
    );
  }
}
