// lib/screens/home/levva_eats/order_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Import do Lottie
import '../../../globals/cart_data.dart';
// Ajuste o import abaixo para o arquivo correto da sua tela de Pedidos Eats, se necessário
import '../../orders/orders_screen.dart'; // Usado para EatsOrdersScreen.routeName
import './eats_landing_screen.dart';     // Usado por _exitConfirmationScreen
import '../../home/home_screen.dart';      // Usado para ModalRoute.withName

class OrderConfirmationScreen extends StatefulWidget {
  static const routeName = '/levva-eats-order-confirmation';
  final Map<String, dynamic> orderDetails;

  const OrderConfirmationScreen({super.key, required this.orderDetails});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

// Removido 'with SingleTickerProviderStateMixin' pois o AnimationController do Flutter não será mais usado aqui.
class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  // AnimationController, _scaleAnimation, e _fadeAnimation foram removidos.

  @override
  void initState() {
    super.initState();
    // Lógica para limpar o carrinho ao entrar na tela, se desejar,
    // mas já é feito antes de navegar para cá ou ao sair daqui.
    // globalCartItems.clear();
  }

  @override
  void dispose() {
    // Não há AnimationController do Flutter para dispensar.
    super.dispose();
  }

  // Método para o botão 'X' da AppBar
  void _exitConfirmationScreen() {
    // Limpa o carrinho ao sair por este botão
    globalCartItems.clear();

    // Navega para a LevvaEatsLandingScreen, mantendo HomeScreen na pilha
    // Isso permite que o usuário volte para a HomeScreen a partir da Landing do Eats.
    if (mounted) { // Adiciona verificação 'mounted' por segurança
      Navigator.of(context).pushNamedAndRemoveUntil(
        LevvaEatsLandingScreen.routeName,
        ModalRoute.withName(HomeScreen.routeName),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storeName = widget.orderDetails['storeName'] as String? ?? 'Loja Desconhecida';
    final deliveryTimeEstimate = widget.orderDetails['deliveryTimeEstimate'] as String? ?? 'não informada';
    // TODO: Você precisará adicionar 'storePhoneNumber' aos seus orderDetails
    final storePhoneNumber = widget.orderDetails['storePhoneNumber'] as String? ?? 'não disponível';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'UuHuul, deu certo !', // <<< TÍTULO ATUALIZADO
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true, // <<< TÍTULO CENTRALIZADO
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove o botão de voltar padrão
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87, size: 28), // Ícone 'X'
            tooltip: 'Fechar e Voltar ao Início do Eats',
            onPressed: _exitConfirmationScreen, // Ação de fechar
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Estica o botão no final
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200, // <<< TAMANHO DA ANIMAÇÃO AUMENTADO
                    height: 200,
                    child: Lottie.asset(
                      'assets/animations/confirmed.json', // Caminho para seu arquivo JSON
                      repeat: false, // Garante que a animação toque apenas uma vez e pare
                    ),
                  ),
                  const SizedBox(height: 32), // Espaçamento aumentado
                  Text(
                    'Seu pedido para "$storeName" foi feito!', // <<< TEXTO ATUALIZADO
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, // Tamanho de fonte ajustado
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A previsão de entrega é ${deliveryTimeEstimate.toLowerCase()}.', // <<< TEXTO ATUALIZADO
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Se caso acontecer algum imprevisto, avise a loja: ${storePhoneNumber == "não disponível" || storePhoneNumber.isEmpty ? "contato não disponível" : storePhoneNumber }.', // <<< TEXTO ATUALIZADO
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            // Espaço antes do botão para empurrá-lo para baixo se não usar Spacer antes
            // const Spacer(), // Removido Spacer para usar Expanded na Column acima

            // Botão "Acompanhar Pedido"
            ElevatedButton(
              onPressed: () {
                globalCartItems.clear(); // Limpa o carrinho
                // Navega para a tela de Pedidos (EatsOrdersScreen), mantendo HomeScreen na pilha
                if (mounted) { // Adiciona verificação 'mounted'
                   Navigator.of(context).pushNamedAndRemoveUntil(
                    EatsOrdersScreen.routeName, // Use a rota correta para sua tela de pedidos Eats
                    ModalRoute.withName(HomeScreen.routeName),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)), // Bordas mais arredondadas
              ),
              child: const Text('Acompanhar Pedido'),
            ),
            const SizedBox(height: 16), // Margem inferior para o botão
          ],
        ),
      ),
    );
  }
}