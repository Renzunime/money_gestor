import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart'; // <--- 1. IMPORTANTE: Agregar este import

// Modelos
import 'data/models/budget_model.dart';
import 'data/models/transaction_model.dart';
import 'data/models/recurring_model.dart';
import 'data/models/goal_model.dart';

// Providers
import 'providers/budget_provider.dart';
import 'providers/recurring_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/goal_provider.dart';

// UI y Configuración
import 'screens/home_screen.dart';
import 'core/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Hive
  await Hive.initFlutter();

  // Registro de Adapters
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(GoalModelAdapter());
  Hive.registerAdapter(RecurringModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());

  // Abrir cajas de datos
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<GoalModel>('goals');
  await Hive.openBox<RecurringModel>('recurring');
  await Hive.openBox<BudgetModel>('budgets');

  // Inicializar formato de fechas en Español
  await initializeDateFormatting('es_ES', null);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => TransactionProvider()..loadTransactions()),
        ChangeNotifierProvider(create: (_) => GoalProvider()..loadGoals()),
        ChangeNotifierProvider(
            create: (_) => RecurringProvider()..loadSubscriptions()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()..loadBudgets()),
      ],
      child: MaterialApp(
        title: 'Money Gestor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,

        // Configuración de Idioma
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],

        // 2. IMPORTANTE: Envolver el HomeScreen en un ShowCaseWidget
        // Sin esto, las llaves (_addKey, etc) del tutorial no funcionarán.
        home: ShowCaseWidget(
          builder: (context) => const HomeScreen(),
        ),
      ),
    );
  }
}
