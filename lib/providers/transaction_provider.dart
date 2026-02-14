import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart'; // Necesario para formatear fechas
import '../data/models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _allTransactions = []; // Copia completa
  DateTime _selectedMonth = DateTime.now(); // Mes seleccionado actualmente

  // Getters
  DateTime get selectedMonth => _selectedMonth;

  // Filtramos las transacciones visibles según el mes seleccionado
  List<TransactionModel> get transactions {
    return _allTransactions.where((tx) {
      return tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Mapa de categorías para la Regla 50/30/20
  final Map<String, String> _categoryType = {
    'Alquiler': 'Necesidad',
    'Comida': 'Necesidad',
    'Transporte': 'Necesidad',
    'Salud': 'Necesidad',
    'Educación': 'Necesidad',
    'Servicios': 'Necesidad',
    'Diversión': 'Deseo',
    'Regalos': 'Deseo',
    'Ropa': 'Deseo',
    'Otros': 'Deseo',
    'Inversiones': 'Ahorro',
    'Ahorro': 'Ahorro',
    'Fondo Emergencia': 'Ahorro'
  };

  // CÁLCULO ESTADÍSTICO DEL MES
  Map<String, double> get monthlyStats {
    double needs = 0;
    double wants = 0;
    double savings = 0;

    for (var tx in transactions) {
      // Usamos solo las del mes filtrado
      if (tx.isExpense) {
        final type = _categoryType[tx.category] ?? 'Deseo';
        if (type == 'Necesidad') needs += tx.amount;
        if (type == 'Deseo') wants += tx.amount;
        if (type == 'Ahorro') savings += tx.amount;
      }
    }
    return {'Necesidad': needs, 'Deseo': wants, 'Ahorro': savings};
  }

  double get monthlyIncome {
    return transactions
        .where((tx) => !tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get monthlyExpenses {
    return transactions
        .where((tx) => tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalBalance => monthlyIncome - monthlyExpenses;

  // --- NAVEGACIÓN DE MESES ---
  void changeMonth(int monthsToAdd) {
    _selectedMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + monthsToAdd);
    notifyListeners();
  }

  // --- CRUD (Gestión de Datos) ---

  void loadTransactions() {
    final box = Hive.box<TransactionModel>('transactions');
    _allTransactions = box.values.toList();
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final box = Hive.box<TransactionModel>('transactions');
    await box.put(transaction.id, transaction);
    _allTransactions.add(transaction);
    notifyListeners();
  }

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

  Future<void> deleteTransaction(String id) async {
    final box = Hive.box<TransactionModel>('transactions');
    await box.delete(id);
    _allTransactions.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  // ... (código anterior)

  // --- NUEVO: FUNCIONES MASIVAS (BATCH) ---

  // 1. Eliminar múltiples transacciones
  Future<void> deleteMultipleTransactions(List<String> ids) async {
    final box = Hive.box<TransactionModel>('transactions');
    await box.deleteAll(ids);

    // Actualizar listas en memoria
    _allTransactions.removeWhere((tx) => ids.contains(tx.id));
    notifyListeners();
  }

  // 2. Agrupar/Categorizar múltiples transacciones
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
          category: newCategory, // Cambiamos la categoría
        );
        await box.put(id, updatedTx);

        // Actualizar memoria
        final index = _allTransactions.indexWhere((t) => t.id == id);
        if (index != -1) _allTransactions[index] = updatedTx;
      }
    }
    notifyListeners();
  }

  // --- NUEVO: BÚSQUEDA AVANZADA ---
  List<TransactionModel> searchTransactions(String query) {
    if (query.isEmpty) return _allTransactions;

    final lowerQuery = query.toLowerCase();
    return _allTransactions.where((tx) {
      final matchTitle = tx.title.toLowerCase().contains(lowerQuery);
      final matchAmount = tx.amount.toString().contains(query);
      final matchCategory = tx.category.toLowerCase().contains(lowerQuery);
      // Búsqueda simple por fecha (Ej: si escriben "2024")
      final matchDate = tx.date.toString().contains(query);

      return matchTitle || matchAmount || matchCategory || matchDate;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
