import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../data/models/recurring_model.dart';
import '../providers/recurring_provider.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RecurringProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pagos Recurrentes 📅')),
      body: provider.subscriptions.isEmpty
          ? const Center(
              child: Text(
                'No tienes suscripciones activas.\n¡Agrega tus gastos fijos aquí!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.subscriptions.length,
              itemBuilder: (context, index) {
                final sub = provider.subscriptions[index];
                final daysLeft =
                    sub.nextPaymentDate.difference(DateTime.now()).inDays;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.withOpacity(0.2),
                      child: const Icon(Icons.loop, color: Colors.indigoAccent),
                    ),
                    title: Text(sub.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${sub.frequency} - Próx: ${DateFormat('dd/MM').format(sub.nextPaymentDate)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${sub.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              daysLeft < 0
                                  ? '¡Vencido!'
                                  : 'en ${daysLeft + 1} días',
                              style: TextStyle(
                                  color: daysLeft < 3
                                      ? Colors.redAccent
                                      : Colors.grey,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.grey, size: 20),
                          onPressed: () => provider.deleteSubscription(sub.id),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String frequency = 'Mensual';
    String category = 'Servicios';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nueva Suscripción',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nombre (Ej: Netflix)')),
              const SizedBox(height: 10),
              TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Monto'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: frequency,
                      items: ['Mensual', 'Anual']
                          .map(
                              (f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (val) => setState(() => frequency = val!),
                      decoration:
                          const InputDecoration(labelText: 'Frecuencia'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null)
                          setState(() => selectedDate = picked);
                      },
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Próximo Pago'),
                        child:
                            Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                    final newSub = RecurringModel(
                      id: const Uuid().v4(),
                      title: titleCtrl.text,
                      amount: double.parse(amountCtrl.text),
                      category: category,
                      frequency: frequency,
                      nextPaymentDate: selectedDate,
                    );
                    Provider.of<RecurringProvider>(context, listen: false)
                        .addSubscription(newSub);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Activar Pago Automático'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
