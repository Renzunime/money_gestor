import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/recurring_provider.dart'; // <--- IMPORTANTE: Para calcular los gastos fijos

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final recProvider = Provider.of<RecurringProvider>(context); // <--- NUEVO

    final stats = provider.monthlyStats;
    final totalIncome = provider.monthlyIncome;
    final currentMonth = provider.selectedMonth;

    // Base de cálculo para la gráfica 50/30/20
    final baseCalculation =
        totalIncome > 0 ? totalIncome : provider.monthlyExpenses;

    // --- CÁLCULO DE LIBERTAD FINANCIERA (NUEVO) ---
    final totalBalance = provider.totalBalance;
    final monthlyFixedExpenses = recProvider.subscriptions
        .where((sub) => sub.isActive)
        .fold(
            0.0,
            (sum, sub) =>
                sum +
                (sub.frequency == 'Anual' ? sub.amount / 12 : sub.amount));

    String runwayText = "∞";
    String runwaySubtitle = "Sin gastos fijos registrados";
    Color runwayColor = Colors.greenAccent;

    if (monthlyFixedExpenses > 0) {
      final months = totalBalance / monthlyFixedExpenses;
      if (months < 1) {
        runwayText = "${(months * 30).toStringAsFixed(0)} Días";
        runwayColor = Colors.redAccent;
      } else {
        runwayText = "${months.toStringAsFixed(1)} Meses";
        runwayColor = months > 6 ? Colors.greenAccent : Colors.orangeAccent;
      }
      runwaySubtitle =
          "Sobrevives con \$${monthlyFixedExpenses.toStringAsFixed(0)}/mes fijos";
    }
    // ---------------------------------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis Financiero 🧠'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. TARJETA DE LIBERTAD FINANCIERA (NUEVO AGREGADO)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade900, Colors.blue.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  children: [
                    const Text("TIEMPO DE LIBERTAD",
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 5),
                    Text(runwayText,
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: runwayColor)),
                    Text(runwaySubtitle,
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),

              // 2. SELECTOR DE MES (TU CÓDIGO ORIGINAL)
              Container(
                decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        onPressed: () => provider.changeMonth(-1)),
                    Text(
                        DateFormat('MMMM yyyy', 'es_ES')
                            .format(currentMonth)
                            .toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        onPressed: () => provider.changeMonth(1)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 3. GRÁFICO 50/30/20 (TU CÓDIGO ORIGINAL)
              if (baseCalculation == 0)
                const SizedBox(
                    height: 200,
                    child: Center(
                        child: Text('Sin datos financieros',
                            style: TextStyle(color: Colors.grey))))
              else
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
                            if (totalIncome > provider.monthlyExpenses)
                              PieChartSectionData(
                                  value: totalIncome - provider.monthlyExpenses,
                                  color: Colors.grey.withOpacity(0.1),
                                  radius: 50,
                                  showTitle: false),
                          ],
                        ),
                      ),
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
                                  color: Colors.white)),
                        ],
                      )
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // 4. DIAGNÓSTICO (TU CÓDIGO ORIGINAL)
              _buildDiagnosticCard(stats, baseCalculation),
            ],
          ),
        ),
      ),
    );
  }

  // --- TUS MÉTODOS AUXILIARES ORIGINALES (INTACTOS) ---
  PieChartSectionData _buildSection(
      double value, double total, Color color, String ideal) {
    if (value == 0)
      return PieChartSectionData(
          value: 0, title: '', radius: 10, showTitle: false);
    final percent = (value / total * 100);
    return PieChartSectionData(
      color: color,
      value: value,
      title: '${percent.toStringAsFixed(0)}%',
      radius: 60,
      titleStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      badgeWidget: percent > 5 ? _Badge(ideal) : null,
      badgePositionPercentageOffset: 1.3,
    );
  }

  Widget _buildDiagnosticCard(Map<String, double> stats, double total) {
    String message = "¡Tus finanzas están equilibradas!";
    IconData icon = Icons.check_circle;
    Color color = Colors.green;

    final needsPct = total == 0 ? 0 : stats['Necesidad']! / total;
    final wantsPct = total == 0 ? 0 : stats['Deseo']! / total;

    if (needsPct > 0.60) {
      message = "Alerta: Tus Necesidades superan el 60% de tus ingresos.";
      icon = Icons.warning_amber;
      color = Colors.redAccent;
    } else if (wantsPct > 0.40) {
      message = "Cuidado: Estás destinando mucho a Deseos.";
      icon = Icons.shopping_bag;
      color = Colors.orangeAccent;
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
