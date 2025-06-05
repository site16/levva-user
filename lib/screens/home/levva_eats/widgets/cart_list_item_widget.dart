// lib/screens/home/levva_eats/widgets/cart_list_item_widget.dart
// Ou o caminho correto que você está usando, por exemplo: lib/screens/levva_eats/widgets/cart_list_item_widget.dart
import 'package:flutter/material.dart';
import 'package:levva/models/eats_cart_item_model.dart';
// Ajuste o caminho do import para o seu modelo EatsCartItemModel


class CartListItemWidget extends StatelessWidget {
  final EatsCartItemModel cartItem;
  final Function(int change) onQuantityChanged;
  final VoidCallback onRemoveItem; // Você pode usar onQuantityChanged com -cartItem.quantity para remover

  const CartListItemWidget({
    super.key,
    required this.cartItem,
    required this.onQuantityChanged,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    // Verifica se imageUrl do produto não é nula e começa com 'http'
    final bool hasValidNetworkImage = cartItem.product.imageUrl != null &&
        cartItem.product.imageUrl!.startsWith('http');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: Colors.grey.shade200, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Imagem do Produto
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.0),
                // ATUALIZAÇÃO AQUI para lidar com imageUrl nula
                image: hasValidNetworkImage
                    ? DecorationImage(
                        image: NetworkImage(cartItem.product.imageUrl!), // Usamos '!' porque já verificamos
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {}, // Silencia erro de UI
                      )
                    : null,
              ),
              // Mostra um ícone placeholder se não houver imagem de rede válida
              child: !hasValidNetworkImage
                  ? Icon(Icons.fastfood_outlined, color: Colors.grey.shade500, size: 35)
                  : null,
            ),
            const SizedBox(width: 12),
            // Nome e Preço Unitário
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.product.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unit: R\$ ${cartItem.product.price.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Controles de Quantidade e Preço Total do Item
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: Colors.grey.shade700, size: 22),
                      onPressed: () => onQuantityChanged(-1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Diminuir quantidade',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(
                        cartItem.quantity.toString(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor, size: 22),
                      onPressed: () => onQuantityChanged(1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Aumentar quantidade',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Total: R\$ ${cartItem.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                // Se você quiser um botão de remover explícito, pode adicionar aqui.
                // O onQuantityChanged(-1) repetidamente já removerá o item se a lógica na tela do carrinho estiver correta.
                // Ou você pode usar o onRemoveItem:
                // TextButton(
                //   onPressed: onRemoveItem,
                //   child: Text('Remover', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                //   style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size(50, 20)),
                // )
              ],
            ),
          ],
        ),
      ),
    );
  }
}