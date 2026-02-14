import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../data/models/goal_model.dart';
import '../providers/goal_provider.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoalProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Metas de Ahorro')),
      body: provider.goals.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.goals.length,
              itemBuilder: (ctx, i) => _GoalCard(goal: provider.goals[i]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context),
        label: const Text('Nueva Meta'),
        icon: const Icon(Icons.flag),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rocket_launch, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Sin metas definidas.\n¡Define un propósito para tu dinero!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Meta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre (Ej: Laptop Gamer)')),
            TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Monto Objetivo'),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                final newGoal = GoalModel(
                  id: const Uuid().v4(),
                  name: nameCtrl.text,
                  targetAmount: double.parse(amountCtrl.text),
                  currentAmount: 0, // Empieza en 0
                );
                Provider.of<GoalProvider>(context, listen: false)
                    .addGoal(newGoal);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Crear'),
          )
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
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
                Text(goal.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete,
                      color: Colors.redAccent, size: 20),
                  onPressed: () =>
                      Provider.of<GoalProvider>(context, listen: false)
                          .deleteGoal(goal.id),
                )
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              backgroundColor: Colors.grey[800],
              color: Colors.indigoAccent,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '\$${goal.currentAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${(goal.progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.indigoAccent)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.savings),
                label: const Text('Abonar Dinero'),
                onPressed: () => _showDepositDialog(context),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Abonar a ${goal.name}'),
        content: TextField(
            controller: amountCtrl,
            decoration: const InputDecoration(
                labelText: 'Monto a abonar', prefixText: '\$ '),
            keyboardType: TextInputType.number),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (amountCtrl.text.isNotEmpty) {
                Provider.of<GoalProvider>(context, listen: false)
                    .addFunds(goal.id, double.parse(amountCtrl.text));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Abonar'),
          )
        ],
      ),
    );
  }
}
