import 'package:hive/hive.dart';

// ESTA ES LA LÍNEA QUE SEGURAMENTE TE FALTA O TIENE UN ERROR:
part 'recurring_model.g.dart';

@HiveType(typeId: 2)
class RecurringModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String frequency;

  @HiveField(5)
  final DateTime nextPaymentDate;

  @HiveField(6)
  final bool isActive;

  RecurringModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.nextPaymentDate,
    this.isActive = true,
  });
}
