import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/expense_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tratamento de erros durante inicialização para evitar tela branca
  try {
    // Inicializar formatação de datas em português
    await initializeDateFormatting('pt_BR', null);
  } catch (e) {
    // Log do erro mas continua a execução
    debugPrint('Erro ao inicializar formatação de datas: $e');
  }

  // Inicializar serviço de notificações com tratamento de erros
  try {
    final notificationService = NotificationService.instance;
    await notificationService.initialize();
    await notificationService.requestPermissions();
    
    // Agendar notificações diárias de vencimentos
    await notificationService.agendarNotificacoesDiarias();
  } catch (e) {
    // Log do erro mas continua a execução (notificações não são críticas)
    debugPrint('Erro ao inicializar notificações: $e');
  }

  // Configurar orientação apenas para portrait
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('Erro ao configurar orientação: $e');
  }

  // Configurar estilo da barra de status
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.backgroundDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  } catch (e) {
    debugPrint('Erro ao configurar estilo da barra de status: $e');
  }

  // Sempre executar o app, mesmo se houver erros nas inicializações
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExpenseProvider(),
      child: MaterialApp(
        title: 'Controle Financeiro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR'), Locale('pt')],
      ),
    );
  }
}
