import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService;
  final String userId;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _unreadCount = 0;

  NotificationProvider(this._notificationService, this.userId);

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    // Não chamamos notifyListeners() aqui diretamente, pois geralmente é chamado
    // após uma ação que modifica a lista ou o estado de leitura.
  }

  Future<void> fetchNotifications() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _notifications = await _notificationService.getNotifications(userId);
      _updateUnreadCount();
      print(
        "NotificationProvider: Notificações carregadas: ${_notifications.length}, Não lidas: $_unreadCount",
      );
      notifyListeners();
    } catch (e) {
      print("NotificationProvider: Erro ao buscar notificações: $e");
      _setError("Não foi possível carregar as notificações: ${e.toString()}");
      _notifications = [];
      _unreadCount = 0;
    }
    _setLoading(false); // Notifica no final
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      // Otimisticamente atualiza a UI
      _notifications[index].isRead = true;
      _updateUnreadCount();
      notifyListeners();
      try {
        await _notificationService.markAsRead(userId, notificationId);
        print(
          "NotificationProvider: Notificação $notificationId marcada como lida no serviço.",
        );
      } catch (e) {
        print(
          "NotificationProvider: Erro ao marcar notificação $notificationId como lida no serviço: $e",
        );
        // Reverte a mudança na UI se a chamada ao serviço falhar
        _notifications[index].isRead = false;
        _updateUnreadCount();
        notifyListeners();
      }
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    bool hadUnread = _unreadCount > 0;
    if (!hadUnread) return;

    // Otimisticamente atualiza a UI
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    _updateUnreadCount();
    notifyListeners();

    try {
      await _notificationService.markAllAsRead(userId);
      print(
        "NotificationProvider: Todas as notificações marcadas como lidas no serviço.",
      );
    } catch (e) {
      print(
        "NotificationProvider: Erro ao marcar todas como lidas no serviço: $e",
      );
      await fetchNotifications();
    }
  }

  Future<void> clearNotification(String notificationId) async {
    final originalNotifications = List<NotificationModel>.from(_notifications);
    _notifications.removeWhere((n) => n.id == notificationId);
    _updateUnreadCount();
    notifyListeners();

    try {
      await _notificationService.clearNotification(userId, notificationId);
      print(
        "NotificationProvider: Notificação $notificationId limpa no serviço.",
      );
    } catch (e) {
      print(
        "NotificationProvider: Erro ao limpar notificação $notificationId no serviço: $e",
      );
      _notifications = originalNotifications;
      _updateUnreadCount();
      notifyListeners();
      _setError("Falha ao limpar notificação.");
    }
  }

  Future<void> clearAllNotifications() async {
    if (_notifications.isEmpty) return;
    final originalNotifications = List<NotificationModel>.from(_notifications);
    _notifications.clear();
    _updateUnreadCount();
    notifyListeners();

    try {
      await _notificationService.clearAllNotifications(userId);
      print("NotificationProvider: Todas as notificações limpas no serviço.");
    } catch (e) {
      print(
        "NotificationProvider: Erro ao limpar todas as notificações no serviço: $e",
      );
      _notifications = originalNotifications;
      _updateUnreadCount();
      notifyListeners();
      _setError("Falha ao limpar todas as notificações.");
    }
  }
}