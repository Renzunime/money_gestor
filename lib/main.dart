import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// --- NUEVOS IMPORTS NECESARIOS PARA EL IDIOMA ---
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Imports de tus archivos
import 'core/theme/app_theme.dart';
import 'data/models/transaction_model.dart';
import 'data/models/goal_model.dart'; // <--- Importamos el modelo de metas
import 'providers/transaction_provider.dart';
import 'providers/goal_provider.dart'; // <--- Importamos el provider de metas
import 'screens/home_screen.dart';

void main() async {
  // 1. Inicialización de Bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicialización de Hive
  await Hive.initFlutter();

  // 3. Registro de Adapters
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(
      GoalModelAdapter()); // <--- NUEVO: Registramos el adaptador de metas

  // 4. Abrir las cajas de datos
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<GoalModel>(
      'goals'); // <--- NUEVO: Abrimos la caja de metas

  // 5. Inicializar formato de fechas en Español
  await initializeDateFormatting('es_ES', null);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider de Transacciones
        ChangeNotifierProvider(
          create: (_) => TransactionProvider()..loadTransactions(),
        ),
        // NUEVO: Provider de Metas
        ChangeNotifierProvider(
          create: (_) => GoalProvider()..loadGoals(),
        ),
      ],
      child: MaterialApp(
        title: 'Money Gestor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,

        // --- CONFIGURACIÓN DE IDIOMA ---
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'), // Español
          Locale('en', 'US'), // Inglés (fallback)
        ],
        // ---------------------------------

        home: const HomeScreen(),
      ),
    );
  }
}
