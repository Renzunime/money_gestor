import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 1)
class GoalModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name; // Ej: "Viaje a Japón"

  @HiveField(2)
  final double targetAmount; // La meta: $2000

  @HiveField(3)
  final double currentAmount; // Lo ahorrado: $500

  @HiveField(4)
  final DateTime? deadline; // Fecha límite opcional

  // Calcular porcentaje logrado (0.0 a 1.0)
  double get progress => (currentAmount / targetAmount).clamp(0.0, 1.0);

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
  });
}
