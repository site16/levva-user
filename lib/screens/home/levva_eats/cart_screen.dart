// lib/screens/home/levva_eats/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necessário para SystemUiOverlayStyle
import 'package:levva/models/eats_store_model.dart';
import '../../../models/eats_cart_item_model.dart';
import '../../../globals/cart_data.dart';
import '../../../data/all_eats_stores.dart'; // Certifique-se que este import está correto e o arquivo existe
import './widgets/cart_list_item_widget.dart';
import './checkout_screen.dart';

class CartScreen extends StatefulWidget {
  static const routeName = '/levva-eats-cart';

  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  String? _appliedCoupon;
  double _couponDiscount = 0.0;

  double _parseDeliveryFee(String feeString) {
    if (feeString.trim().toLowerCase() == 'grátis') {
      return 0.0;
    }
    final cleanedString = feeString
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(cleanedString) ?? 5.0; // Taxa padrão se o parse falhar
  }

  double get _deliveryFee {
    if (globalCartItems.isEmpty) {
      return 0.0;
    }
    final String? currentStoreId = globalCartItems.first.product.storeId;

    if (currentStoreId == null) {
      print("Atenção: storeId não encontrado no produto do carrinho. Usando taxa de entrega padrão.");
      return 5.0;
    }

    // TODO: Idealmente, a lista de lojas (allEatsStores) deveria vir de um provider ou serviço,
    // não de um import de dados estáticos, para melhor manutenibilidade e teste.
    final store = allEatsStores.firstWhere(
      (s) => s.id == currentStoreId,
      orElse: () {
        print("Atenção: Loja com ID '$currentStoreId' não encontrada na lista allEatsStores. Usando taxa de entrega padrão.");
        // Retorna um modelo dummy para evitar crash, mas isso indica um problema de dados.
        return EatsStoreModel(
            id: 'fallback_store_id', // ID genérico
            name: 'Loja Desconhecida',
            type: 'Variada',
            logo: Icons.store_mall_directory, // Ícone de placeholder
            rating: 0.0,
            deliveryTimeEstimate: 'N/A',
            deliveryFee: 'R\$ 5.00', // Taxa padrão
            isOpen: false,
            // products: [], // Se o modelo exigir
            // bannerUrl: '', // Se o modelo exigir
            );
      },
    );
    return _parseDeliveryFee(store.deliveryFee);
  }

  double get _subtotal => globalCartItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get _total => (_subtotal - _couponDiscount) + _deliveryFee < 0 ? 0 : (_subtotal - _couponDiscount) + _deliveryFee;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _updateQuantityInGlobalCart(EatsCartItemModel cartItem, int change) {
    setState(() {
      final existingItemIndex = globalCartItems.indexWhere(
        (item) => item.product.id == cartItem.product.id &&
                  item.selectedAddons.map((a) => a.id).join(',') == cartItem.selectedAddons.map((a) => a.id).join(',')
      );
      if (existingItemIndex >= 0) {
        globalCartItems[existingItemIndex].quantity += change;
        if (globalCartItems[existingItemIndex].quantity <= 0) {
          globalCartItems.removeAt(existingItemIndex);
          if (globalCartItems.isEmpty) {
            _resetCoupon();
          }
        }
      }
    });
  }

  void _removeItemFromGlobalCart(EatsCartItemModel cartItem) {
    setState(() {
      globalCartItems.removeWhere(
        (item) => item.product.id == cartItem.product.id &&
                  item.selectedAddons.map((a) => a.id).join(',') == cartItem.selectedAddons.map((a) => a.id).join(',')
      );
      if (globalCartItems.isEmpty) {
        _resetCoupon();
      }
    });
  }

  Future<void> _showClearCartConfirmationDialog() async {
    // O context usado para showDialog é o da CartScreen.
    // Se CartScreen for desmontada enquanto o dialog está ativo, o _clearCart
    // (que usa o context da CartScreen) pode falhar.
    await showDialog<void>( // Não precisamos do resultado do dialog aqui
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) { // dialogContext é para o AlertDialog
        return AlertDialog(
          title: const Text('Esvaziar Ticket?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Todos os itens serão removidos do seu ticket.'),
                Text('Deseja continuar?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha o dialog
              },
            ),
            TextButton(
              child: const Text('Esvaziar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha o dialog PRIMEIRO
                _clearCart(); // DEPOIS chama _clearCart
              },
            ),
          ],
        );
      },
    );
    // Após o dialog fechar, se precisasse usar o context da CartScreen aqui,
    // uma verificação if (!mounted) return; seria necessária.
    // Neste caso, não há código após o await que use o context da CartScreen diretamente.
  }

  void _clearCart() {
    // VERIFICAÇÃO CRUCIAL: Garante que CartScreen ainda está montada
    if (!mounted) {
      print("CartScreen: Tentativa de chamar _clearCart em widget desmontado.");
      return;
    }
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Captura após a verificação

    setState(() {
      globalCartItems.clear();
      _resetCoupon();
    });

    // if (!mounted) return; // Não estritamente necessário aqui se já usarmos 'scaffoldMessenger'
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Ticket esvaziado!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _applyCoupon() {
    // VERIFICAÇÃO DE SEGURANÇA: Embora síncrono, protege contra cenários inesperados.
    if (!mounted) {
      print("CartScreen: Tentativa de chamar _applyCoupon em widget desmontado.");
      return;
    }
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Captura após a verificação

    final couponCode = _couponController.text.trim().toUpperCase();
    
    // setState já verifica 'mounted' internamente antes de chamar markNeedsBuild.
    // A preocupação é com o uso do context para ScaffoldMessenger dentro ou fora dele.
    setState(() {
      if (couponCode == 'LEVVAFREE10') {
        _appliedCoupon = couponCode;
        _couponDiscount = 10.0;
        // É mais seguro chamar o SnackBar fora do setState, após a verificação mounted,
        // mas como scaffoldMessenger foi capturado após uma verificação mounted, está OK.
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Cupom "$_appliedCoupon" aplicado com R\$10,00 de desconto!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (couponCode.isNotEmpty) {
        _appliedCoupon = null;
        _couponDiscount = 0.0;
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Cupom inválido ou expirado.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Por favor, insira um código de cupom.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    });
    _couponController.clear();
  }

  void _resetCoupon() {
    // setState é seguro.
    setState(() {
      _appliedCoupon = null;
      _couponDiscount = 0.0;
      _couponController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith( // Para ícones da status bar escuros
          statusBarColor: Colors.white, 
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        title: const Text(
          'Meu Ticket',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          if (globalCartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.black54),
              tooltip: 'Esvaziar Ticket',
              onPressed: _showClearCartConfirmationDialog, // Este método agora é async
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: globalCartItems.isEmpty
          ? Center( 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey.shade400),
                  const SizedBox(height: 20),
                  const Text('Seu ticket está vazio!', style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text('Adicione itens para continuar.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Volta para a tela anterior, que pode ser a lista de lojas ou detalhes da loja
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                      // Se não puder popar, pode ser necessário navegar para uma tela padrão,
                      // mas geralmente o carrinho é acessado de um local que permite 'pop'.
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                    child: const Text('Continuar comprando', style: TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            )
          : Column( 
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
                    itemCount: globalCartItems.length,
                    itemBuilder: (context, index) {
                      final item = globalCartItems[index];
                      return CartListItemWidget(
                        cartItem: item,
                        onQuantityChanged: (change) {
                          _updateQuantityInGlobalCart(item, change);
                        },
                        onRemoveItem: () {
                          _removeItemFromGlobalCart(item);
                        }
                      );
                    },
                  ),
                ),
                Padding( // Área do cupom
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 6.0, bottom: 6.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              decoration: InputDecoration(
                                hintText: 'Adicionar cupom',
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                              ),
                              style: const TextStyle(fontSize: 15),
                              textCapitalization: TextCapitalization.characters,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _applyCoupon,
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            ),
                            child: const Text('APLICAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container( // Área de resumo e checkout
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 0, blurRadius: 10, offset: const Offset(0, -5))],
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                          Text('R\$ ${_subtotal.toStringAsFixed(2).replaceAll('.', ',')}', style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      if (_couponDiscount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Desconto do Cupom (${_appliedCoupon ?? ''})', style: TextStyle(fontSize: 15, color: Colors.green.shade700)),
                            Text('- R\$ ${_couponDiscount.toStringAsFixed(2).replaceAll('.', ',')}', style: TextStyle(fontSize: 15, color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Taxa de entrega', style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                          Text(_deliveryFee > 0 ? 'R\$ ${_deliveryFee.toStringAsFixed(2).replaceAll('.', ',')}' : 'Grátis', style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const Divider(thickness: 0.8, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text('R\$ ${_total.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                            Navigator.of(context).pushNamed(CheckoutScreen.routeName, arguments: _total);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        ),
                        child: const Text('Continuar para Pagamento'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}