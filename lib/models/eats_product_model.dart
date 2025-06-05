// lib/models/eats_product_model.dart
import 'eats_addon_model.dart'; // Certifique-se que EatsAddonModel tem toMap() e fromMap()

class EatsProductModel {
  final String id;
  final String storeId;    // ID da loja à qual este produto pertence
  final String? storeName;  // Nome da loja, agora opcional (String?)
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;     // Categoria do produto (ex: "Sanduíches", "Bebidas")
  final List<EatsAddonModel>? addons; // Lista de adicionais disponíveis para este produto

  EatsProductModel({
    required this.id,
    required this.storeId,
    this.storeName,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    this.addons,
  });

  // --- MÉTODO toMap ADICIONADO ---
  // Converte a instância de EatsProductModel para um Map<String, dynamic>
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storeId': storeId,
      'storeName': storeName,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      // Se 'addons' não for nulo, mapeia cada addon usando seu próprio método toMap()
      // Certifique-se que EatsAddonModel tem um método toMap()
      'addons': addons?.map((addon) => addon.toMap()).toList(),
    };
  }

  // --- MÉTODO factory fromMap ADICIONADO ---
  // Cria uma instância de EatsProductModel a partir de um Map<String, dynamic>
  factory EatsProductModel.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) {
      // Você pode optar por lançar um erro ou retornar um produto "inválido"
      // dependendo de como você quer lidar com dados faltantes.
      // Por enquanto, vamos assumir que campos obrigatórios devem existir.
      print("Alerta: Mapa vazio fornecido para EatsProductModel.fromMap. Pode causar erros se campos obrigatórios estiverem ausentes.");
      // Lançar um erro é mais seguro para garantir a integridade dos dados:
      // throw ArgumentError('Mapa vazio fornecido para EatsProductModel.fromMap');
    }
    return EatsProductModel(
      id: map['id'] as String? ?? '', // Fornece um valor padrão se nulo
      storeId: map['storeId'] as String? ?? '', // Fornece um valor padrão se nulo
      storeName: map['storeName'] as String?, // Já é opcional
      name: map['name'] as String? ?? 'Produto Desconhecido', // Fornece um valor padrão se nulo
      description: map['description'] as String? ?? '', // Fornece um valor padrão se nulo
      price: (map['price'] as num?)?.toDouble() ?? 0.0, // Converte num para double, padrão 0.0
      imageUrl: map['imageUrl'] as String?, // Já é opcional
      category: map['category'] as String? ?? 'Outros', // Fornece um valor padrão se nulo
      // Se 'addons' não for nulo no mapa, mapeia cada addon usando EatsAddonModel.fromMap()
      // Certifique-se que EatsAddonModel tem um método factory fromMap()
      addons: (map['addons'] as List<dynamic>?)
              ?.map((addonData) => EatsAddonModel.fromMap(addonData as Map<String, dynamic>))
              .toList(), // Retorna null se 'addons' for nulo no mapa, pois o campo é List<EatsAddonModel>?
    );
  }
}