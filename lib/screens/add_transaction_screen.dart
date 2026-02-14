import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/goal_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transactionToEdit;
  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;
  String _selectedCategory = 'Comida';
  String? _selectedGoalId;

  final List<String> _expenseCategories = [
    'Comida',
    'Transporte',
    'Alquiler',
    'Diversión',
    'Salud',
    'Educación',
    'Inversiones',
    'Ahorro'
  ];
  final List<String> _incomeCategories = [
    'Sueldo',
    'Freelance',
    'Rentabilidad Inversiones',
    'Regalos',
    'Otros'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!;
      _titleController.text = tx.title;
      _amountController.text = tx.amount.toString();
      _selectedDate = tx.date;
      _isExpense = tx.isExpense;
      _selectedCategory = tx.category;
    } else {
      _selectedCategory = _expenseCategories[0];
    }
  }

  void _onGoalSelected(String? goalId, String goalName) {
    setState(() {
      _selectedGoalId = goalId;
      if (goalId != null) {
        _isExpense = true;
        _selectedCategory = 'Ahorro';
        if (_titleController.text.isEmpty ||
            _titleController.text.startsWith('Abono a:')) {
          _titleController.text = "Abono a: $goalName";
        }
      } else {
        if (_titleController.text.startsWith('Abono a:')) {
          _titleController.text = "";
        }
      }
    });
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      final amount = double.parse(_amountController.text);
      if (amount <= 0) return;

      final txProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);

      if (widget.transactionToEdit == null) {
        final newTransaction = TransactionModel(
          id: const Uuid().v4(),
          title: title,
          amount: amount,
          date: _selectedDate,
          isExpense: _isExpense,
          category: _selectedCategory,
        );
        txProvider.addTransaction(newTransaction);

        if (_selectedGoalId != null && _isExpense) {
          goalProvider.addFunds(_selectedGoalId!, amount);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('¡Guardado! Dinero movido a tu Meta 🎯'),
                backgroundColor: Colors.purpleAccent),
          );
        }
      } else {
        final updatedTransaction = TransactionModel(
          id: widget.transactionToEdit!.id,
          title: title,
          amount: amount,
          date: _selectedDate,
          isExpense: _isExpense,
          category: _selectedCategory,
        );
        txProvider.updateTransaction(updatedTransaction);
      }
      Navigator.of(context).pop();
    }
  }

  void _deleteTransaction() {
    Provider.of<TransactionProvider>(context, listen: false)
        .deleteTransaction(widget.transactionToEdit!.id);
    Navigator.of(context).pop();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() => _selectedDate = pickedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = Provider.of<GoalProvider>(context);

    List<String> currentCategories =
        _isExpense ? _expenseCategories : _incomeCategories;
    if (!currentCategories.contains(_selectedCategory))
      _selectedCategory = currentCategories[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.transactionToEdit == null ? 'Nueva Transacción' : 'Editar'),
        actions: [
          if (widget.transactionToEdit != null)
            IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: _deleteTransaction)
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. SELECTOR DE META
                if (widget.transactionToEdit == null) ...[
                  _buildGoalSelector(goalProvider),
                  const SizedBox(height: 20),
                ],

                // 2. TIPO (GASTO/INGRESO)
                IgnorePointer(
                  ignoring: _selectedGoalId != null,
                  child: Opacity(
                    opacity: _selectedGoalId != null ? 0.5 : 1.0,
                    child: _buildTypeSwitch(),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. MONTO
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFF1E293B),
                  ),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) =>
                      (val == null || double.tryParse(val) == null)
                          ? 'Monto inválido'
                          : null,
                ),
                const SizedBox(height: 16),

                // 4. DESCRIPCIÓN
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Ej: Almuerzo, Uber...',
                      border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Ingresa un título' : null,
                ),
                const SizedBox(height: 16),

                // -------------------------------------------------------------
                // SOLUCIÓN AL ERROR DE OVERFLOW:
                // Ya no usamos Row. Usamos Column para apilarlos verticalmente.
                // -------------------------------------------------------------

                // 5. CATEGORÍA
                IgnorePointer(
                  ignoring: _selectedGoalId != null,
                  child: DropdownButtonFormField<String>(
                    isExpanded:
                        true, // Esto asegura que use todo el ancho sin romperse
                    value: _selectedCategory,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: const InputDecoration(
                        labelText: 'Categoría', border: OutlineInputBorder()),
                    items: currentCategories
                        .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat,
                                overflow: TextOverflow
                                    .ellipsis) // Corta el texto si es muy largo
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                  ),
                ),

                const SizedBox(height: 16), // Espacio entre Categoría y Fecha

                // 6. FECHA
                InkWell(
                  onTap: _presentDatePicker,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Fecha',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today)),
                    child: Text(
                      DateFormat('dd / MMMM / yyyy', 'es_ES')
                          .format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                // -------------------------------------------------------------

                const SizedBox(height: 30),

                // BOTÓN DE ACCIÓN
                ElevatedButton.icon(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _selectedGoalId != null
                        ? Colors.purpleAccent
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(
                      _selectedGoalId != null ? Icons.savings : Icons.check),
                  label: Text(
                      _selectedGoalId != null
                          ? 'GUARDAR EN META'
                          : (widget.transactionToEdit == null
                              ? 'GUARDAR'
                              : 'ACTUALIZAR'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET SELECTOR DE META
  Widget _buildGoalSelector(GoalProvider goalProvider) {
    if (goalProvider.goals.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _selectedGoalId != null
            ? Colors.purple.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _selectedGoalId != null
                ? Colors.purpleAccent
                : Colors.grey.withOpacity(0.2),
            width: _selectedGoalId != null ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag,
                  color: _selectedGoalId != null
                      ? Colors.purpleAccent
                      : Colors.grey),
              const SizedBox(width: 10),
              const Text('Destinar a una Meta',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (_selectedGoalId != null) const Spacer(),
              if (_selectedGoalId != null)
                InkWell(
                  onTap: () => _onGoalSelected(null, ''),
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                )
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedGoalId,
              hint: const Text('Selecciona (Opcional)',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              dropdownColor: const Color(0xFF1E293B),
              icon:
                  const Icon(Icons.arrow_drop_down, color: Colors.purpleAccent),
              items: goalProvider.goals.map((goal) {
                return DropdownMenuItem(
                  value: goal.id,
                  child: Text(goal.name,
                      style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  final goalName =
                      goalProvider.goals.firstWhere((g) => g.id == val).name;
                  _onGoalSelected(val, goalName);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isExpense = true;
                _selectedCategory = _expenseCategories[0];
                _selectedGoalId = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isExpense ? Colors.redAccent : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text('Gasto',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isExpense ? Colors.white : Colors.grey)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isExpense = false;
                _selectedCategory = _incomeCategories[0];
                _selectedGoalId = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isExpense ? Colors.greenAccent : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text('Ingreso',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: !_isExpense ? Colors.black : Colors.grey)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
