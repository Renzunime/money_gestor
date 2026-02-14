import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../data/models/goal_model.dart';

class GoalProvider extends ChangeNotifier {
  List<GoalModel> _goals = [];

  List<GoalModel> get goals => _goals;

  // Cargar metas al inicio
  void loadGoals() {
    final box = Hive.box<GoalModel>('goals');
    _goals = box.values.toList();
    notifyListeners();
  }

  // Crear nueva meta
  Future<void> addGoal(GoalModel goal) async {
    final box = Hive.box<GoalModel>('goals');
    await box.put(goal.id, goal);
    _goals.add(goal);
    notifyListeners();
  }

  // Abonar dinero a la meta
  Future<void> addFunds(String id, double amount) async {
    final box = Hive.box<GoalModel>('goals');
    final goal = box.get(id);

    if (goal != null) {
      final updatedGoal = GoalModel(
        id: goal.id,
        name: goal.name,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount + amount,
        deadline: goal.deadline,
      );

      await box.put(id, updatedGoal);

      // Actualizar en memoria
      final index = _goals.indexWhere((g) => g.id == id);
      if (index != -1) {
        _goals[index] = updatedGoal;
        notifyListeners();
      }
    }
  }

  Future<void> deleteGoal(String id) async {
    final box = Hive.box<GoalModel>('goals');
    await box.delete(id);
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
  }
}
