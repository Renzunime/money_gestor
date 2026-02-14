import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 3) // Usamos el ID 3
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String category; // Ej: "Comida"

  @HiveField(2)
  final double limitAmount; // Ej: 200.00

  BudgetModel({
    required this.id,
    required this.category,
    required this.limitAmount,
  });
}
