import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Para vibración

// Imports de tus componentes
import '../providers/transaction_provider.dart';
import '../providers/recurring_provider.dart';
import '../widgets/transaction_card.dart';
import '../widgets/balance_card.dart';

// Pantallas
import 'add_transaction_screen.dart';
import 'stats_screen.dart';
import 'goals_screen.dart';
import 'all_transactions_screen.dart';
import 'recurring_screen.dart';
import 'budget_screen.dart';
import 'rewards_screen.dart'; // <--- IMPORTANTE: La pantalla de trofeos

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confettiController;

  // Estado para la multiselección
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // Llaves para el Tutorial (Showcase)
  final GlobalKey _addKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _budgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Configuración del confeti (explosión corta)
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    // Automatización y Tutorial al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final txProvider =
          Provider.of<TransactionProvider>(context, listen: false);

      // 1. Revisar si hay pagos fijos (suscripciones) pendientes
      Provider.of<RecurringProvider>(context, listen: false)
          .checkRecurringTransactions(txProvider);

      // 2. Iniciar tutorial si es la primera vez
      _checkFirstTime();
    });
  }

  // Lógica para mostrar el tutorial solo una vez
  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    // Usamos una llave única. Si quieres reiniciar el tutorial para pruebas, cambia el nombre aquí.
    final isFirstTime = prefs.getBool('intro_tutorial_v1') ?? true;

    if (isFirstTime) {
      if (mounted) {
        // Inicia la secuencia de luces
        ShowCaseWidget.of(context)
            .startShowCase([_addKey, _budgetKey, _statsKey]);
      }
      await prefs.setBool('intro_tutorial_v1', false);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // --- MÉTODOS DE SELECCIÓN MÚLTIPLE ---
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
    HapticFeedback.mediumImpact(); // Vibración al activar
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

  // Lógica de Niveles (Gamificación)
  Map<String, dynamic> _getLevelInfo(int streak) {
    if (streak < 3) {
      return {
        'title': 'Novato',
        'color': Colors.blueGrey,
        'icon': Icons.star_border
      };
    }
    if (streak < 7) {
      return {
        'title': 'Constante',
        'color': Colors.cyan,
        'icon': Icons.star_half
      };
    }
    if (streak < 21) {
      return {'title': 'Experto', 'color': Colors.orange, 'icon': Icons.star};
    }
    return {
      'title': 'Maestro',
      'color': Colors.purpleAccent,
      'icon': Icons.auto_awesome
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final streak = provider.currentStreak;
    final level = _getLevelInfo(streak);

    return Scaffold(
      // --- APP BAR DINÁMICA ---
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
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Renzu Finanzas',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'Nivel: ${level['title']}',
                    style: TextStyle(
                        fontSize: 12,
                        color: level['color'],
                        fontWeight: FontWeight.w500),
                  )
                ],
              ),
              centerTitle: false,
              actions: [
                // INDICADOR DE RACHA (Click para ir a Premios)
                Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: (level['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: (level['color'] as Color).withOpacity(0.5)),
                  ),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Navegar a la Sala de Trofeos
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const RewardsScreen()));
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.local_fire_department,
                              color: level['color'], size: 20),
                          const SizedBox(width: 4),
                          Text('$streak días',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: level['color'])),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

      // --- CUERPO PRINCIPAL ---
      body: Stack(
        children: [
          Column(
            children: [
              // Solo mostramos Balance y Accesos Rápidos si NO estamos borrando cosas
              if (!_isSelectionMode) ...[
                const BalanceCard(),
                const SizedBox(height: 10),
                _buildQuickActions(context),
              ],

              // Header de la lista
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                      label: const Text('Ver todos'),
                    )
                  ],
                ),
              ),

              // LISTA DE TRANSACCIONES
              Expanded(
                child: provider.transactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                            bottom: 100), // Espacio para el FAB
                        itemCount: provider.transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = provider.transactions[index];
                          final isSelected =
                              _selectedIds.contains(transaction.id);

                          // Swipe to Delete (Deslizar para borrar)
                          return Dismissible(
                            key: Key(transaction.id),
                            direction: _isSelectionMode
                                ? DismissDirection.none
                                : DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red.shade900,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text("Borrar",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(width: 10),
                                  Icon(Icons.delete, color: Colors.white),
                                ],
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              HapticFeedback.heavyImpact();
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("¿Borrar movimiento?"),
                                  content: const Text(
                                      "Esta acción no se puede deshacer."),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text("Cancelar")),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text("Borrar",
                                            style:
                                                TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) {
                              provider.deleteTransaction(transaction.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Transacción eliminada')));
                            },
                            child: GestureDetector(
                              onLongPress: () =>
                                  _enterSelectionMode(transaction.id),
                              onTap: () async {
                                if (_isSelectionMode) {
                                  _toggleSelection(transaction.id);
                                } else {
                                  // Editar transacción
                                  await Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => AddTransactionScreen(
                                              transactionToEdit: transaction)));
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                color: isSelected
                                    ? Colors.indigo.withOpacity(0.3)
                                    : Colors.transparent,
                                child: TransactionCard(
                                  transaction: transaction,
                                  onDelete: _isSelectionMode
                                      ? () {} // En selección, el botón individual no hace nada
                                      : () => provider
                                          .deleteTransaction(transaction.id),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // CAPA DE CONFETI (Animación)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 10,
              minBlastForce: 5,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
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

      // --- BOTÓN FLOTANTE (Nuevo Gasto) ---
      floatingActionButton: !_isSelectionMode
          ? Showcase(
              key: _addKey,
              title: 'Empieza tu Imperio 🚀',
              description:
                  'Registra tu primer ingreso o gasto aquí.\n¡Es el primer paso para el control!',
              tooltipBackgroundColor: Colors.indigo,
              textColor: Colors.white,
              targetShapeBorder: const CircleBorder(),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen()));

                  // Si el usuario agregó algo, podríamos lanzar confeti aquí si quisiéramos
                  // if (provider.transactions.isNotEmpty) _confettiController.play();
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Nuevo",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          : null,
    );
  }

  // --- ESTADO VACÍO (ILUSTRACIÓN) ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined,
              size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            '¡Todo limpio!',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 8),
          Text(
            'Añade un gasto o ingreso para ver la magia.',
            style: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  // --- ACCESOS RÁPIDOS (BOTONES SUPERIORES) ---
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
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.flag_rounded,
            label: 'Metas',
            color: Colors.purpleAccent,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
          ),
          const SizedBox(width: 12),

          // Tutorial Paso 2: Análisis
          Showcase(
            key: _statsKey,
            title: 'Tu Futuro 🔮',
            description:
                'Descubre cuántos días de libertad\nfinanciera has acumulado.',
            tooltipBackgroundColor: Colors.indigo,
            textColor: Colors.white,
            targetPadding: const EdgeInsets.all(4),
            child: _ActionButton(
              icon: Icons.pie_chart_rounded,
              label: 'Análisis',
              color: Colors.orangeAccent,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const StatsScreen())),
            ),
          ),

          const SizedBox(width: 12),

          // Tutorial Paso 3: Límites
          Showcase(
            key: _budgetKey,
            title: 'Escudo Anti-Gastos 🛡️',
            description:
                'Ponte límites en "Comida" o "Fiesta"\ny la app te avisará si te pasas.',
            tooltipBackgroundColor: Colors.indigo,
            textColor: Colors.white,
            targetPadding: const EdgeInsets.all(4),
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

// --- WIDGET DE BOTÓN PERSONALIZADO (OPTIMIZADO PARA SHOWCASE) ---
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
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 90,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: color.withOpacity(0.3), width: 1)),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
