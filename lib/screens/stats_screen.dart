import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final stats = provider.monthlyStats;
    final totalIncome = provider.monthlyIncome; // BASE DE CÁLCULO: INGRESOS
    final currentMonth = provider.selectedMonth;

    // Si no hay ingresos, usamos el total de gastos para no romper la gráfica,
    // pero idealmente se debe comparar contra ingresos.
    final baseCalculation =
        totalIncome > 0 ? totalIncome : provider.monthlyExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis Mensual'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. SELECTOR DE MES
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                      onPressed: () => provider.changeMonth(-1),
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'es_ES')
                          .format(currentMonth)
                          .toUpperCase(),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 18),
                      onPressed: () => provider.changeMonth(1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 2. GRÁFICO (Ahora comparado con Ingresos)
              if (baseCalculation == 0)
                const SizedBox(
                  height: 300,
                  child: Center(
                    child: Text('Sin datos financieros este mes',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else ...[
                SizedBox(
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 60,
                          sections: [
                            _buildSection(stats['Necesidad']!, baseCalculation,
                                Colors.blueAccent, '50%'),
                            _buildSection(stats['Deseo']!, baseCalculation,
                                Colors.orangeAccent, '30%'),
                            _buildSection(stats['Ahorro']!, baseCalculation,
                                Colors.greenAccent, '20%'),
                            // Espacio restante (Lo que te sobra del sueldo)
                            if (totalIncome > provider.monthlyExpenses)
                              PieChartSectionData(
                                value: totalIncome - provider.monthlyExpenses,
                                color: Colors.grey.withOpacity(0.1),
                                title: '',
                                radius: 50,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                      // Texto central con el % gastado total
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Gastado',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            '${((provider.monthlyExpenses / baseCalculation) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 3. DIAGNÓSTICO INTELIGENTE
                _buildDiagnosticCard(stats, baseCalculation),

                const SizedBox(height: 20),

                // 4. DESGLOSE TÉCNICO
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Desglose (vs Ingresos)',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                _buildDetailRow('Necesidades', stats['Necesidad']!,
                    baseCalculation, 0.50, Colors.blueAccent),
                _buildDetailRow('Deseos', stats['Deseo']!, baseCalculation,
                    0.30, Colors.orangeAccent),
                _buildDetailRow('Ahorro/Inversión', stats['Ahorro']!,
                    baseCalculation, 0.20, Colors.greenAccent),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PieChartSectionData _buildSection(
      double value, double total, Color color, String ideal) {
    if (value == 0)
      return PieChartSectionData(
          value: 0, title: '', radius: 10, showTitle: false);

    final percent = (value / total * 100);
    // Si el porcentaje es muy pequeño, no mostramos el badge para que no se vea feo
    final showBadge = percent > 5;

    return PieChartSectionData(
      color: color,
      value: value,
      title: '${percent.toStringAsFixed(0)}%',
      radius: 60,
      titleStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      badgeWidget: showBadge ? _Badge(ideal) : null,
      badgePositionPercentageOffset: 1.3,
    );
  }

  Widget _buildDiagnosticCard(Map<String, double> stats, double total) {
    String message = "¡Tus finanzas están equilibradas!";
    IconData icon = Icons.check_circle;
    Color color = Colors.green;

    final needsPct = stats['Necesidad']! / total;
    final wantsPct = stats['Deseo']! / total;
    final savePct = stats['Ahorro']! / total;

    if (needsPct > 0.60) {
      message = "Alerta: Tus Necesidades superan el 60% de tus ingresos.";
      icon = Icons.warning_amber;
      color = Colors.redAccent;
    } else if (wantsPct > 0.40) {
      message = "Cuidado: Estás destinando mucho a Deseos/Lujos.";
      icon = Icons.shopping_bag;
      color = Colors.orangeAccent;
    } else if (savePct < 0.10 && total > 0) {
      message = "Consejo: Intenta subir tu Ahorro al menos al 10%.";
      icon = Icons.savings;
      color = Colors.blueAccent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 16),
          Expanded(
              child: Text(message,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label, double value, double total, double target, Color color) {
    final percent = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                CircleAvatar(backgroundColor: color, radius: 6),
                const SizedBox(width: 8),
                Text(label),
              ]),
              Text(
                  '\$${value.toStringAsFixed(2)}  (${(percent * 100).toStringAsFixed(1)}%)',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: color.withOpacity(0.1),
            color: percent > target + 0.1 ? Colors.red : color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: Colors.black54, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: const TextStyle(fontSize: 10, color: Colors.white70)),
    );
  }
}
