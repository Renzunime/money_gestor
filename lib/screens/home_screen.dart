import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/transaction_provider.dart';
import '../providers/recurring_provider.dart';
import '../widgets/transaction_card.dart';
import '../widgets/balance_card.dart';
import 'add_transaction_screen.dart';
import 'stats_screen.dart';
import 'goals_screen.dart';
import 'all_transactions_screen.dart';
import 'recurring_screen.dart';
import 'budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confettiController;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // Llaves para el Tutorial
  final GlobalKey _addKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _budgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Revisar transacciones recurrentes
      final txProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      Provider.of<RecurringProvider>(context, listen: false)
          .checkRecurringTransactions(txProvider);

      // 2. Ejecutar tutorial
      _checkFirstTime();
    });
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('first_time_home') ?? true;

    if (isFirstTime) {
      if (mounted) {
        // Disparar las luces del tutorial
        ShowCaseWidget.of(context)
            .startShowCase([_addKey, _budgetKey, _statsKey]);
      }
      await prefs.setBool('first_time_home', false);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // --- MÉTODOS DE SELECCIÓN ---
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) _isSelectionMode = false;
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final streak = provider.currentStreak;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: Colors.indigo.shade900,
              leading: IconButton(
                  icon: const Icon(Icons.close), onPressed: _exitSelectionMode),
              title: Text('${_selectedIds.length} seleccionados'),
              actions: [
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      provider
                          .deleteMultipleTransactions(_selectedIds.toList());
                      _exitSelectionMode();
                    }),
              ],
            )
          : AppBar(
              title: const Text('Renzu Finanzas'),
              actions: [
                Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.orangeAccent, size: 20),
                      const SizedBox(width: 4),
                      Text('$streak días',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orangeAccent)),
                    ],
                  ),
                ),
              ],
            ),
      body: Stack(
        children: [
          Column(
            children: [
              if (!_isSelectionMode) ...[
                const BalanceCard(),
                _buildQuickActions(context),
              ],
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Movimientos Recientes',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AllTransactionsScreen())),
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Buscar'),
                    )
                  ],
                ),
              ),
              Expanded(
                child: provider.transactions.isEmpty
                    ? const Center(
                        child: Text('Sin movimientos este mes',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: provider.transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = provider.transactions[index];
                          final isSelected =
                              _selectedIds.contains(transaction.id);

                          return GestureDetector(
                            onLongPress: () =>
                                _enterSelectionMode(transaction.id),
                            onTap: () async {
                              if (_isSelectionMode) {
                                _toggleSelection(transaction.id);
                              } else {
                                await Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => AddTransactionScreen(
                                            transactionToEdit: transaction)));
                              }
                            },
                            child: Container(
                              color: isSelected
                                  ? Colors.indigo.withOpacity(0.2)
                                  : Colors.transparent,
                              child: TransactionCard(
                                transaction: transaction,
                                onDelete: _isSelectionMode
                                    ? () {}
                                    : () => provider
                                        .deleteTransaction(transaction.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: !_isSelectionMode
          ? Showcase(
              key: _addKey,
              title: '¡Añade un Gasto!',
              description:
                  'Toca aquí para registrar tus ingresos o gastos diarios.',
              child: FloatingActionButton(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen()));
                  _confettiController.play();
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.loop,
            label: 'Fijos',
            color: Colors.blueAccent,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecurringScreen())),
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.flag_rounded,
            label: 'Metas',
            color: Colors.purpleAccent,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
          ),
          const SizedBox(width: 10),
          Showcase(
            key: _statsKey,
            title: 'Analiza tu Dinero',
            description:
                'Aquí verás gráficas de tus gastos y tu tiempo de libertad financiera.',
            child: _ActionButton(
              icon: Icons.pie_chart_rounded,
              label: 'Análisis',
              color: Colors.orangeAccent,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const StatsScreen())),
            ),
          ),
          const SizedBox(width: 10),
          Showcase(
            key: _budgetKey,
            title: 'Ponte Límites',
            description:
                'Define un presupuesto máximo para comida o diversión y no gastes de más.',
            child: _ActionButton(
              icon: Icons.security,
              label: 'Límites',
              color: Colors.tealAccent,
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BudgetScreen())),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
