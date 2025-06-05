import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/eats_order_model.dart';
import '../../home/levva_eats/store_details_screen.dart'; // Ajuste o caminho se necessário

// (Mantenha o enum EatsOrderStatus e a classe OrderStatusEvent no seu eats_order_model.dart)

class EatsOrderDetailBottomSheet extends StatelessWidget {
  final EatsOrderModel order;

  const EatsOrderDetailBottomSheet({
    super.key,
    required this.order,
  });

  String _formatDate(DateTime dt) {
    return DateFormat('dd/MM', 'pt_BR').format(dt);
  }

  String _formatTime(DateTime dt) {
    return DateFormat('HH:mm', 'pt_BR').format(dt);
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return format.format(amount);
  }

  // Widget para cada nó da timeline de status
  Widget _buildStatusTimelineNode(BuildContext context, {
    required IconData icon,
    required String label,
    String? time,
    required bool isActive, // Se este status específico já ocorreu
    required bool isCurrent, // Se este é o último status ocorrido
    Color? activeColor,
    Color? inactiveColor,
  }) {
    final theme = Theme.of(context);
    activeColor ??= theme.primaryColor; // Cor padrão para ativo
    inactiveColor ??= Colors.grey.shade400;

    Color color = isActive ? activeColor : inactiveColor;
    FontWeight fontWeight = isActive ? FontWeight.w500 : FontWeight.normal;

    if (isCurrent) {
      color = theme.primaryColorDark; // Destaque para o status atual
      fontWeight = FontWeight.bold;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, color: color, fontWeight: fontWeight, letterSpacing: 0.3),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          time ?? '--',
          style: TextStyle(fontSize: 13, color: color, fontWeight: fontWeight),
        ),
      ],
    );
  }

  // Widget para a linha conectora da timeline
  Widget _buildTimelineConnector(BuildContext context, {required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2.5, // Linha um pouco mais grossa
        color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300,
        margin: const EdgeInsets.symmetric(horizontal: 0.0), // Sem margem para conectar melhor
      ),
    );
  }

  Widget _buildVisualOrderStatusTimeline(BuildContext context, List<OrderStatusEvent> statusHistory) {
    final theme = Theme.of(context);

    final Map<EatsOrderStatus, Map<String, dynamic>> statusConfig = {
      EatsOrderStatus.pending: {'icon': Icons.flag_outlined, 'label': 'Realizado'},
      EatsOrderStatus.confirmed: {'icon': Icons.visibility_outlined, 'label': 'Visto'},
      EatsOrderStatus.preparing: {'icon': Icons.restaurant_menu_outlined, 'label': 'Preparo'},
      EatsOrderStatus.outForDelivery: {'icon': Icons.delivery_dining_outlined, 'label': 'Entrega'},
      EatsOrderStatus.delivered: {'icon': Icons.check_circle_outline_rounded, 'label': 'Entregue'},
    };

    final List<EatsOrderStatus> displayTimelineOrder = [
      EatsOrderStatus.pending,
      EatsOrderStatus.confirmed,
      EatsOrderStatus.preparing,
      EatsOrderStatus.outForDelivery,
      EatsOrderStatus.delivered,
    ];
    
    if (order.status == EatsOrderStatus.cancelledByStore || order.status == EatsOrderStatus.cancelledByUser || order.status == EatsOrderStatus.failed) {
        String statusText = "Pedido Cancelado";
        if(order.status == EatsOrderStatus.failed) statusText = "Falha no Pedido";
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Center(child: Text(statusText, style: TextStyle(color: Colors.red.shade700, fontSize: 17, fontWeight: FontWeight.bold))),
        );
    }

    Map<EatsOrderStatus, DateTime?> eventTimestamps = {};
    for (var status in displayTimelineOrder) {
      try {
        eventTimestamps[status] = statusHistory.lastWhere((e) => e.status == status).timestamp;
      } catch (e) {
        eventTimestamps[status] = null;
      }
    }
    if (statusHistory.isEmpty && order.status == EatsOrderStatus.pending) {
        eventTimestamps[EatsOrderStatus.pending] = order.orderDate;
    }

    List<Widget> timelineWidgets = [];
    int currentOrderStatusIndex = displayTimelineOrder.indexOf(order.status);
    if (currentOrderStatusIndex == -1 && order.status == EatsOrderStatus.delivered) {
        currentOrderStatusIndex = displayTimelineOrder.length -1; // Considera entregue como o último da lista
    }


    for (int i = 0; i < displayTimelineOrder.length; i++) {
      final statusEnum = displayTimelineOrder[i];
      final config = statusConfig[statusEnum]!;
      final time = eventTimestamps[statusEnum];

      bool isActive = false;
      if (currentOrderStatusIndex != -1) {
          isActive = i <= currentOrderStatusIndex;
      }
      // Se o pedido já foi entregue, todos os status anteriores devem ser ativos
      if (order.status == EatsOrderStatus.delivered) {
          isActive = true;
      }


      bool isCurrentNode = isActive && (i == currentOrderStatusIndex || (order.status == EatsOrderStatus.delivered && statusEnum == EatsOrderStatus.delivered) );

      timelineWidgets.add(
        _buildStatusTimelineNode(
          context,
          icon: config['icon'],
          label: config['label'],
          time: time != null ? _formatTime(time) : ( (statusEnum == EatsOrderStatus.pending && isActive) ? _formatTime(order.orderDate) : null),
          isActive: isActive,
          isCurrent: isCurrentNode,
          activeColor: theme.primaryColor,
        ),
      );

      if (i < displayTimelineOrder.length - 1) {
        // Linha ativa se o nó atual E o próximo estiverem ativos (ou o atual for o "currentOverall")
        bool lineIsActive = isActive && ( (currentOrderStatusIndex != -1 && i < currentOrderStatusIndex) || order.status == EatsOrderStatus.delivered) ;
        timelineWidgets.add(_buildTimelineConnector(context, isActive: lineIsActive));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinha os nós pela parte de cima
        children: timelineWidgets,
      ),
    );
  }


  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 28.0, bottom: 12.0), // Aumentado espaçamento
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith( // Um pouco menor que titleMedium
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.8, // Leve espaçamento entre letras
            ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isTotal = false, bool highlightValue = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5, // Ajustado
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14.5, // Ajustado
                color: highlightValue ? theme.primaryColorDark : Colors.black87,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String storeName = order.storeName;
    final String storeAddress = order.storeAddress ?? 'Endereço não informado';
    final String storePhoneNumber = order.storePhoneNumber ?? 'Contato não disponível';
    final String deliveryEstimateString = order.estimatedDeliveryTime != null
        ? "${_formatTime(order.estimatedDeliveryTime!)} (Estimativa)"
        : "não informada"; // Usando o fallback simples

    return Material(
      color: Colors.white,
      elevation: 0, // Sem elevação extra se já é modal
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0), // Bordas um pouco menos pronunciadas
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90, // 90% da tela
        ),
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container( // Handle
              width: 48,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Botão 'X' removido do corpo do BottomSheet
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 30.0), // Padding ajustado
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Text(
                        'seu pedido foi assim, ó:',
                        style: theme.textTheme.bodyLarge?.copyWith( // Ajustado para bodyLarge
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        '${_formatDate(order.orderDate)} - #${order.id.length > 7 ? order.id.substring(0,7) : order.id}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColorDark ?? theme.primaryColor,
                        ),
                      ),
                    ),
                    _buildVisualOrderStatusTimeline(context, order.statusHistory),
              
                    const Divider(height: 24, thickness: 0.8),
              
                    _buildSectionTitle(context, 'Detalhes do Pedido'),
                    if (order.items.isNotEmpty)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.items.length,
                        itemBuilder: (ctx, index) {
                          final cartItem = order.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${cartItem.quantity}x ${cartItem.product.name}',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(cartItem.totalPrice),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                if (cartItem.product.category.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 0, top: 4.0),
                                    child: Text('Categoria: ${cartItem.product.category}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                                  ),
                                if (cartItem.selectedAddons.isNotEmpty)
                                  ...cartItem.selectedAddons.map((addon) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 0, top: 3.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('+ ${addon.name}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                          Text('+ ${_formatCurrency(addon.price)}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                if (cartItem.observation != null && cartItem.observation!.isNotEmpty)
                                   Padding(
                                    padding: const EdgeInsets.only(left: 0, top: 3.0),
                                    child: Text('Obs: ${cartItem.observation}', style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade700, fontStyle: FontStyle.italic)),
                                  ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 18, thickness: 0.8),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: theme.cardColor, // Usar cor do card do tema
                        borderRadius: BorderRadius.circular(12.0), // Bordas mais suaves
                        border: Border.all(color: Colors.grey.shade200, width: 0.8)
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(context, 'Subtotal:', _formatCurrency(order.subtotal)),
                          _buildInfoRow(context, 'Entrega:', _formatCurrency(order.deliveryFee)),
                          if (order.serviceFee != null && order.serviceFee! > 0)
                            _buildInfoRow(context, 'Taxa de Conveniência:', _formatCurrency(order.serviceFee!)),
                          const Divider(height: 20, thickness: 0.5),
                          _buildInfoRow(context, 'Total:', _formatCurrency(order.totalAmount), isTotal: true, highlightValue: true),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 28, thickness: 0.8),
              
                    _buildSectionTitle(context, 'Entrega'),
                    Text(order.deliveryAddress.toString(), style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4)),
                    const SizedBox(height: 6),
                    Text('Previsão de entrega: $deliveryEstimateString', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
              
                    const Divider(height: 28, thickness: 0.8),
              
                    _buildSectionTitle(context, 'Pagamento'),
                    Text(order.paymentMethod, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                    if (order.paymentDetails != null && order.paymentDetails!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(order.paymentDetails!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                      ),
                    
                    const Divider(height: 28, thickness: 0.8),
              
                    _buildSectionTitle(context, 'Dados da Loja'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (order.storeLogoUrl != null && order.storeLogoUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(order.storeLogoUrl!, width: 56, height: 56, fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => Container(width: 56, height: 56, color: Colors.grey.shade200, child: Icon(Icons.storefront, size: 30, color: Colors.grey.shade400)),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(storeName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 3),
                              Text(storeAddress, style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.3)),
                              const SizedBox(height: 3),
                              Text(
                                'Tel: ${storePhoneNumber}', // Já tem fallback
                                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: Colors.black87, // COR PRETA para o botão
                            ),
                            onPressed: () {
                              if (order.storeId.isNotEmpty) {
      print("Navegando para detalhes da loja ID: ${order.storeId}");
      // Fecha o BottomSheet antes de navegar para a próxima tela
      Navigator.of(context).pop(); 
      Navigator.of(context).pushNamed(
        StoreDetailsScreen.routeName, // Certifique-se que este routeName está correto
        arguments: order.storeId, // Ou o objeto EatsStoreModel se sua tela de detalhes da loja o aceitar
      );
    } else {
      // Como não há 'await' antes desta linha, e o onPressed está sendo executado,
      // o 'context' aqui deve ser válido. A verificação 'mounted' não é necessária.
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID da loja não disponível para navegação.'))
      );
    }
  },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('IR PRA LOJA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.4)), // COR PRETA implícita
                                const SizedBox(width: 3),
                                Icon(Icons.arrow_forward_ios_rounded, size: 12), // COR PRETA implícita
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20), 
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}