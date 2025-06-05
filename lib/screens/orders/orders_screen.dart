// lib/screens/eats_orders/eats_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// Removido 'package:intl/intl.dart;' pois não está sendo usado diretamente aqui.
// Se EatsOrderItemCard precisar, ele deve importar.

import '../../providers/eats_orders_provider.dart';
import '../../models/eats_order_model.dart';
import '../../widgets/eats_order_item_card.dart'; // Seu card de item de pedido
import '../home/home_screen.dart'; // Import para HomeScreen.routeName

// <<< NOVO IMPORT para o BottomSheet de Detalhes do Pedido >>>
// Ajuste o caminho se o seu EatsOrderDetailBottomSheet estiver em um local diferente
import './widgets/eats_order_detail_bottom_sheet.dart';

class EatsOrdersScreen extends StatefulWidget {
  static const routeName = '/eats-orders';
  const EatsOrdersScreen({super.key});

  @override
  State<EatsOrdersScreen> createState() => _EatsOrdersScreenState();
}

class _EatsOrdersScreenState extends State<EatsOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EatsOrdersProvider>(context, listen: false);
      if (provider.eatsOrders.isEmpty && !provider.isLoading && provider.errorMessage == null) {
        provider.fetchEatsOrders();
      }
    });
  }

  Future<void> _refreshEatsOrders(BuildContext context) async {
    await Provider.of<EatsOrdersProvider>(context, listen: false).fetchEatsOrders();
  }

  // Função para mostrar o BottomSheet de detalhes do pedido
  void _showOrderDetailSheet(BuildContext context, EatsOrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o bottom sheet seja mais alto
      backgroundColor: Colors.transparent, // Para que o borderRadius do nosso Container no BottomSheet funcione
      builder: (bCtx) {
        return EatsOrderDetailBottomSheet(order: order);
      },
    );
  }

  Widget _buildStatePlaceholder(BuildContext context, {required IconData icon, required String message, String? buttonText, VoidCallback? onButtonPressed}) {
    // ... (seu método _buildStatePlaceholder como antes)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Text(buttonText),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eatsOrdersProvider = Provider.of<EatsOrdersProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                HomeScreen.routeName, // Certifique-se que HomeScreen.routeName está correto
                (route) => false,
              );
            }
          },
        ),
        title: const Text(
          'Meus Pedidos Eats',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1.0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.white,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshEatsOrders(context),
        color: Colors.black,
        child: Builder(
          builder: (context) {
            if (eatsOrdersProvider.isLoading && eatsOrdersProvider.eatsOrders.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Colors.black));
            }
            
            if (eatsOrdersProvider.errorMessage != null && eatsOrdersProvider.eatsOrders.isEmpty) {
              return _buildStatePlaceholder(
                context,
                icon: Icons.error_outline_rounded,
                message: eatsOrdersProvider.errorMessage ?? "Ocorreu um erro ao buscar seus pedidos.",
                buttonText: "Tentar Novamente",
                onButtonPressed: () => _refreshEatsOrders(context),
              );
            }
            
            if (eatsOrdersProvider.eatsOrders.isEmpty && !eatsOrdersProvider.isLoading) {
              return _buildStatePlaceholder(
                context,
                icon: Icons.receipt_long_outlined,
                message: "Você ainda não fez nenhum pedido no Levva Eats.",
              );
            }
            
            // Esta condição é provavelmente redundante por causa da primeira condição de loading
            // if (eatsOrdersProvider.eatsOrders.isEmpty && eatsOrdersProvider.isLoading) {
            //     return const Center(child: CircularProgressIndicator(color: Colors.black));
            // }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
              itemCount: eatsOrdersProvider.eatsOrders.length,
              itemBuilder: (ctx, index) {
                final order = eatsOrdersProvider.eatsOrders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: EatsOrderItemCard(
                    order: order,
                    onTap: () {
                      // <<< AÇÃO ATUALIZADA AO TOCAR NO ITEM >>>
                      print("Exibindo detalhes para o pedido ID: ${order.id}");
                      _showOrderDetailSheet(context, order);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}