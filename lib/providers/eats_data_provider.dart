// lib/providers/eats_orders_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/eats_order_model.dart';
import '../models/eats_cart_item_model.dart';
import '../models/eats_product_model.dart';
import '../models/eats_addon_model.dart';
import '../services/auth_service.dart';

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
      // LÓGICA REAL DE BUSCA NO FIRESTORE (EXEMPLO - DESCOMENTE E ADAPTE QUANDO FOR USAR)
      /*
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('eatsOrders') // Certifique-se que este é o nome correto da sua subcoleção
          .orderBy('orderDate', descending: true)
          .get();

      _eatsOrders = snapshot.docs
          .map((doc) => EatsOrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      */

      // --------- INÍCIO: DADOS MOCKADOS (REMOVA OU COMENTE AO INTEGRAR COM FIRESTORE) --------
      print(
        "EatsOrdersProvider: Usando dados mockados para fetchEatsOrders. Implemente a busca real do Firestore.",
      );
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simula latência da rede
      _eatsOrders = _getMockEatsOrders(userId); // Usando a função mock
      // --------- FIM: DADOS MOCKADOS --------

      _isLoading = false;
      notifyListeners();
    } catch (error, stackTrace) {
      print("Erro ao buscar pedidos Eats: $error");
      print("StackTrace: $stackTrace");
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
      // LÓGICA REAL DO FIRESTORE (EXEMPLO - DESCOMENTE E ADAPTE QUANDO FOR USAR)
      /*
      // Garante que o userId no objeto 'order' é o do usuário autenticado
      final orderToSave = order.copyWith(userId: userId); // Supondo um método copyWith no EatsOrderModel

      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('eatsOrders') // Certifique-se que este é o nome correto da sua subcoleção
          .add(orderToSave.toMap()); // Usa o método toMap() do EatsOrderModel
      
      // Adiciona o pedido com ID do Firebase à lista local para feedback imediato
      final newOrderWithFirebaseId = orderToSave.copyWith(id: docRef.id);
      _eatsOrders.insert(0, newOrderWithFirebaseId);
      */

      // --------- INÍCIO: SIMULAÇÃO (REMOVA OU COMENTE AO INTEGRAR COM FIRESTORE) --------
      print("EatsOrdersProvider: Simulando salvar novo pedido no Firestore.");
      await Future.delayed(const Duration(seconds: 1));

      // Cria uma nova instância baseada na 'order' recebida, mas com um novo ID e statusHistory inicial
      final newOrderWithId = EatsOrderModel(
        id:
            DateTime.now().millisecondsSinceEpoch
                .toString(), // Novo ID Mock para esta simulação
        userId: userId, // Garante o userId correto
        storeId: order.storeId,
        storeName: order.storeName, // Deve vir preenchido no objeto 'order'
        storeAddress: order.storeAddress,
        storePhoneNumber: order.storePhoneNumber,
        storeLogoUrl: order.storeLogoUrl,
        items: order.items,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        serviceFee: order.serviceFee,
        discountApplied: order.discountApplied,
        totalAmount: order.totalAmount,
        deliveryAddress: order.deliveryAddress,
        paymentMethod: order.paymentMethod,
        paymentDetails: order.paymentDetails,
        notes: order.notes,
        status: EatsOrderStatus.pending, // Status inicial para um novo pedido
        orderDate: DateTime.now(), // Data atual para o novo pedido simulado
        estimatedDeliveryTime:
            order
                .estimatedDeliveryTime, // Pode ser recalculado ou vir de 'order'
        statusHistory: [
          // Histórico inicial para o novo pedido
          OrderStatusEvent(
            status: EatsOrderStatus.pending,
            timestamp: DateTime.now(),
            description: "Pedido realizado",
          ),
        ],
        trackingNumber: order.trackingNumber,
      );
      _eatsOrders.insert(0, newOrderWithId);
      // --------- FIM: SIMULAÇÃO --------

      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      print("Erro ao realizar pedido Eats: $error");
      print("StackTrace: $stackTrace");
      _errorMessage = "Erro ao processar seu pedido. Tente novamente.";
      notifyListeners();
      return false;
    }
  }

  List<EatsOrderModel> _getMockEatsOrders(String userId) {
    // Definições de produtos e adicionais mockados para usar nos pedidos
    final mockSushiProduct = EatsProductModel(
      id: 'prod_sushi',
      storeId: 'sushi_imperial_id',
      storeName: "Sushi Imperial (Mock)",
      name: 'Combinado Salmão Especial',
      description: '10 Sashimi, 8 Niguiri, 6 Uramaki',
      price: 55.0,
      category: 'Combinados',
    );
    final mockSushiAddon = EatsAddonModel(
      id: 'addon_sushi',
      name: 'Gengibre Extra',
      price: 1.50,
    );

    final mockPizzaProduct = EatsProductModel(
      id: 'prod_pizza',
      storeId: 'pizzaria_id',
      storeName: "Pizzaria Delícia (Mock)",
      name: 'Pizza Margherita Grande',
      description: 'Molho de tomate, mussarela, manjericão fresco',
      price: 48.0,
      category: 'Pizzas Tradicionais',
    );

    final mockLancheProduct = EatsProductModel(
      id: 'prod_lanche_xtudo',
      storeId: 'lanches_id',
      storeName: "Lanchonete do Zé (Mock)",
      name: 'X-Tudo da Casa',
      description: 'Pão, 2 carnes, ovo, queijo duplo, bacon, salada completa',
      price: 28.0,
      category: 'Lanches Especiais',
    );
    final mockLancheBebida = EatsProductModel(
      id: 'prod_refri_lata',
      storeId: 'lanches_id',
      storeName: "Lanchonete do Zé (Mock)",
      name: 'Refrigerante Lata',
      description: 'Coca-Cola 350ml',
      price: 6.0,
      category: 'Bebidas',
    );

    return [
      EatsOrderModel(
        id: 'mock_eats_1',
        userId: userId,
        storeId: 'sushi_imperial_id',
        storeName: "Sushi Imperial (Mock)",
        storeAddress: "Rua da Simulação Gastronômica, 123, Setor Leste",
        storePhoneNumber: "(62) 3222-0001",
        storeLogoUrl:
            "https://via.placeholder.com/100x100/FFCDD2/000000?Text=Sushi", // Exemplo de URL
        items: [
          EatsCartItemModel(
            product: mockSushiProduct,
            quantity: 1,
            selectedAddons: [mockSushiAddon],
            observation: "Caprichar no salmão!",
          ),
        ],
        subtotal: mockSushiProduct.price + mockSushiAddon.price,
        deliveryFee: 7.0,
        serviceFee: 1.0,
        discountApplied: 0.0,
        totalAmount:
            (mockSushiProduct.price + mockSushiAddon.price) + 7.0 + 1.0,
        deliveryAddress: OrderAddressModel(
          street: "Rua dos Sonhos",
          number: "100",
          neighborhood: "Jardim Paraíso",
          city: "Goiânia",
          postalCode: "74000-001",
          complement: "Apto 101",
        ),
        paymentMethod: "Cartão de Crédito (Online)",
        paymentDetails: "Visa final **** 4321",
        notes: "Entregar na portaria, por favor.",
        status: EatsOrderStatus.delivered,
        orderDate: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
        estimatedDeliveryTime: DateTime.now()
            .subtract(const Duration(days: 2, hours: 3))
            .add(const Duration(minutes: 45)),
        statusHistory: [
          OrderStatusEvent(
            status: EatsOrderStatus.pending,
            timestamp: DateTime.now().subtract(
              const Duration(days: 2, hours: 3),
            ),
            description: "Pedido realizado",
          ),
          OrderStatusEvent(
            status: EatsOrderStatus.confirmed,
            timestamp: DateTime.now().subtract(
              const Duration(days: 2, hours: 2, minutes: 50),
            ),
            description: "Loja confirmou",
          ),
          OrderStatusEvent(
            status: EatsOrderStatus.preparing,
            timestamp: DateTime.now().subtract(
              const Duration(days: 2, hours: 2, minutes: 30),
            ),
            description: "Em preparo",
          ),
          OrderStatusEvent(
            status: EatsOrderStatus.outForDelivery,
            timestamp: DateTime.now().subtract(
              const Duration(days: 2, hours: 2),
            ),
            description: "Saiu para entrega",
          ),
          OrderStatusEvent(
            status: EatsOrderStatus.delivered,
            timestamp: DateTime.now().subtract(
              const Duration(days: 2, hours: 1, minutes: 15),
            ),
            description: "Entregue com sucesso",
          ),
        ],
        trackingNumber: "LEVVA001FS",
      ),
      EatsOrderModel(
        id: 'mock_eats_2',
        userId: userId,
        storeId: 'pizzaria_id',
        storeName: "Pizzaria Delícia (Mock)",
        storeAddress: "Avenida das Pizzas Quentes, 789, Setor Sul",
        storePhoneNumber: "(62) 3222-0002",
        // storeLogoUrl: "URL_DA_LOGO_PIZZARIA_AQUI",
        items: [EatsCartItemModel(product: mockPizzaProduct, quantity: 1)],
        subtotal: mockPizzaProduct.price,
        deliveryFee: 0.0, // Entrega Grátis
        serviceFee: 0.0,
        discountApplied: 5.0, // Cupom de R$5
        totalAmount: mockPizzaProduct.price - 5.0,
        deliveryAddress: OrderAddressModel(
          street: "Rua da Gula",
          number: "200",
          neighborhood: "Vila Faminta",
          city: "Aparecida de Goiânia",
          postalCode: "74000-002",
        ),
        paymentMethod: "Pix",
        paymentDetails: "Chave: pedido@levva.com",
        status: EatsOrderStatus.confirmed,
        orderDate: DateTime.now().subtract(const Duration(hours: 5)),
        estimatedDeliveryTime: DateTime.now()
            .subtract(const Duration(hours: 5))
            .add(const Duration(minutes: 60)),
        statusHistory: [
          OrderStatusEvent(
            status: EatsOrderStatus.pending,
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
            description: "Pedido enviado",
          ),
          OrderStatusEvent(
            status: EatsOrderStatus.confirmed,
            timestamp: DateTime.now().subtract(
              const Duration(hours: 4, minutes: 55),
            ),
            description: "Confirmado pela pizzaria",
          ),
        ],
      ),
      // Adicionando o mock_eats_order_003 que estava causando problemas
      EatsOrderModel(
        id: 'mock_eats_order_003',
        userId: userId,
        storeId: 'lanches_id',
        storeName: "Lanchonete do Zé (Mock)",
        storeAddress: "Praça da Simulação Central, Quiosque 3",
        storePhoneNumber: "(62) 3222-0003",
        items: [
          EatsCartItemModel(
            product: mockLancheProduct,
            quantity: 2,
            observation: "Sem picles em um, por favor.",
          ),
          EatsCartItemModel(product: mockLancheBebida, quantity: 3),
        ],
        subtotal: (mockLancheProduct.price * 2) + (mockLancheBebida.price * 3),
        deliveryFee: 4.50,
        serviceFee: 0.50,
        discountApplied: 0.0,
        totalAmount:
            (mockLancheProduct.price * 2) +
            (mockLancheBebida.price * 3) +
            4.50 +
            0.50,
        deliveryAddress: OrderAddressModel(
          street: "Alameda dos Bytes",
          number: "1024",
          neighborhood: "Setor Binário",
          city: "Goianésia",
          postalCode: "76380-000",
          reference: "Ao lado da padaria virtual",
        ),
        paymentMethod: "Dinheiro (Troco para R\$ 100,00)",
        paymentDetails:
            "Troco solicitado: R\$ XYZ", // Este detalhe pode ser calculado ou vir da tela de checkout
        notes: "Tudo bem caprichado!",
        status: EatsOrderStatus.outForDelivery,
        orderDate: DateTime.now().subtract(const Duration(minutes: 75)),
        estimatedDeliveryTime: DateTime.now()
            .subtract(const Duration(minutes: 75))
            .add(const Duration(minutes: 40)),
        statusHistory: [
          OrderStatusEvent(
            status: EatsOrderStatus.pending,
            timestamp: DateTime.now().subtract(const Duration(minutes: 75)),
            description: "Pedido feito",
          ),
          OrderStatusEvent(
            status: EatsOrderStatus.confirmed,
            timestamp: DateTime.now().subtract(const Duration(minutes: 70)),
            description: "Zé confirmou",
          ),
          OrderStatusEvent(
            status: EatsOrderStatus.preparing,
            timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
            description: "Na chapa!",
          ),
          OrderStatusEvent(
            status: EatsOrderStatus.outForDelivery,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            description: "Motoboy Zezinho a caminho",
          ),
        ],
        trackingNumber: "LEVVAFOOD003",
      ),
    ];
  }
}
