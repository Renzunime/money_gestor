import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_card.dart';
import '../widgets/balance_card.dart';
import 'add_transaction_screen.dart';
import 'stats_screen.dart';
import 'goals_screen.dart';
import 'all_transactions_screen.dart'; // <--- NUEVO IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Estado para la multiselección
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }

      // Si desmarcamos todos, salimos del modo selección
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
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

  // ACCIÓN: ELIMINAR MULTIPLES
  void _deleteSelected(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar ${_selectedIds.length} elementos'),
        content: const Text('¿Estás seguro? No se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteMultipleTransactions(_selectedIds.toList());
              Navigator.pop(ctx);
              _exitSelectionMode();
            },
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ACCIÓN: AGRUPAR (CAMBIAR CATEGORÍA MASIVO)
  void _groupSelected(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final categories = [
      'Comida',
      'Transporte',
      'Alquiler',
      'Diversión',
      'Salud',
      'Educación',
      'Inversiones',
      'Sueldo',
      'Otros'
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mover a Carpeta (Categoría)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories
                    .map((cat) => ActionChip(
                          label: Text(cat),
                          onPressed: () {
                            provider.bulkUpdateCategory(
                                _selectedIds.toList(), cat);
                            Navigator.pop(ctx);
                            _exitSelectionMode();
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Movidos a $cat')));
                          },
                        ))
                    .toList(),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      // APP BAR DINÁMICO
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: Colors.indigo.shade900,
              leading: IconButton(
                  icon: const Icon(Icons.close), onPressed: _exitSelectionMode),
              title: Text('${_selectedIds.length} seleccionados'),
              actions: [
                IconButton(
                  icon:
                      const Icon(Icons.folder_open), // Icono de Carpeta/Agrupar
                  tooltip: 'Agrupar en Carpeta',
                  onPressed: () => _groupSelected(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Eliminar seleccionados',
                  onPressed: () => _deleteSelected(context),
                ),
              ],
            )
          : AppBar(
              title: const Text('Renzu Finanzas'),
              elevation: 0,
              centerTitle: true,
            ),

      body: Column(
        children: [
          // 1. DASHBOARD y ACCESOS RÁPIDOS (Solo visibles si NO estamos seleccionando para ahorrar espacio, o déjalos)
          if (!_isSelectionMode) ...[
            const BalanceCard(),
            _buildQuickActions(context),
          ],

          // 2. HEADER DE LISTA CON "VER GENERAL"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Movimientos Recientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // BOTÓN "VER GENERAL / BUSCAR"
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AllTransactionsScreen()),
                  ),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('General / Buscar'),
                )
              ],
            ),
          ),

          // 3. LISTA CON SOPORTE DE SELECCIÓN
          Expanded(
            child: provider.transactions.isEmpty
                ? const Center(
                    child: Text('Sin movimientos',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: provider.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = provider.transactions[index];
                      final isSelected = _selectedIds.contains(transaction.id);

                      return GestureDetector(
                        onLongPress: () => _enterSelectionMode(transaction.id),
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(transaction.id);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddTransactionScreen(
                                    transactionToEdit: transaction),
                              ),
                            );
                          }
                        },
                        child: Container(
                          color: isSelected
                              ? Colors.indigo.withOpacity(0.2)
                              : Colors
                                  .transparent, // Color de fondo si está seleccionado
                          child: Stack(
                            children: [
                              TransactionCard(
                                transaction: transaction,
                                // Desactivamos el slide-to-delete si estamos seleccionando para evitar conflictos
                                onDelete: _isSelectionMode
                                    ? () {}
                                    : () => provider
                                        .deleteTransaction(transaction.id),
                              ),
                              // Checkbox visual
                              if (_isSelectionMode)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? Colors.indigoAccent
                                        : Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null, // Ocultamos el botón + si estamos seleccionando
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.flag_rounded,
              label: 'Mis Metas',
              color: Colors.purpleAccent,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.pie_chart_rounded,
              label: 'Análisis',
              color: Colors.orangeAccent,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const StatsScreen())),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar privado
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
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
