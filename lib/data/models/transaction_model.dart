import 'package:hive/hive.dart';

// Esta línea es CRÍTICA. Debe coincidir con el nombre de tu archivo.
part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final bool isExpense; // true = Gasto, false = Ingreso

  @HiveField(5)
  final String category;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.category,
  });
}
