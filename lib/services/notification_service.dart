import 'package:cloud_firestore/cloud_firestore.dart'; // Para Timestamp
import '../models/notification_model.dart'; // Importa o modelo

class NotificationService {
  // Lista simulada de notificações
  final List<NotificationModel> _simulatedNotifications = [
    NotificationModel(
      id: '1',
      title: 'Bem-vindo ao Levva!',
      message:
          'Explore todas as funcionalidades e comece a pedir as suas entregas.',
      timestamp: Timestamp.now(),
      type: NotificationType.sistema,
    ),
    NotificationModel(
      id: '2',
      title: 'Promoção de Lançamento!',
      message:
          'Use o código LEVVA10 e ganhe 10% de desconto na sua primeira entrega.',
      timestamp: Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 2)),
      ),
      type: NotificationType.promocao,
      isRead: true, // Exemplo de notificação já lida
    ),
    NotificationModel(
      id: '3',
      title: 'Sua Levva a Caminho!',
      message:
          'O entregador Carlos Silva está a caminho para coletar o seu pedido.',
      timestamp: Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 1)),
      ),
      type: NotificationType.corrida,
      rideId: 'corrida_xyz_123',
    ),
    NotificationModel(
      id: '4',
      title: 'Entrega Concluída',
      message:
          'A sua Levva para a Rua Principal, 123 foi concluída com sucesso. Avalie o entregador!',
      timestamp: Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 2)),
      ),
      type: NotificationType.corrida,
      rideId: 'corrida_abc_789',
      isRead: true,
    ),
    NotificationModel(
      id: '5',
      title: 'Atualização Importante',
      message: 'Adicionámos novas áreas de cobertura na sua cidade. Confira!',
      timestamp: Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      type: NotificationType.sistema,
    ),
  ];

  // Simula a obtenção de notificações
  Future<List<NotificationModel>> getNotifications() async {
    // Numa app real, isto viria do Firebase Cloud Messaging,
    // de uma base de dados local (SQLite) ou de um backend.
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simula latência da rede
    // Retorna uma cópia para evitar modificações diretas na lista simulada
    return List<NotificationModel>.from(
      _simulatedNotifications.reversed,
    ); // Mais recentes primeiro
  }

  // Simula marcar uma notificação como lida
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _simulatedNotifications.indexWhere(
      (n) => n.id == notificationId,
    );
    if (index != -1) {
      _simulatedNotifications[index].isRead = true;
      print(
        "NotificationService: Notificação $notificationId marcada como lida (simulado).",
      );
    }
  }

  // Simula marcar todas como lidas
  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (var notification in _simulatedNotifications) {
      notification.isRead = true;
    }
    print(
      "NotificationService: Todas as notificações marcadas como lidas (simulado).",
    );
  }

  // Simula limpar todas as notificações
  Future<void> clearAllNotifications() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _simulatedNotifications.clear();
    print("NotificationService: Todas as notificações limpas (simulado).");
  }

  // Simula limpar uma notificação específica
  Future<void> clearNotification(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _simulatedNotifications.removeWhere((n) => n.id == notificationId);
    print("NotificationService: Notificação $notificationId limpa (simulado).");
  }
}
