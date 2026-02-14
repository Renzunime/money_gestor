import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../data/models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _allTransactions = [];

  // Getter para obtener las transacciones (ordenadas por fecha descendente)
  List<TransactionModel> get transactions {
    // Nota: Para optimizar, idealmente no deberíamos ordenar cada vez que se llama,
    // pero para esta escala de app está bien.
    _allTransactions.sort((a, b) => b.date.compareTo(a.date));
    return _allTransactions;
  }

  // Cargar datos al inicio
  void loadTransactions() {
    final box = Hive.box<TransactionModel>('transactions');
    _allTransactions = box.values.toList();
    notifyListeners();
  }

  // Agregar transacción
  Future<void> addTransaction(TransactionModel transaction) async {
    final box = Hive.box<TransactionModel>('transactions');
    await box.put(transaction.id, transaction);
    _allTransactions.add(transaction);
    notifyListeners();
  }

  // Eliminar transacción
  Future<void> deleteTransaction(String id) async {
    final box = Hive.box<TransactionModel>('transactions');
    await box.delete(id);
    _allTransactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
  }

  // Actualizar transacción
  Future<void> updateTransaction(TransactionModel updatedTransaction) async {
    final box = Hive.box<TransactionModel>('transactions');
    await box.put(updatedTransaction.id, updatedTransaction);

    final index =
        _allTransactions.indexWhere((tx) => tx.id == updatedTransaction.id);
    if (index != -1) {
      _allTransactions[index] = updatedTransaction;
      notifyListeners();
    }
  }

  // --- FUNCIONES AVANZADAS ---

  // 1. Eliminar múltiples (Batch Delete)
  Future<void> deleteMultipleTransactions(List<String> ids) async {
    final box = Hive.box<TransactionModel>('transactions');
    await box.deleteAll(ids);
    _allTransactions.removeWhere((tx) => ids.contains(tx.id));
    notifyListeners();
  }

  // 2. Actualización Masiva de Categoría
  Future<void> bulkUpdateCategory(List<String> ids, String newCategory) async {
    final box = Hive.box<TransactionModel>('transactions');

    for (var id in ids) {
      final tx = box.get(id);
      if (tx != null) {
        final updatedTx = TransactionModel(
          id: tx.id,
          title: tx.title,
          amount: tx.amount,
          date: tx.date,
          isExpense: tx.isExpense,
          category: newCategory,
        );
        await box.put(id, updatedTx);

        final index = _allTransactions.indexWhere((t) => t.id == id);
        if (index != -1) {
          _allTransactions[index] = updatedTx;
        }
      }
    }
    notifyListeners();
  }

  // 3. Buscador
  List<TransactionModel> searchTransactions(String query) {
    if (query.isEmpty) return transactions;

    final lowerQuery = query.toLowerCase();
    return _allTransactions.where((tx) {
      return tx.title.toLowerCase().contains(lowerQuery) ||
          tx.category.toLowerCase().contains(lowerQuery) ||
          tx.amount.toString().contains(query);
    }).toList();
  }

  // 4. Racha de días (Streak)
  int get currentStreak {
    if (_allTransactions.isEmpty) return 0;

    final sortedDates = _allTransactions
        .map((tx) => DateTime(tx.date.year, tx.date.month, tx.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime checkDate = todayDate;

    if (!sortedDates.contains(todayDate)) {
      if (!sortedDates.contains(todayDate.subtract(const Duration(days: 1)))) {
        return 0;
      }
      checkDate = todayDate.subtract(const Duration(days: 1));
    }

    while (sortedDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // 5. Total por Categoría (Movido aquí y eliminada la duplicada)
  double getMonthTotalByCategory(String category) {
    final now = DateTime.now();
    return _allTransactions
        .where((tx) =>
            tx.isExpense &&
            tx.category == category &&
            tx.date.year == now.year &&
            tx.date.month == now.month)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // --- ESTADÍSTICAS ---
  double get totalBalance {
    double income = _allTransactions
        .where((tx) => !tx.isExpense)
        .fold(0, (sum, tx) => sum + tx.amount);
    double expense = _allTransactions
        .where((tx) => tx.isExpense)
        .fold(0, (sum, tx) => sum + tx.amount);
    return income - expense;
  }

  double get monthlyIncome {
    final now = DateTime.now();
    return _allTransactions
        .where((tx) =>
            !tx.isExpense &&
            tx.date.month == now.month &&
            tx.date.year == now.year)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  double get monthlyExpenses {
    final now = DateTime.now();
    return _allTransactions
        .where((tx) =>
            tx.isExpense &&
            tx.date.month == now.month &&
            tx.date.year == now.year)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  // Mapas para gráficas
  DateTime _selectedMonth = DateTime.now();
  DateTime get selectedMonth => _selectedMonth;

  void changeMonth(int increment) {
    _selectedMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + increment);
    notifyListeners();
  }

  Map<String, double> get monthlyStats {
    final stats = {'Necesidad': 0.0, 'Deseo': 0.0, 'Ahorro': 0.0};

    final monthTransactions = _allTransactions.where((tx) =>
        tx.isExpense &&
        tx.date.month == _selectedMonth.month &&
        tx.date.year == _selectedMonth.year);

    for (var tx in monthTransactions) {
      if ([
        'Comida',
        'Alquiler',
        'Salud',
        'Transporte',
        'Educación',
        'Servicios'
      ].contains(tx.category)) {
        stats['Necesidad'] = stats['Necesidad']! + tx.amount;
      } else if (['Inversiones', 'Ahorro'].contains(tx.category)) {
        stats['Ahorro'] = stats['Ahorro']! + tx.amount;
      } else {
        stats['Deseo'] = stats['Deseo']! + tx.amount;
      }
    }
    return stats;
  }
}
