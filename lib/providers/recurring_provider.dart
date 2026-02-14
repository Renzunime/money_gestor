import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../data/models/recurring_model.dart';
import '../data/models/transaction_model.dart';
import 'transaction_provider.dart';

class RecurringProvider extends ChangeNotifier {
  List<RecurringModel> _subscriptions = [];

  List<RecurringModel> get subscriptions => _subscriptions;

  // Cargar y ordenar por fecha más cercana
  void loadSubscriptions() {
    final box = Hive.box<RecurringModel>('recurring');
    _subscriptions = box.values.toList()
      ..sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    notifyListeners();
  }

  Future<void> addSubscription(RecurringModel sub) async {
    final box = Hive.box<RecurringModel>('recurring');
    await box.put(sub.id, sub);
    loadSubscriptions(); // Recargar para ordenar
  }

  Future<void> deleteSubscription(String id) async {
    final box = Hive.box<RecurringModel>('recurring');
    await box.delete(id);
    loadSubscriptions();
  }

  // --- 🧠 EL CEREBRO DE LA AUTOMATIZACIÓN ---
  // Esta función se llamará al abrir la app
  Future<void> checkRecurringTransactions(
      TransactionProvider txProvider) async {
    final box = Hive.box<RecurringModel>('recurring');
    final now = DateTime.now();
    bool changesMade = false;

    for (var sub in box.values) {
      // Si la fecha ya pasó o es hoy, y está activa
      if (sub.isActive &&
          sub.nextPaymentDate.isBefore(now.add(const Duration(days: 1)))) {
        // 1. CREAR EL GASTO REAL EN EL HISTORIAL
        final newTx = TransactionModel(
          id: const Uuid().v4(),
          title: "Pago Automático: ${sub.title}",
          amount: sub.amount,
          date: sub.nextPaymentDate, // Usamos la fecha que tocaba, no "hoy"
          isExpense: true,
          category: sub.category,
        );

        await txProvider.addTransaction(newTx);

        // 2. CALCULAR LA PRÓXIMA FECHA
        DateTime nextDate = sub.nextPaymentDate;
        if (sub.frequency == 'Mensual') {
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
        } else {
          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
        }

        // 3. ACTUALIZAR LA SUSCRIPCIÓN
        final updatedSub = RecurringModel(
          id: sub.id,
          title: sub.title,
          amount: sub.amount,
          category: sub.category,
          frequency: sub.frequency,
          nextPaymentDate: nextDate,
          isActive: sub.isActive,
        );

        await box.put(sub.id, updatedSub);
        changesMade = true;
      }
    }

    if (changesMade) {
      loadSubscriptions();
      // Opcional: Aquí podrías mostrar una notificación local diciendo "Se pagó Netflix"
    }
  }
}
