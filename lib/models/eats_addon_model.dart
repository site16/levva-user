// lib/models/eats_addon_model.dart

class EatsAddonModel {
  final String id;
  final String name;
  final double price;
  // bool isSelected; // O estado de seleção é gerenciado externamente, como você comentou.

  EatsAddonModel({
    required this.id,
    required this.name,
    required this.price,
  });

  // --- MÉTODO toMap ADICIONADO ---
  // Converte a instância de EatsAddonModel para um Map<String, dynamic>
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }

  // --- MÉTODO factory fromMap ADICIONADO ---
  // Cria uma instância de EatsAddonModel a partir de um Map<String, dynamic>
  factory EatsAddonModel.fromMap(Map<String, dynamic> map) {
    return EatsAddonModel(
      id: map['id'] as String? ?? '', // Fornece valor padrão se nulo
      name: map['name'] as String? ?? 'Adicional Desconhecido', // Fornece valor padrão se nulo
      price: (map['price'] as num?)?.toDouble() ?? 0.0, // Converte num para double, padrão 0.0
    );
  }
}