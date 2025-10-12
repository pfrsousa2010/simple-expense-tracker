import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/despesa.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

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
