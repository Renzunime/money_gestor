import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_card.dart';
import '../data/models/transaction_model.dart';
import 'add_transaction_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  DateTime? _filterDate;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);

    // Lógica de filtrado combinada (Texto + Fecha opcional)
    List<TransactionModel> displayList = provider.searchTransactions(_query);

    if (_filterDate != null) {
      displayList = displayList
          .where((tx) =>
              tx.date.year == _filterDate!.year &&
              tx.date.month == _filterDate!.month &&
              tx.date.day == _filterDate!.day)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: false,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar (Ej: Comida, 50.00)...',
            hintStyle: const TextStyle(color: Colors.white60),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                        _filterDate = null;
                      });
                    },
                  )
                : null,
          ),
          onChanged: (val) => setState(() => _query = val),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today,
                color:
                    _filterDate != null ? Colors.orangeAccent : Colors.white),
            tooltip: 'Filtrar por fecha',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _filterDate = picked);
              }
            },
          )
        ],
      ),
      body: displayList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey[700]),
                  const SizedBox(height: 10),
                  const Text('No se encontraron resultados',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final transaction = displayList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddTransactionScreen(
                            transactionToEdit: transaction),
                      ),
                    );
                  },
                  child: TransactionCard(
                    transaction: transaction,
                    onDelete: () => provider.deleteTransaction(transaction.id),
                  ),
                );
              },
            ),
    );
  }
}
