import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final streak = provider.currentStreak;

    // Lista de Premios (Logros)
    final List<Map<String, dynamic>> rewards = [
      {
        'days': 3,
        'title': 'El Despertar',
        'icon': Icons.wb_sunny,
        'color': Colors.amber,
        'secret':
            '💡 Regla de Oro: Págate a ti mismo primero. Ahorra el 10% apenas recibas tu sueldo.'
      },
      {
        'days': 7,
        'title': 'Constancia Pura',
        'icon': Icons.local_fire_department,
        'color': Colors.orangeAccent,
        'secret':
            '🔥 Interés Compuesto: Ahorrar \$5 diarios por 30 años al 8% se convierten en \$220,000.'
      },
      {
        'days': 14,
        'title': 'Guardián del Dinero',
        'icon': Icons.shield,
        'color': Colors.blueAccent,
        'secret':
            '🛡️ Fondo de Emergencia: Antes de invertir, ten ahorrados 3 meses de gastos fijos.'
      },
      {
        'days': 30,
        'title': 'Maestro Financiero',
        'icon': Icons.auto_awesome,
        'color': Colors.purpleAccent,
        'secret':
            '👑 Regla 24h: Para compras > \$50, espera un día. El 80% de las ganas se irán.'
      },
      {
        'days': 60,
        'title': 'Leyenda Viviente',
        'icon': Icons.diamond,
        'color': Colors.cyanAccent,
        'secret':
            '💎 Libertad: No compras con dinero, compras con el tiempo de vida que te costó ganarlo.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sala de Trofeos 🏆'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // CABECERA DE NIVEL
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade900, Colors.blue.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                const Text("RACHA ACTUAL",
                    style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                        fontSize: 12)),
                const SizedBox(height: 5),
                Text("$streak Días",
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (streak % 30) / 30,
                  backgroundColor: Colors.white10,
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 10),
                const Text("Sigue así para desbloquear más secretos.",
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Text("Tus Logros",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // LISTA DE LOGROS
          ...rewards.map((reward) {
            final isUnlocked = streak >= reward['days'];
            return _RewardCard(
              title: reward['title'],
              description: isUnlocked
                  ? reward['secret']
                  : 'Bloqueado hasta los ${reward['days']} días.',
              icon: reward['icon'],
              color: reward['color'],
              isUnlocked: isUnlocked,
              requiredDays: reward['days'],
            );
          }),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final int requiredDays;

  const _RewardCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.requiredDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? color.withOpacity(0.5)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isUnlocked
                ? color.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isUnlocked ? icon : Icons.lock,
            color: isUnlocked ? color : Colors.grey,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUnlocked ? Colors.white : Colors.grey,
          ),
        ),
        subtitle: Text(
          isUnlocked ? "Desbloqueado" : "Meta: $requiredDays días",
          style: TextStyle(
            color: isUnlocked ? color : Colors.grey,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              description,
              style: TextStyle(
                color: isUnlocked ? Colors.white70 : Colors.grey,
                fontStyle: isUnlocked ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          )
        ],
      ),
    );
  }
}
