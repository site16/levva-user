// lib/globals/cart_data.dart
import '../models/eats_cart_item_model.dart'; // Ajuste o caminho se seus modelos não estiverem em lib/models/

// Lista global para armazenar os itens do carrinho
List<EatsCartItemModel> globalCartItems = [];

// Você pode adicionar funções helper aqui se quiser, por exemplo:
// void clearCart() {
//   globalCartItems.clear();
// }
// double getCartTotal() {
//   return globalCartItems.fold(0, (sum, item) => sum + item.totalPrice);
// }