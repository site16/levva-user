// lib/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
// Certifique-se de que seu arquivo enums.dart existe e contém NotificationType
// Se NotificationType estiver neste arquivo, como no seu exemplo, não precisa do import abaixo.
// import 'package:levva/models/enums.dart'; 

// Definição do enum NotificationType (mantenha aqui ou mova para enums.dart e importe)
enum NotificationType {
  promocao, // Promoções, novidades do app, cupons
  corrida,  // Atualizações sobre uma corrida (aceite, a caminho, finalizada)
  sistema,  // Alertas do sistema, atualizações importantes
  outros,   // Notificações genéricas
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final Timestamp timestamp; // Data e hora da notificação
  final NotificationType type;
  bool isRead;
  final String? rideId; // Opcional: ID da corrida relacionada
  
  // NOVOS CAMPOS PARA CUPONS (conforme artefato notification_model_updated_example)
  final String? discountCode; // Código do cupom, ex: "LEVVA20"
  final String? discountId;   // ID do cupom no seu sistema de descontos
  // Adicione outros campos conforme necessário (ex: imageUrl, deepLink)

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.type = NotificationType.outros,
    this.isRead = false,
    this.rideId,
    this.discountCode, // Adicionado ao construtor
    this.discountId,   // Adicionado ao construtor
  });

  // Método factory para criar uma instância a partir de um DocumentSnapshot do Firestore
  // (Atualizado conforme artefato notification_model_updated_example)
  factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data(); // data pode ser nulo se o documento não existir
    if (data == null) {
      // Você pode querer lançar um erro ou retornar um modelo padrão/nulo
      // dependendo de como você quer lidar com documentos não encontrados.
      // Por enquanto, vamos lançar um erro para indicar que algo está errado.
      throw Exception("Documento de notificação não encontrado ou dados nulos para ID: ${doc.id}");
    }
    
    return NotificationModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Sem Título',
      message: data['message'] as String? ?? 'Sem Mensagem',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == data['type'], // Salva como String: "NotificationType.promocao"
        orElse: () => NotificationType.outros, 
      ),
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      isRead: data['isRead'] as bool? ?? false,
      rideId: data['rideId'] as String?,
      discountCode: data['discountCode'] as String?, // Ler do Firestore
      discountId: data['discountId'] as String?,     // Ler do Firestore
    );
  }

  // Método para converter a instância em um Map para salvar no Firestore
  // (Atualizado conforme artefato notification_model_updated_example)
  Map<String, dynamic> toJson() { // Renomeado de toFirestore para convenção comum
    return {
      'title': title,
      'message': message,
      'type': type.toString(), // Salva o enum como String
      'timestamp': timestamp,
      'isRead': isRead,
      if (rideId != null) 'rideId': rideId,
      if (discountCode != null) 'discountCode': discountCode, // Adicionar ao Firestore
      if (discountId != null) 'discountId': discountId,       // Adicionar ao Firestore
      // O ID do documento geralmente não é salvo dentro do próprio documento no Firestore,
      // pois ele já é o ID do DocumentSnapshot.
    };
  }
}
