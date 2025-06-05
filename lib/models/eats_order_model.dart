// lib/models/eats_order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Necessário para Timestamp e conversões Firestore
import 'eats_cart_item_model.dart';
// import 'eats_store_model.dart'; // Se você decidir usar o modelo completo da loja aqui

// Definição de OrderAddressModel (como você forneceu)
class OrderAddressModel {
  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final String? complement;
  final String? postalCode; // <<< SUGESTÃO: CEP
  final String? reference;  // <<< SUGESTÃO: Ponto de referência

  OrderAddressModel({
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    this.complement,
    this.postalCode,
    this.reference,
  });

  @override
  String toString() {
    String address = '$street, $number';
    if (complement != null && complement!.isNotEmpty) {
      address += ' ($complement)';
    }
    address += ' - $neighborhood, $city';
    if (postalCode != null && postalCode!.isNotEmpty) {
      address += ' - CEP: $postalCode';
    }
    return address;
  }

  // Método para converter para Map (útil para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'number': number,
      'neighborhood': neighborhood,
      'city': city,
      'complement': complement,
      'postalCode': postalCode,
      'reference': reference,
    };
  }

  // Método factory para criar a partir de um Map (útil do Firestore)
  factory OrderAddressModel.fromMap(Map<String, dynamic> map) {
    return OrderAddressModel(
      street: map['street'] as String? ?? '',
      number: map['number'] as String? ?? '',
      neighborhood: map['neighborhood'] as String? ?? '',
      city: map['city'] as String? ?? '',
      complement: map['complement'] as String?,
      postalCode: map['postalCode'] as String?,
      reference: map['reference'] as String?,
    );
  }
}

// Enum EatsOrderStatus (como você forneceu)
enum EatsOrderStatus {
  pending,        // Pedido realizado, aguardando confirmação da loja
  confirmed,      // Loja confirmou o pedido
  preparing,      // Pedido está sendo preparado
  outForDelivery, // Pedido saiu para entrega
  delivered,      // Pedido foi entregue
  cancelledByUser,// Pedido cancelado pelo usuário
  cancelledByStore, // Pedido cancelado pela loja
  failed          // Falha na entrega ou processamento
}

// <<< ADIÇÃO SUGERIDA: Classe para eventos de status na linha do tempo >>>
class OrderStatusEvent {
  final EatsOrderStatus status; // Usa o mesmo enum de status do pedido
  final DateTime timestamp;
  final String? description; // Opcional: "Loja confirmou", "Entregador a caminho"

  OrderStatusEvent({
    required this.status,
    required this.timestamp,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status.name, // Salva o nome do enum como string
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
    };
  }

  factory OrderStatusEvent.fromMap(Map<String, dynamic> map) {
    return OrderStatusEvent(
      status: EatsOrderStatus.values.firstWhere(
            (e) => e.name == (map['status'] as String?),
            orElse: () => EatsOrderStatus.pending // Fallback
          ),
      timestamp: (map['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
      description: map['description'] as String?,
    );
  }
}

class EatsOrderModel {
  final String id;
  final String userId;
  final String storeId;
  // <<< ADIÇÕES SUGERIDAS para detalhes da loja (desnormalização) >>>
  final String storeName;
  final String? storeAddress; // Pode ser uma string simples ou um OrderAddressModel se preferir
  final String? storePhoneNumber;
  final String? storeLogoUrl;

  final List<EatsCartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double? serviceFee; // <<< ADIÇÃO SUGERIDA: Taxa de conveniência/serviço
  final double discountApplied;
  final double totalAmount;
  final OrderAddressModel deliveryAddress;
  final String paymentMethod;
  final String? paymentDetails; // <<< ADIÇÃO SUGERIDA: Ex: "via AiqFome", "Cartão Visa final 1234"
  final String? notes;
  final EatsOrderStatus status;         // Status atual geral do pedido
  final DateTime orderDate;
  final DateTime? estimatedDeliveryTime;
  final String? trackingNumber;

  // <<< ADIÇÃO SUGERIDA para a linha do tempo do status >>>
  final List<OrderStatusEvent> statusHistory;

  EatsOrderModel({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.storeName, // <<< ADICIONADO
    this.storeAddress,      // <<< ADICIONADO
    this.storePhoneNumber,  // <<< ADICIONADO
    this.storeLogoUrl,      // <<< ADICIONADO
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    this.serviceFee,        // <<< ADICIONADO
    this.discountApplied = 0.0,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.paymentDetails,    // <<< ADICIONADO
    this.notes,
    required this.status,
    required this.orderDate,
    this.estimatedDeliveryTime,
    this.trackingNumber,
    this.statusHistory = const [], // <<< ADICIONADO (padrão lista vazia)
  });

  // Método para converter para Map (útil para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'storeId': storeId,
      'storeName': storeName,
      'storeAddress': storeAddress,
      'storePhoneNumber': storePhoneNumber,
      'storeLogoUrl': storeLogoUrl,
      'items': items.map((item) => item.toMap()).toList(), // Supondo que EatsCartItemModel tem toMap()
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'discountApplied': discountApplied,
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress.toMap(), // Usa o toMap de OrderAddressModel
      'paymentMethod': paymentMethod,
      'paymentDetails': paymentDetails,
      'notes': notes,
      'status': status.name, // Salva o nome do enum como string
      'orderDate': Timestamp.fromDate(orderDate),
      'estimatedDeliveryTime': estimatedDeliveryTime != null ? Timestamp.fromDate(estimatedDeliveryTime!) : null,
      'trackingNumber': trackingNumber,
      'statusHistory': statusHistory.map((event) => event.toMap()).toList(),
    };
  }

  // Método factory para criar a partir de um DocumentSnapshot do Firestore
  factory EatsOrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError("Missing data for EatsOrderModel ${doc.id}");
    }
    return EatsOrderModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      storeId: data['storeId'] as String? ?? '',
      storeName: data['storeName'] as String? ?? 'Loja Desconhecida',
      storeAddress: data['storeAddress'] as String?,
      storePhoneNumber: data['storePhoneNumber'] as String?,
      storeLogoUrl: data['storeLogoUrl'] as String?,
      items: (data['items'] as List<dynamic>?)
              ?.map((itemData) => EatsCartItemModel.fromMap(itemData as Map<String, dynamic>)) // Supondo EatsCartItemModel.fromMap()
              .toList() ??
          [],
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (data['serviceFee'] as num?)?.toDouble(),
      discountApplied: (data['discountApplied'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: OrderAddressModel.fromMap(data['deliveryAddress'] as Map<String, dynamic>? ?? {}),
      paymentMethod: data['paymentMethod'] as String? ?? 'Não informado',
      paymentDetails: data['paymentDetails'] as String?,
      notes: data['notes'] as String?,
      status: EatsOrderStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String?),
        orElse: () => EatsOrderStatus.pending, // Fallback
      ),
      orderDate: (data['orderDate'] as Timestamp? ?? Timestamp.now()).toDate(),
      estimatedDeliveryTime: (data['estimatedDeliveryTime'] as Timestamp?)?.toDate(),
      trackingNumber: data['trackingNumber'] as String?,
      statusHistory: (data['statusHistory'] as List<dynamic>?)
              ?.map((eventData) => OrderStatusEvent.fromMap(eventData as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}