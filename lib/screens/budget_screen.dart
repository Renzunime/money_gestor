import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../data/models/budget_model.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Presupuestos Mensuales 🛡️')),
      body: budgetProvider.budgets.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: budgetProvider.budgets.length,
              itemBuilder: (context, index) {
                final budget = budgetProvider.budgets[index];
                // Calculamos cuánto lleva gastado
                final spent =
                    txProvider.getMonthTotalByCategory(budget.category);
                final progress = (spent / budget.limitAmount).clamp(0.0, 1.0);

                // Color semáforo
                Color color = Colors.greenAccent;
                if (progress > 0.8) color = Colors.orangeAccent;
                if (progress >= 1.0) color = Colors.redAccent;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(budget.category,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.grey, size: 20),
                              onPressed: () =>
                                  budgetProvider.deleteBudget(budget.id),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: Colors.grey[800],
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${spent.toStringAsFixed(0)} / \$${budget.limitAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: spent > budget.limitAmount
                                      ? Colors.redAccent
                                      : Colors.white),
                            ),
                            Text('${(progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                    color: color, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (spent > budget.limitAmount)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '¡Has excedido tu límite por \$${(spent - budget.limitAmount).toStringAsFixed(0)}!',
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 12),
                            ),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudgetDialog(context),
        label: const Text('Nuevo Límite'),
        icon: const Icon(Icons.security),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Sin presupuestos.\n¡Ponle límites a tus gastos!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    String selectedCategory = 'Comida';
    final categories = [
      'Comida',
      'Transporte',
      'Alquiler',
      'Diversión',
      'Salud',
      'Educación',
      'Otros'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Definir Límite'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Límite Mensual', prefixText: '\$ '),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (amountCtrl.text.isNotEmpty) {
                  final newBudget = BudgetModel(
                    id: const Uuid().v4(),
                    category: selectedCategory,
                    limitAmount: double.parse(amountCtrl.text),
                  );
                  Provider.of<BudgetProvider>(context, listen: false)
                      .addBudget(newBudget);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Guardar'),
            )
          ],
        ),
      ),
    );
  }
}
