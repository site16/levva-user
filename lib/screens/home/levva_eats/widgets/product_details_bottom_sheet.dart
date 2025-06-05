// lib/screens/home/levva_eats/widgets/product_details_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:levva/globals/cart_data.dart'; // Importar a lista global do carrinho
import 'package:levva/models/eats_addon_model.dart';
import 'package:levva/models/eats_cart_item_model.dart';
import 'package:levva/models/eats_product_model.dart';

class ProductDetailsBottomSheet extends StatefulWidget {
  final EatsProductModel product;

  const ProductDetailsBottomSheet({super.key, required this.product});

  @override
  State<ProductDetailsBottomSheet> createState() => _ProductDetailsBottomSheetState();
}

class _ProductDetailsBottomSheetState extends State<ProductDetailsBottomSheet> {
  int _quantity = 1;
  final TextEditingController _observationController = TextEditingController();
  late Map<String, bool> _selectedAddonsMap;
  double _currentAddonsPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedAddonsMap = {
      if (widget.product.addons != null)
        for (var addon in widget.product.addons!) addon.id: false,
    };
    _calculateAddonsPrice();
  }

  void _incrementQuantity() {
    setState(() { _quantity++; });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() { _quantity--; });
    }
  }

  void _toggleAddon(String addonId) {
    setState(() {
      _selectedAddonsMap[addonId] = !_selectedAddonsMap[addonId]!;
      _calculateAddonsPrice();
    });
  }

  void _calculateAddonsPrice() {
    _currentAddonsPrice = 0.0;
    if (widget.product.addons != null) {
      for (var addon in widget.product.addons!) {
        if (_selectedAddonsMap[addon.id] == true) {
          _currentAddonsPrice += addon.price;
        }
      }
    }
  }

  double get _totalItemPrice => (widget.product.price + _currentAddonsPrice) * _quantity;

  // --- MÉTODO _handleAddToCart ATUALIZADO ---
  // Agora não mostra SnackBar e apenas chama Navigator.pop com um resultado booleano.
  Future<void> _handleAddToCart() async {
    if (!mounted) {
      print("ProductDetailsBottomSheet: _handleAddToCart no início, mas widget não montado.");
      // Não podemos chamar Navigator.pop se não estiver montado e o context for inválido.
      // O chamador de showModalBottomSheet terá que lidar com o fato de que o Future não resolveu com um valor específico.
      return;
    }
    // Usar rootNavigator: true é geralmente mais seguro para fechar rotas modais como BottomSheets.
    final navigator = Navigator.of(context, rootNavigator: true);

    final String newProductStoreId = widget.product.storeId;
    String? currentCartStoreId;

    if (globalCartItems.isNotEmpty) {
      currentCartStoreId = globalCartItems.first.product.storeId;
    }

    bool itemSuccessfullyProcessed = false;

    // Se o carrinho não está vazio E o ID da loja do novo produto é diferente
    if (currentCartStoreId != null && newProductStoreId != currentCartStoreId) {
      final bool? replaceCartConfirmed = await showDialog<bool>(
        context: context, // Contexto do State para mostrar o dialog
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Iniciar Novo Ticket?'),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Seu ticket atual contém itens de outra loja.'),
                  Text('Deseja esvaziar o ticket atual e adicionar este novo item?'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                onPressed: () {
                  Navigator.of(dialogContext).pop(false); // Dialog retorna false
                },
              ),
              TextButton(
                child: Text('Esvaziar e Adicionar', style: TextStyle(color: Theme.of(context).primaryColorDark)),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true); // Dialog retorna true
                },
              ),
            ],
          );
        },
      );

      if (!mounted) { // Re-verifica após o await do dialog
        print("ProductDetailsBottomSheet: Widget desmontado após showDialog.");
        return; // Não podemos chamar pop se desmontado.
      }

      if (replaceCartConfirmed == true) {
        globalCartItems.clear();
        // Prossiga para adicionar o item (lógica abaixo)
      } else {
        // Usuário cancelou a substituição do carrinho.
        print("ProductDetailsBottomSheet: Usuário cancelou substituição do carrinho. Fechando com false.");
        navigator.pop(false); // Fecha o BottomSheet, indicando que a adição não ocorreu como esperado.
        return;
      }
    }

    // Lógica para adicionar ou atualizar item no carrinho
    // (ocorre se o carrinho estava vazio, ou é da mesma loja, ou o usuário confirmou esvaziar)
    List<EatsAddonModel> currentlySelectedAddonsList = [];
    if (widget.product.addons != null) {
      for (var addon in widget.product.addons!) {
        if (_selectedAddonsMap[addon.id] == true) {
          currentlySelectedAddonsList.add(addon);
        }
      }
    }

    int existingItemIndex = globalCartItems.indexWhere(
      (item) => item.isSameItemAs(widget.product, currentlySelectedAddonsList)
    );

    if (existingItemIndex != -1) {
      globalCartItems[existingItemIndex].quantity += _quantity;
    } else {
      final newCartItem = EatsCartItemModel(
        product: widget.product,
        quantity: _quantity,
        selectedAddons: currentlySelectedAddonsList,
        observation: _observationController.text.trim().isNotEmpty
            ? _observationController.text.trim()
            : null,
      );
      globalCartItems.add(newCartItem);
    }
    itemSuccessfullyProcessed = true; // Marca que o item foi processado no carrinho

    // Pop final do BottomSheet
    if (!mounted) {
      print("ProductDetailsBottomSheet: Widget desmontado antes do pop final.");
      return;
    }

    if (itemSuccessfullyProcessed) {
      print("ProductDetailsBottomSheet: Item adicionado/modificado. Fechando com true.");
      navigator.pop(true); // Fecha o BottomSheet, indicando sucesso na operação do carrinho
    } else {
      // Este 'else' é para cobrir cenários onde o item não foi processado
      // e o fluxo não retornou antes (o que não deveria acontecer com a lógica atual).
      print("ProductDetailsBottomSheet: Nenhuma modificação no carrinho (caminho inesperado). Fechando com false.");
      navigator.pop(false); // Fecha o BottomSheet, indicando falha ou nenhuma ação.
    }
  }
  // --- FIM DO MÉTODO _handleAddToCart ATUALIZADO ---

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAddons = widget.product.addons != null && widget.product.addons!.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Container(
              width: 40, height: 5, margin: const EdgeInsets.only(bottom: 12.0),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          Text(widget.product.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.product.description, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
          const SizedBox(height: 16),

          if (hasAddons) ...[
            Text('Adicionais', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.product.addons!.length,
              itemBuilder: (context, index) {
                final addon = widget.product.addons![index];
                return CheckboxListTile(
                  title: Text(addon.name),
                  secondary: Text('+ R\$ ${addon.price.toStringAsFixed(2).replaceAll('.', ',')}'),
                  value: _selectedAddonsMap[addon.id],
                  onChanged: (bool? value) { _toggleAddon(addon.id); },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: theme.primaryColorDark,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
            const Divider(height: 24),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quantidade', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              Row(
                children: <Widget>[
                  IconButton(icon: Icon(Icons.remove_circle_outline, color: _quantity > 1 ? theme.primaryColorDark : Colors.grey, size: 28), onPressed: _decrementQuantity),
                  Text('$_quantity', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: Icon(Icons.add_circle_outline, color: theme.primaryColorDark, size: 28), onPressed: _incrementQuantity),
                ],
              ),
            ],
          ),
          const Divider(height: 24),

          Text('Observações', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _observationController,
            decoration: InputDecoration(
              hintText: 'Ex: Sem cebola, ponto da carne...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              filled: true, fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 3, textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _handleAddToCart, // Chama o método atualizado
            child: Text('Por no ticket • R\$ ${_totalItemPrice.toStringAsFixed(2).replaceAll('.', ',')}'),
          ),
        ],
      ),
    );
  }
}