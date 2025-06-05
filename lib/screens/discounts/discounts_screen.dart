import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para SystemUiOverlayStyle
import 'package:provider/provider.dart';
import '../../models/discount_model.dart';
import '../../providers/discount_provider.dart';
import '../../widgets/discount_card.dart'; // Certifique-se que este widget está estilizado conforme a imagem

class DiscountsScreen extends StatefulWidget {
  static const routeName = '/discounts';
  const DiscountsScreen({super.key});

  @override
  State<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends State<DiscountsScreen> {
  // _tabController e SingleTickerProviderStateMixin removidos pois não há mais abas

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DiscountProvider>(context, listen: false);
      // Carrega todos os descontos, já que não há mais abas para separar
      // Você pode querer filtrar por "disponíveis" aqui se o provider tiver essa lógica
      if (provider.allDiscounts.isEmpty && !provider.isLoading && provider.errorMessage == null) {
        provider.fetchDiscounts();
      }
    });
  }

  // dispose não precisa mais do _tabController.dispose()

  void _applyCouponToRide(BuildContext context, DiscountModel discount) {
    // A lógica original de aplicar cupom pode ser mantida ou ajustada
    // Esta função é chamada pelo DiscountCard
    print('Aplicando cupom: ${discount.code}');
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cupom "${discount.code}" selecionado!'), // Ou "aplicado" se a ação for imediata
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
    // Adicionalmente, você pode querer:
    // Provider.of<RideRequestProvider>(context, listen: false).applyDiscount(discount);
    // Navigator.of(context).pop(); // Voltar para a tela anterior após aplicar
  }

  Widget _buildDiscountListContent(
    BuildContext context,
    DiscountProvider discountProvider,
  ) {
    final theme = Theme.of(context);
    // Vamos exibir todos os descontos ou apenas os disponíveis?
    // Para este exemplo, usarei availableDiscounts. Adapte se necessário.
    final List<DiscountModel> discountsToDisplay = discountProvider.availableDiscounts;

    if (discountProvider.isLoading && discountsToDisplay.isEmpty) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor));
    }

    if (discountProvider.errorMessage != null && discountsToDisplay.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
              const SizedBox(height: 16),
              Text(
                discountProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent.shade700, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Tentar Novamente'),
                onPressed: () => discountProvider.fetchDiscounts(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor, // Botão com cor primária
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (discountsToDisplay.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 60,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "Nenhum desconto disponível", // Mensagem ajustada
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Fique de olho! Novas promoções e descontos aparecerão aqui em breve.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // A lista de descontos
    return ListView.builder(
      padding: const EdgeInsets.all(16.0), // Padding ao redor da lista
      itemCount: discountsToDisplay.length,
      itemBuilder: (ctx, index) {
        final discount = discountsToDisplay[index];
        // O DiscountCard precisa ser estilizado para corresponder à imagem:
        // - Fundo branco
        // - Sombra sutil
        // - Cantos arredondados
        // - Ícone à esquerda
        // - Título do desconto e validade
        // - Botão "Aplicar" preto com texto branco à direita
        return DiscountCard(
          discount: discount,
          isAvailable: discount.isValidNow, // Ajuste a lógica de disponibilidade se necessário
          onApply: (discount.isValidNow)
              ? () => _applyCouponToRide(context, discount)
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final discountProvider = Provider.of<DiscountProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100], // Fundo cinza claro para a tela
      appBar: AppBar(
        leading: IconButton( // Botão de voltar personalizado para "< Voltar"
          icon: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_new_rounded, size: 20), // Ícone de voltar
              SizedBox(width: 0), // Ajuste se precisar de espaço entre ícone e texto
              // Text("Voltar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        leadingWidth: 70, // Ajuste a largura do leading para caber o texto se adicionar
        title: const Text(
          'Meus Descontos',
          style: TextStyle(
            color: Colors.black87, // Cor do título
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true, // Centraliza o título
        backgroundColor: Colors.white, // Fundo branco para a AppBar
        elevation: 0.8, // Sombra sutil abaixo da AppBar
        scrolledUnderElevation: 1.0,
        iconTheme: IconThemeData(color: Colors.black87), // Cor dos ícones da AppBar (ex: voltar)
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith( // Ícones da barra de status escuros
          statusBarColor: Colors.transparent,
        ),
        // actions: [] // Ícone de filtro removido, então actions fica vazio ou é omitido
      ),
      body: RefreshIndicator(
        onRefresh: () => discountProvider.fetchDiscounts(),
        color: theme.primaryColor, // Cor do indicador de refresh
        child: _buildDiscountListContent(context, discountProvider),
      ),
    );
  }
}