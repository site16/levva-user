// lib/models/eats_cart_item_model.dart
import 'eats_product_model.dart'; // Seu EatsProductModel
import 'eats_addon_model.dart';   // Seu EatsAddonModel

class EatsCartItemModel {
  final EatsProductModel product;
  int quantity; // Mantido mutável para facilitar o incremento direto no carrinho
  final List<EatsAddonModel> selectedAddons;
  String? observation; // ATUALIZADO para não ser final no seu código original, mantendo assim

  EatsCartItemModel({
    required this.product,
    this.quantity = 1,
    this.selectedAddons = const [],
    this.observation, // Permanece opcional
  });

  double get baseItemPrice {
    double addonsPrice = 0.0;
    for (var addon in selectedAddons) {
      addonsPrice += addon.price;
    }
    return product.price + addonsPrice;
  }

  double get totalPrice => baseItemPrice * quantity;

  bool isSameItemAs(EatsProductModel otherProduct, List<EatsAddonModel> otherSelectedAddons) {
    if (product.id != otherProduct.id) {
      return false;
    }
    if (selectedAddons.length != otherSelectedAddons.length) {
      return false;
    }
    List<String> currentAddonIds = selectedAddons.map((a) => a.id).toList()..sort();
    List<String> otherAddonIds = otherSelectedAddons.map((a) => a.id).toList()..sort();
    for (int i = 0; i < currentAddonIds.length; i++) {
      if (currentAddonIds[i] != otherAddonIds[i]) {
        return false;
      }
    }
    return true;
  }

  // --- MÉTODO toMap ADICIONADO ---
  // Converte a instância de EatsCartItemModel para um Map<String, dynamic>
  Map<String, dynamic> toMap() {
    return {
      // Assumindo que EatsProductModel tem um método toMap()
      'product': product.toMap(),
      'quantity': quantity,
      // Assumindo que EatsAddonModel tem um método toMap()
      'selectedAddons': selectedAddons.map((addon) => addon.toMap()).toList(),
      'observation': observation,
    };
  }

  // --- MÉTODO factory fromMap ADICIONADO ---
  // Cria uma instância de EatsCartItemModel a partir de um Map<String, dynamic>
  factory EatsCartItemModel.fromMap(Map<String, dynamic> map) {
    // Validação básica para o produto, pois é obrigatório
    if (map['product'] == null) {
      throw ArgumentError("Dados do produto ausentes no EatsCartItemModel.fromMap");
    }

    return EatsCartItemModel(
      // Assumindo que EatsProductModel tem um método factory fromMap()
      product: EatsProductModel.fromMap(map['product'] as Map<String, dynamic>),
      quantity: map['quantity'] as int? ?? 1, // Padrão 1 se nulo ou ausente
      // Assumindo que EatsAddonModel tem um método factory fromMap()
      selectedAddons: (map['selectedAddons'] as List<dynamic>?)
              ?.map((addonData) => EatsAddonModel.fromMap(addonData as Map<String, dynamic>))
              .toList() ??
          const [], // Padrão lista vazia se nulo ou ausente
      observation: map['observation'] as String?,
    );
  }
}