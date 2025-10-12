import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/despesa.dart';
import '../services/database_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // IDs fixos para notificações diárias
  static const int _notificacaoHojeId = 999999;
  static const int _notificacaoAmanhaId = 999998;

  NotificationService._init();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Agenda notificações diárias às 09h para verificar vencimentos
  Future<void> agendarNotificacoesDiarias() async {
    // Cancelar notificações diárias anteriores
    await _notifications.cancel(_notificacaoHojeId);
    await _notifications.cancel(_notificacaoAmanhaId);

    // Agendar para amanhã às 09h (e se repetir diariamente)
    await _agendarVerificacaoVencimentos();
  }

  /// Agenda a verificação e envio de notificações de vencimentos
  Future<void> _agendarVerificacaoVencimentos() async {
    final now = DateTime.now();

    // Próxima execução às 09h
    DateTime nextRun = DateTime(now.year, now.month, now.day, 9, 0);

    // Se já passou das 09h hoje, agendar para amanhã
    if (now.hour >= 9) {
      nextRun = nextRun.add(const Duration(days: 1));
    }

    final scheduledDate = tz.TZDateTime.from(nextRun, tz.local);

    // Verificar e enviar notificações
    await _verificarENotificarVencimentos();

    // Agendar próxima verificação (amanhã às 09h)
    _agendarProximaVerificacao(scheduledDate);
  }

  /// Agenda a próxima verificação diária
  void _agendarProximaVerificacao(tz.TZDateTime scheduledDate) {
    // Nota: Para notificações diárias recorrentes verdadeiras, seria necessário
    // usar um plugin adicional como android_alarm_manager_plus ou workmanager.
    // Por enquanto, as notificações são verificadas cada vez que o app é aberto.
    // Uma solução mais robusta exigiria um serviço em background.
  }

  /// Verifica despesas vencendo hoje e amanhã e envia notificações
  Future<void> _verificarENotificarVencimentos() async {
    final db = DatabaseService.instance;
    final hoje = DateTime.now();
    // Normalizar para calcular amanhã corretamente
    final hojeNormalizado = DateTime(hoje.year, hoje.month, hoje.day);
    final amanhaNormalizado = hojeNormalizado.add(const Duration(days: 1));

    // Buscar todas as despesas
    final todasDespesas = await db.buscarTodasDespesas();

    // Filtrar despesas vencendo hoje (não pagas)
    final despesasHoje = todasDespesas.where((despesa) {
      if (despesa.status == StatusPagamento.pago ||
          despesa.diaVencimento == null)
        return false;
      return despesa.ano == hoje.year &&
          despesa.mes == hoje.month &&
          despesa.diaVencimento == hoje.day;
    }).toList();

    // Filtrar despesas vencendo amanhã (não pagas)
    final despesasAmanha = todasDespesas.where((despesa) {
      if (despesa.status == StatusPagamento.pago ||
          despesa.diaVencimento == null)
        return false;
      return despesa.ano == amanhaNormalizado.year &&
          despesa.mes == amanhaNormalizado.month &&
          despesa.diaVencimento == amanhaNormalizado.day;
    }).toList();

    // Enviar notificação para hoje (se houver despesas)
    if (despesasHoje.isNotEmpty) {
      await _enviarNotificacaoVencimentosHoje(despesasHoje.length);
    }

    // Enviar notificação para amanhã (se houver despesas)
    if (despesasAmanha.isNotEmpty) {
      await _enviarNotificacaoVencimentosAmanha(despesasAmanha.length);
    }
  }

  /// Envia notificação de despesas vencendo hoje
  Future<void> _enviarNotificacaoVencimentosHoje(int quantidade) async {
    const androidDetails = AndroidNotificationDetails(
      'vencimentos_diarios',
      'Vencimentos Diários',
      channelDescription: 'Notificações diárias de vencimento de despesas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final texto = quantidade == 1
        ? 'Hoje vence 1 conta'
        : 'Hoje vencem $quantidade contas';

    await _notifications.show(
      _notificacaoHojeId,
      '⏰ Contas Vencendo Hoje',
      texto,
      details,
    );
  }

  /// Envia notificação de despesas vencendo amanhã
  Future<void> _enviarNotificacaoVencimentosAmanha(int quantidade) async {
    const androidDetails = AndroidNotificationDetails(
      'vencimentos_diarios',
      'Vencimentos Diários',
      channelDescription: 'Notificações diárias de vencimento de despesas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final texto = quantidade == 1
        ? 'Amanhã vence 1 conta'
        : 'Amanhã vencem $quantidade contas';

    await _notifications.show(
      _notificacaoAmanhaId,
      '📅 Contas Vencendo Amanhã',
      texto,
      details,
    );
  }

  /// Verifica e envia notificações imediatamente (útil para testar ou executar manualmente)
  Future<void> verificarVencimentosAgora() async {
    await _verificarENotificarVencimentos();
  }

  Future<void> agendarNotificacaoVencimento(Despesa despesa) async {
    if (despesa.diaVencimento == null) return;

    final now = DateTime.now();
    final vencimento = DateTime(
      despesa.ano,
      despesa.mes,
      despesa.diaVencimento!,
    );
    final dataNotificacao = vencimento.subtract(const Duration(days: 1));

    // Não agendar se a data já passou
    if (dataNotificacao.isBefore(now)) return;

    final scheduledDate = tz.TZDateTime.from(
      DateTime(
        dataNotificacao.year,
        dataNotificacao.month,
        dataNotificacao.day,
        9, // 9h da manhã
        0,
      ),
      tz.local,
    );

    const androidDetails = AndroidNotificationDetails(
      'vencimentos',
      'Vencimentos',
      channelDescription: 'Notificações de vencimento de despesas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      despesa.id ?? 0,
      'Vencimento Amanhã! 💰',
      '${despesa.descricao} - R\$ ${despesa.valor.toStringAsFixed(2)}',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelarNotificacao(int despesaId) async {
    await _notifications.cancel(despesaId);
  }

  Future<void> cancelarTodasNotificacoes() async {
    await _notifications.cancelAll();
  }
}
