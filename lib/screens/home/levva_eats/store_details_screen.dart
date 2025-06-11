import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Ajuste os caminhos dos imports
import '../../../models/eats_store_model.dart';
import '../../../models/eats_product_model.dart';
import '../../../models/eats_addon_model.dart';
import '../../../globals/cart_data.dart';
import '../../../utils/favorite_service.dart';
import './widgets/product_list_item_widget.dart';
import './widgets/product_details_bottom_sheet.dart';
import './cart_screen.dart';
import './widgets/store_profile_header.dart'; // <- Novo import do header customizado!

class StoreDetailsScreen extends StatefulWidget {
  static const routeName = '/levva-eats-store-details';
  final EatsStoreModel store;

  const StoreDetailsScreen({super.key, required this.store});

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  List<EatsProductModel> _products = [];
  Map<String, List<EatsProductModel>> _categorizedProducts = {};
  List<String> _productCategories = [];
  String? _selectedProductCategoryName;
  bool _showTicketButton = false;
  bool _isFavorited = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Dados para o header: só distância e rating
  final double _distanceKm = 2.2;

  @override
  void initState() {
    super.initState();
    _loadAndCategorizeProducts();
    if (_productCategories.isNotEmpty) {
      _selectedProductCategoryName = _productCategories.first;
    }
    _updateTicketButtonVisibility();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    bool isFav = await FavoriteService.isFavorite(widget.store.id);
    if (mounted) {
      setState(() {
        _isFavorited = isFav;
      });
    }
  }

  void _loadAndCategorizeProducts() {
    _products = [
      EatsProductModel(
        id: 'p1',
        storeId: widget.store.id,
        storeName: widget.store.name,
        name: 'Lanche Clássico da Casa',
        description: 'Pão, carne, queijo e salada.',
        price: 25.90,
        imageUrl: 'https://via.placeholder.com/100/FFF9C4/000000?Text=Lanche',
        category: 'Lanches',
        addons: [EatsAddonModel(id: 'a1', name: 'Bacon', price: 3.0)]
      ),
      EatsProductModel(
        id: 'p2',
        storeId: widget.store.id,
        storeName: widget.store.name,
        name: 'Batata Canoa',
        description: 'Porção individual.',
        price: 12.50,
        imageUrl: 'https://via.placeholder.com/100/FFECB3/000000?Text=Fritas',
        category: 'Porções'
      ),
      EatsProductModel(
        id: 'p3',
        storeId: widget.store.id,
        storeName: widget.store.name,
        name: 'Pizza Média Pepperoni',
        description: 'Molho, queijo e pepperoni.',
        price: 42.00,
        imageUrl: 'https://via.placeholder.com/100/FFCDD2/000000?Text=Pizza',
        category: 'Pizzas'
      ),
      EatsProductModel(
        id: 'p4',
        storeId: widget.store.id,
        storeName: widget.store.name,
        name: 'Suco de Laranja 500ml',
        description: 'Natural, feito na hora.',
        price: 9.00,
        imageUrl: null,
        category: 'Bebidas'
      ),
      EatsProductModel(
        id: 'p5',
        storeId: widget.store.id,
        storeName: widget.store.name,
        name: 'Petit Gateau',
        description: 'Com sorvete de creme.',
        price: 18.00,
        imageUrl: 'https://via.placeholder.com/100/D7CCC8/000000?Text=Sobremesa',
        category: 'Sobremesas'
      ),
    ];

    _categorizedProducts = {};
    _productCategories = [];
    for (var product in _products) {
      if (!_categorizedProducts.containsKey(product.category)) {
        _categorizedProducts[product.category] = [];
        if (!_productCategories.contains(product.category)) _productCategories.add(product.category);
      }
      _categorizedProducts[product.category]!.add(product);
    }
    _productCategories.sort((String a, String b) {
      if (a == 'Promoções') return -1;
      if (b == 'Promoções') return 1;
      return a.compareTo(b);
    });
  }

  List<EatsProductModel> get _currentCategoryProducts {
    if (_selectedProductCategoryName == null) return [];
    return _categorizedProducts[_selectedProductCategoryName!] ?? [];
  }

  void _updateTicketButtonVisibility() {
    if (mounted) {
      final bool shouldShow = globalCartItems.any((item) => item.product.storeId == widget.store.id);
      if (_showTicketButton != shouldShow) {
        setState(() { _showTicketButton = shouldShow; });
      }
    }
  }

  int get _cartUniqueItemCount {
    return globalCartItems.where((item) => item.product.storeId == widget.store.id).length;
  }

  double get _cartTotalPrice {
    // Aqui garante o cálculo correto: preço base + addons, tudo multiplicado pela quantidade do item
    return globalCartItems
        .where((item) => item.product.storeId == widget.store.id)
        .fold(0.0, (sum, item) {
          // Soma o preço base do produto
          double itemTotal = item.product.price;
          // Soma o valor dos addons, se houver
          if(item.selectedAddons.isNotEmpty) {
            itemTotal += item.selectedAddons.fold(0.0, (addonSum, addon) => addonSum + addon.price);
          }
          // Multiplica pelo quantity
          return sum + (itemTotal * item.quantity);
        });
  }

  Future<void> _toggleFavorite() async {
    bool newFavoriteState = await FavoriteService.toggleFavoriteStatus(widget.store.id);
    if (mounted) {
      setState(() {
        _isFavorited = newFavoriteState;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorited ? '${widget.store.name} adicionado aos favoritos!' : '${widget.store.name} removido dos favoritos.'),
        duration: const Duration(seconds: 1),
        backgroundColor: _isFavorited ? Colors.pinkAccent.shade100 : Colors.grey.shade700,
      ),
    );
  }

  Widget _buildProductCategoryChip(String categoryName) {
    bool isSelected = categoryName == _selectedProductCategoryName;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(categoryName),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() { _selectedProductCategoryName = categoryName; });
          }
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.black,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0), side: BorderSide(color: isSelected ? Colors.black : Colors.grey.shade300)),
        elevation: isSelected ? 2.0 : 0.5,
        selectedShadowColor: Colors.black38,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Para banner cobrir atrás da AppBar!
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar transparente
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_outlined,
              color: Colors.black87, // Ícone preto!
              size: 26,
            ),
            tooltip: _isFavorited ? 'Desfavoritar Loja' : 'Favoritar Loja',
            onPressed: _toggleFavorite,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          // Aqui pode futuramente implementar fade/blur na AppBar ao rolar (opcional)
          return false;
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            StoreProfileHeader(
              store: widget.store,
              distanceKm: _distanceKm,
              // Não passa minOrder, reviewCount, level, levelMax!
              deliveryTimeEstimate: widget.store.deliveryTimeEstimate,
              deliveryFee: widget.store.deliveryFee,
            ),
            if (_productCategories.isNotEmpty)
              Container(
                height: 60,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: _productCategories.length,
                  itemBuilder: (context, index) {
                    return _buildProductCategoryChip(_productCategories[index]);
                  },
                ),
              ),

            if (_selectedProductCategoryName != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0, bottom: 4.0),
                child: Text(
                  _selectedProductCategoryName!,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),

            if (_currentCategoryProducts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _selectedProductCategoryName == null || _categorizedProducts[_selectedProductCategoryName!] == null || _categorizedProducts[_selectedProductCategoryName!]!.isEmpty
                        ? 'Nenhum produto nesta categoria.'
                        : 'Carregando produtos...',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, _showTicketButton ? 80.0 : 16.0),
                itemCount: _currentCategoryProducts.length,
                itemBuilder: (context, index) {
                  final product = _currentCategoryProducts[index];
                  return ProductListItemWidget(
                    product: product,
                    onTap: () async {
                      final itemAdded = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                        ),
                        builder: (BuildContext btmSheetCTX) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(btmSheetCTX).viewInsets.bottom),
                            child: ProductDetailsBottomSheet(product: product),
                          );
                        },
                      );

                      if (itemAdded != null && mounted) {
                        _updateTicketButtonVisibility();
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _showTicketButton
          ? GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(CartScreen.routeName).then((_) {
                  _updateTicketButtonVisibility();
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6,offset: const Offset(0, 3)) ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 6),
                        Text(_cartUniqueItemCount.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const Text('VER TICKET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(_currencyFormat.format(_cartTotalPrice), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}