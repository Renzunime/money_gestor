import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Servicios
import 'services/notification_service.dart';

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

// UI
import 'screens/home_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicialización de Base de Datos
  await Hive.initFlutter();

  // Registro de Adapters (Evita errores si se recarga)
  if (!Hive.isAdapterRegistered(0))
    Hive.registerAdapter(TransactionModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(GoalModelAdapter());
  if (!Hive.isAdapterRegistered(2))
    Hive.registerAdapter(RecurringModelAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(BudgetModelAdapter());

  // Abrir Cajas
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<GoalModel>('goals');
  await Hive.openBox<RecurringModel>('recurring');
  await Hive.openBox<BudgetModel>('budgets');

  // 2. Inicialización de Notificaciones
  try {
    final notificationService = NotificationService();
    await notificationService.init();

    // Programar la rutina diaria
    await notificationService.scheduleDailyRoutine();
    debugPrint("✅ Notificaciones iniciadas correctamente");
  } catch (e) {
    debugPrint("⚠️ ERROR EN NOTIFICACIONES (La app iniciará sin ellas): $e");
  }

  // 3. Idioma
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

        // --- CORRECCIÓN AQUÍ ---
        // 'builder' espera una función (context) => Widget.
        home: ShowCaseWidget(
          builder: (context) => const HomeScreen(),
        ),
      ),
    );
  }
}
