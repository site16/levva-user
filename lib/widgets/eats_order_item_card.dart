import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/eats_order_model.dart'; // Importa o modelo e EatsOrderStatus

class EatsOrderItemCard extends StatelessWidget {
  final EatsOrderModel order;
  final VoidCallback? onTap;

  const EatsOrderItemCard({super.key, required this.order, this.onTap});

  Widget _buildStatusWidget(BuildContext context, EatsOrderStatus status) {
    IconData icon;
    Color color;
    String text;

    // Mapeia EatsOrderStatus para UI
    switch (status) {
      case EatsOrderStatus.pending:
        icon = Icons.hourglass_empty_rounded;
        color = Colors.orange.shade700;
        text = "Pendente";
        break;
      case EatsOrderStatus.confirmed:
        icon = Icons.thumb_up_alt_outlined;
        color = Colors.blue.shade700;
        text = "Confirmado";
        break;
      case EatsOrderStatus.preparing:
        icon = Icons.restaurant_menu_rounded;
        color = Colors.deepOrange.shade600;
        text = "Preparando";
        break;
      case EatsOrderStatus.outForDelivery:
        icon = Icons.delivery_dining_rounded;
        color = Colors.lightGreen.shade700;
        text = "Saiu para entrega";
        break;
      case EatsOrderStatus.delivered:
        icon = Icons.check_circle_outline_rounded;
        color = Colors.green.shade700;
        text = "Entregue";
        break;
      case EatsOrderStatus.cancelledByUser:
      case EatsOrderStatus.cancelledByStore:
        icon = Icons.cancel_outlined;
        color = Colors.red.shade700;
        text = "Cancelado";
        break;
      case EatsOrderStatus.failed:
      default:
        icon = Icons.error_outline_rounded;
        color = Colors.red.shade900;
        text = "Falhou";
        break;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

    // TODO: Você precisará de uma forma de obter o nome da loja a partir do order.storeId
    // Pode ser buscando em uma lista local de lojas ou passando o storeName no EatsOrderModel
    String displayStoreName = order.storeId; // Placeholder, idealmente seria o nome da loja

    return Card(
      elevation: 1.0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: Colors.grey.shade200, width: 0.8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50, // Cor temática para Eats
                  borderRadius: BorderRadius.circular(8.0),
                ),
                // TODO: Adicionar logo da loja se disponível em order.storeInfo ou buscando por storeId
                child: Icon(Icons.fastfood_outlined, color: Colors.orange.shade700, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible( // Para o nome da loja não estourar
                          child: Text(
                            displayStoreName, // Mostrar nome da loja aqui
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusWidget(context, order.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                     Text(
                      dateTimeFormatter.format(order.orderDate),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    // Resumo dos itens (exemplo simples)
                    Text(
                      // Exibe o nome do primeiro item ou "Múltiplos itens"
                      order.items.isNotEmpty
                          ? (order.items.length > 1
                              ? '${order.items.first.product.name} e mais ${order.items.length - 1} ${order.items.length -1 == 1 ? "item" : "itens"}'
                              : order.items.first.product.name)
                          : 'Nenhum item',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currencyFormatter.format(order.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}