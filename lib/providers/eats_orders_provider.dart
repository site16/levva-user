// lib/providers/eats_orders_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/eats_order_model.dart'; // Seu modelo de pedido Eats
import '../models/eats_cart_item_model.dart'; // Para dados mockados
import '../models/eats_product_model.dart'; // Para dados mockados
import '../models/eats_addon_model.dart';   // Para dados mockados
import '../services/auth_service.dart';    // Para obter o userId

class EatsOrdersProvider with ChangeNotifier {
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<EatsOrderModel> _eatsOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  EatsOrdersProvider(this._authService);

  List<EatsOrderModel> get eatsOrders => [..._eatsOrders];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchEatsOrders() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      _errorMessage = "Usuário não autenticado.";
      _eatsOrders = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Lógica real de busca no Firestore (exemplo):
      /*
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('eatsOrders') // Exemplo de caminho
          .orderBy('orderDate', descending: true)
          .get();

      _eatsOrders = snapshot.docs
          .map((doc) => EatsOrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      */

      // --------- INÍCIO: DADOS MOCKADOS (Remover ao integrar com Firestore) --------
      print("EatsOrdersProvider: Usando dados mockados para fetchEatsOrders. Implemente a busca real do Firestore.");
      await Future.delayed(const Duration(seconds: 1));
      _eatsOrders = _getMockEatsOrders(userId); // Usando a função mock
      // --------- FIM: DADOS MOCKADOS --------

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      print("Erro ao buscar pedidos Eats: $error");
      _errorMessage = "Erro ao buscar pedidos do Levva Eats. Tente novamente.";
      _isLoading = false;
      _eatsOrders = [];
      notifyListeners();
    }
  }

  Future<bool> placeNewEatsOrder(EatsOrderModel order) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      _errorMessage = "Usuário não autenticado para realizar pedido.";
      notifyListeners();
      return false;
    }
    try {
      // LÓGICA REAL DO FIRESTORE (COMENTADA POR ENQUANTO):
      /*
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('eatsOrders')
          .add(order.toMap()); // Usa o método toMap() do EatsOrderModel
      
      // Para atualizar o ID localmente se necessário, ou apenas refetch
      // final newOrderWithFirebaseId = order.copyWith(id: docRef.id);
      // _eatsOrders.insert(0, newOrderWithFirebaseId);
      */

      // --------- INÍCIO: SIMULAÇÃO (Remover ao integrar com Firestore) --------
      print("EatsOrdersProvider: Simulando salvar novo pedido no Firestore.");
      await Future.delayed(const Duration(seconds: 1));
      
      // Linha 86 (aproximadamente) - onde o EatsOrderModel é criado
      final newOrderWithId = EatsOrderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // ID Mock
        userId: order.userId,
        storeId: order.storeId,
        storeName: order.storeName, // <<< ADICIONADO: Usa o storeName do pedido de entrada
        // Se order.storeName puder ser nulo e storeName for obrigatório no construtor,
        // você precisaria de um fallback, ex: order.storeName ?? 'Loja Desconhecida'
        // Mas, como tornamos storeName obrigatório, 'order' já deve tê-lo.
        storeAddress: order.storeAddress, // <<< Adicionado se presente em 'order'
        storePhoneNumber: order.storePhoneNumber, // <<< Adicionado se presente em 'order'
        storeLogoUrl: order.storeLogoUrl, // <<< Adicionado se presente em 'order'
        items: order.items,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        serviceFee: order.serviceFee, // <<< Adicionado se presente em 'order'
        discountApplied: order.discountApplied,
        totalAmount: order.totalAmount,
        deliveryAddress: order.deliveryAddress,
        paymentMethod: order.paymentMethod,
        paymentDetails: order.paymentDetails, // <<< Adicionado se presente em 'order'
        notes: order.notes,
        status: EatsOrderStatus.pending, // Status inicial
        orderDate: order.orderDate, // Usa a data do pedido de entrada
        estimatedDeliveryTime: order.estimatedDeliveryTime,
        statusHistory: [ // Adiciona um evento inicial ao histórico
          OrderStatusEvent(status: EatsOrderStatus.pending, timestamp: order.orderDate, description: "Pedido realizado")
        ],
        // trackingNumber: order.trackingNumber, // Se aplicável
      );
      _eatsOrders.insert(0, newOrderWithId);
      // --------- FIM: SIMULAÇÃO --------

      notifyListeners();
      return true; // Indica sucesso
    } catch (error) {
      print("Erro ao realizar pedido Eats: $error");
      _errorMessage = "Erro ao processar seu pedido. Tente novamente.";
      notifyListeners();
      return false; // Indica falha
    }
  }

  // Função mock de exemplo
  List<EatsOrderModel> _getMockEatsOrders(String userId) {
    // Para os mocks, você precisará de instâncias de EatsProductModel e EatsAddonModel
    // Vamos criar alguns placeholders simples aqui
    final mockProduct = EatsProductModel(id: 'prod1', storeId: 'sushi_imperial_id', name: 'Combinado Simples', description: 'Sushi e sashimi', price: 40.0, category: 'Combinados');
    final mockAddon = EatsAddonModel(id: 'addon1', name: 'Wasabi Extra', price: 2.0);

    return [
      EatsOrderModel(
        id: 'mock_eats_1',
        userId: userId,
        storeId: 'sushi_imperial_id',
        storeName: "Sushi Imperial (Mock)", // <<< ADICIONADO
        storeAddress: "Rua da Simulação, 123",
        storePhoneNumber: "(62) 99999-0001",
        items: [
          EatsCartItemModel(product: mockProduct, quantity: 1, selectedAddons: [mockAddon])
        ],
        subtotal: 42.0,
        deliveryFee: 5.0,
        totalAmount: 47.0,
        deliveryAddress: OrderAddressModel(street: "Rua Mock", number: "123", neighborhood: "Mock Bairro", city: "Mockcidade", postalCode: "76000-000"),
        paymentMethod: "Dinheiro",
        status: EatsOrderStatus.delivered,
        orderDate: DateTime.now().subtract(const Duration(days: 2)),
        estimatedDeliveryTime: DateTime.now().subtract(const Duration(days: 2)).add(const Duration(minutes: 40)),
        statusHistory: [
          OrderStatusEvent(status: EatsOrderStatus.pending, timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 1))),
          OrderStatusEvent(status: EatsOrderStatus.confirmed, timestamp: DateTime.now().subtract(const Duration(days: 2, minutes: 50))),
          OrderStatusEvent(status: EatsOrderStatus.preparing, timestamp: DateTime.now().subtract(const Duration(days: 2, minutes: 40))),
          OrderStatusEvent(status: EatsOrderStatus.outForDelivery, timestamp: DateTime.now().subtract(const Duration(days: 2, minutes: 20))),
          OrderStatusEvent(status: EatsOrderStatus.delivered, timestamp: DateTime.now().subtract(const Duration(days: 2))),
        ]
      ),
      EatsOrderModel(
        id: 'mock_eats_2',
        userId: userId,
        storeId: 'pizzaria_id',
        storeName: "Pizzaria Delícia (Mock)", // <<< ADICIONADO
        storeAddress: "Avenida da Simulação, 456",
        storePhoneNumber: "(62) 99999-0002",
        items: [
          EatsCartItemModel(product: EatsProductModel(id: 'prod2', storeId: 'pizzaria_id', name: 'Pizza Calabresa G', description: 'Molho, queijo, calabresa', price: 55.0, category: 'Pizzas'), quantity: 1)
        ],
        subtotal: 55.0,
        deliveryFee: 0.0, // Entrega Grátis
        totalAmount: 55.0,
        deliveryAddress: OrderAddressModel(street: "Av Mock", number: "456", neighborhood: "Mock Centro", city: "Mockcidade", postalCode: "76000-001"),
        paymentMethod: "Pelo App (LevvaPay)",
        status: EatsOrderStatus.preparing,
        orderDate: DateTime.now().subtract(const Duration(hours: 3)),
        estimatedDeliveryTime: DateTime.now().subtract(const Duration(hours: 3)).add(const Duration(minutes: 50)),
        statusHistory: [
           OrderStatusEvent(status: EatsOrderStatus.pending, timestamp: DateTime.now().subtract(const Duration(hours: 3))),
           OrderStatusEvent(status: EatsOrderStatus.confirmed, timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 50))),
           OrderStatusEvent(status: EatsOrderStatus.preparing, timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 40))),
        ]
      ),
    ];
  }
}