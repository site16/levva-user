import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Busca todas as notificações reais do Firestore para o usuário autenticado.
  Future<List<NotificationModel>> getNotifications(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList();
  }

  /// Marca uma notificação como lida no Firestore.
  Future<void> markAsRead(String userId, String notificationId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Marca todas as notificações como lidas no Firestore.
  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final query = await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Remove uma notificação específica do Firestore.
  Future<void> clearNotification(String userId, String notificationId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  /// Remove todas as notificações do Firestore.
  Future<void> clearAllNotifications(String userId) async {
    final batch = _db.batch();
    final query = await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .get();
    for (var doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}