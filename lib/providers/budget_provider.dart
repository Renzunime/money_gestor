import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../data/models/budget_model.dart';

class BudgetProvider extends ChangeNotifier {
  List<BudgetModel> _budgets = [];

  List<BudgetModel> get budgets => _budgets;

  // Esta función es síncrona (void), no necesita Future
  void loadBudgets() {
    final box = Hive.box<BudgetModel>('budgets');
    _budgets = box.values.toList();
    notifyListeners();
  }

  Future<void> addBudget(BudgetModel budget) async {
    final box = Hive.box<BudgetModel>('budgets');

    // Si ya existe presupuesto para esa categoría, lo actualizamos
    final index = _budgets.indexWhere((b) => b.category == budget.category);
    if (index != -1) {
      await deleteBudget(_budgets[index].id);
    }

    await box.put(budget.id, budget);

    loadBudgets(); // <--- CORREGIDO: Sin 'await'
  }

  Future<void> deleteBudget(String id) async {
    final box = Hive.box<BudgetModel>('budgets');
    await box.delete(id);
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}
