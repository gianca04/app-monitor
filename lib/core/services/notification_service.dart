import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Inicialización para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Inicialización para iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  // Se ejecuta al hacer clic en la notificación
  void _onDidReceiveNotificationResponse(NotificationResponse details) async {
    final String? filePath = details.payload;
    if (filePath != null && filePath.isNotEmpty) {
      final file = File(filePath);
      if (await file.exists()) {
        await OpenFile.open(filePath);
      }
    }
  }

  // Solicitar permisos en tiempo de ejecución (especialmente Android 13+)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final bool? granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }
    return true;
  }

  // Notificación de inicio de descarga
  Future<void> showDownloadStartNotification({required String filename}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pdf_download_channel',
      'Descarga de Reportes PDF',
      channelDescription: 'Notificaciones sobre la descarga de reportes PDF',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: true,
      onlyAlertOnce: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: 999,
      title: 'Descargando reporte...',
      body: filename,
      notificationDetails: details,
    );
  }

  // Notificación de descarga finalizada
  Future<void> showDownloadCompleteNotification({
    required String filename,
    required String filePath,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pdf_download_channel',
      'Descarga de Reportes PDF',
      channelDescription: 'Notificaciones sobre la descarga de reportes PDF',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Cancelar la de inicio
    await _notificationsPlugin.cancel(id: 999);

    await _notificationsPlugin.show(
      id: _generateNotificationId(filePath),
      title: 'Descarga completada',
      body: '$filename. Toca para abrir.',
      notificationDetails: details,
      payload: filePath,
    );
  }

  // Cancelar la notificación de descarga activa (por ejemplo, en caso de error)
  Future<void> cancelDownloadNotification() async {
    await _notificationsPlugin.cancel(id: 999);
  }

  int _generateNotificationId(String path) {
    return path.hashCode.abs() % 100000;
  }
}
