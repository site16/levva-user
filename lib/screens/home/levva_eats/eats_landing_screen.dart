// lib/screens/home/levva_eats/eats_landing_screen.dart
import 'package:flutter/material.dart';
import '../../home/home_screen.dart'; // << NOVO IMPORT

// Models
import '../../../models/eats_store_model.dart';

// Telas para navegação
import './store_list_screen.dart';
import './cart_screen.dart';
import './store_details_screen.dart';
import './favorite_stores_screen.dart';

class _CategoryChipData {
  final String id;
  final String name;
  _CategoryChipData({required this.id, required this.name});
}

class LevvaEatsLandingScreen extends StatefulWidget {
  static const routeName = '/levva-eats-landing';

  const LevvaEatsLandingScreen({super.key});

  @override
  State<LevvaEatsLandingScreen> createState() => _LevvaEatsLandingScreenState();
}

class _LevvaEatsLandingScreenState extends State<LevvaEatsLandingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryId = 'all';
  String _searchQuery = '';

  final List<_CategoryChipData> _categories = [
    _CategoryChipData(id: 'all', name: 'Todas'),
    _CategoryChipData(id: 'restaurantes', name: 'Restaurantes'),
    _CategoryChipData(id: 'farmacias', name: 'Farmácias'),
    _CategoryChipData(id: 'mercados', name: 'Mercados'),
    _CategoryChipData(id: 'petshops', name: 'Pet Shops'),
    _CategoryChipData(id: 'bebidas', name: 'Bebidas'),
    _CategoryChipData(id: 'padarias', name: 'Padarias'),
  ];

  final List<EatsStoreModel> _allStores = [
    EatsStoreModel(id: 's3', name: 'Sushi Imperial', logo: Icons.ramen_dining_outlined, type: 'Japonesa', rating: 4.9, deliveryTimeEstimate: '35-50 min', deliveryFee: 'R\$ 8,00', isOpen: true, imageUrl: 'https://via.placeholder.com/300x150/B2EBF2/000000?Text=Sushi+Banner', deliveryServiceInfo: 'Entrega Parceira'),
    EatsStoreModel(id: 's1', name: 'Pizzaria Forno Mágico', logo: Icons.local_pizza_outlined, type: 'Pizza', rating: 4.7, deliveryTimeEstimate: '25-40 min', deliveryFee: 'R\$ 4,50', isOpen: true, imageUrl: 'https://via.placeholder.com/300x150/FFCDD2/000000?Text=Pizza+Banner', deliveryServiceInfo: 'Entrega da Loja'),
    EatsStoreModel(id: 's5', name: 'Farmácia Saúde Já', logo: Icons.medical_services_outlined, type: 'Farmácia', rating: 4.6, deliveryTimeEstimate: '15-25 min', deliveryFee: 'R\$ 3,00', isOpen: true, imageUrl: null, deliveryServiceInfo: 'Entrega Expressa'),
    EatsStoreModel(id: 's2', name: 'Burger Supremo', logo: Icons.lunch_dining_outlined, type: 'Lanches', rating: 4.3, deliveryTimeEstimate: '20-30 min', deliveryFee: 'Grátis', isOpen: true, imageUrl: 'https://via.placeholder.com/300x150/F8BBD0/000000?Text=Burger+Banner', deliveryServiceInfo: 'Entrega e Retirada'),
    EatsStoreModel(id: 's4', name: 'Mercadinho da Vila', logo: Icons.store_mall_directory_outlined, type: 'Mercado', rating: 4.1, deliveryTimeEstimate: '30-40 min', deliveryFee: 'R\$ 6,00', isOpen: true, imageUrl: 'https://via.placeholder.com/300x150/C8E6C9/000000?Text=Market+Banner', deliveryServiceInfo: 'Retirada no Local'),
    EatsStoreModel(id: 's10', name: 'Pet Levva Shop', logo: Icons.pets_outlined, type: 'Pet Shops', rating: 4.6, deliveryTimeEstimate: '25-40 min', deliveryFee: 'R\$ 5,00', isOpen: false, imageUrl: null, deliveryServiceInfo: 'Entrega Agendada'),
  ];

  List<EatsStoreModel> get _filteredStores {
    List<EatsStoreModel> storesToShow;
    if (_selectedCategoryId == 'all') {
      storesToShow = List.from(_allStores);
    } else {
      storesToShow = _allStores.where((store) {
        final storeType = store.type.toLowerCase();
        final categoryToSearch = _selectedCategoryId.toLowerCase()
            .replaceAll('ç', 'c').replaceAll('á', 'a').replaceAll('ó', 'o').replaceAll('ê', 'e');
        if (_selectedCategoryId == "restaurantes") {
            return ['pizza', 'lanches', 'japonesa', 'açaí', 'padaria', 'hamburgueria'].contains(storeType);
        }
        return storeType.contains(categoryToSearch);
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      storesToShow = storesToShow.where((store) {
        return store.name.toLowerCase().contains(queryLower) ||
               store.type.toLowerCase().contains(queryLower);
      }).toList();
    }

    storesToShow.sort((a, b) {
      if (a.isOpen && !b.isOpen) return -1;
      if (!a.isOpen && b.isOpen) return 1;
      return b.rating.compareTo(a.rating);
    });
    return storesToShow;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildCategoryChip(_CategoryChipData category) {
    // ... (código do _buildCategoryChip inalterado)
    bool isSelected = category.id == _selectedCategoryId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(category.name),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() { _selectedCategoryId = category.id; });
          }
        },
        backgroundColor: Colors.grey.shade100,
        selectedColor: Colors.black,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: isSelected ? Colors.black : Colors.grey.shade300)
        ),
        elevation: 0.5,
        pressElevation: 2.0,
      ),
    );
  }

  Widget _buildStoreListItem(EatsStoreModel store) {
    // ... (código do _buildStoreListItem inalterado)
    final bool isOpen = store.isOpen;
    final double itemOpacity = isOpen ? 1.0 : 0.6;
    final Color statusColor = isOpen ? Colors.green.shade700 : Colors.red.shade700;
    final String statusText = isOpen ? "Aberto agora" : "Fechado";
    final bool hasValidNetworkImage = store.imageUrl != null && store.imageUrl!.isNotEmpty && store.imageUrl!.startsWith('http');
    Widget imageDisplay;

    if (hasValidNetworkImage) {
      imageDisplay = ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          store.imageUrl!, width: 60, height: 60, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(store.logo, size: 30, color: Colors.grey.shade600),
          loadingBuilder: (context, child, progress) => progress == null ? child : Container(width: 60, height: 60, alignment:Alignment.center, child: CircularProgressIndicator(strokeWidth: 2, value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null)),
        ),
      );
    } else {
      imageDisplay = Icon(store.logo, size: 30, color: Colors.grey.shade700);
    }

    return Opacity(
      opacity: itemOpacity,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12.0),
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: Colors.grey.shade200, width: 0.8)
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: isOpen ? () {
            Navigator.of(context).pushNamed(StoreDetailsScreen.routeName, arguments: store);
          } : () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${store.name} está fechada no momento.')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(child: imageDisplay),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(store.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                              const SizedBox(width: 3),
                              Text(store.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(store.type, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${store.deliveryTimeEstimate} • ${store.deliveryFee}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              // Se não puder "voltar" na pilha (ex: LevvaEatsLanding é a raiz),
              // navega para a HomeScreen como um fallback seguro, limpando a pilha atual.
              Navigator.of(context).pushNamedAndRemoveUntil(
                HomeScreen.routeName,
                (route) => false, // Remove todas as rotas antes de ir para HomeScreen
              );
            }
          },
          tooltip: 'Voltar',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline_rounded, color: Colors.black54, size: 26),
            tooltip: 'Lojas Favoritas',
            onPressed: () {
              Navigator.of(context).pushNamed(FavoriteStoresScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87, size: 26),
            tooltip: 'Carrinho',
            onPressed: () {
              Navigator.of(context).pushNamed(CartScreen.routeName);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NestedScrollView(
        // ... (restante do body inalterado) ...
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                child: Column(
                  children: [
                    const Center(
                      child: Text(
                        'LEVVA EATS',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar em LEVVA EATS...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.0)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide(color: theme.primaryColorDark, width: 1.5)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() { _searchQuery = ''; });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() { _searchQuery = value; });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryChip(_categories[index]);
                  },
                ),
              ),
            ),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
          ];
        },
        body: _filteredStores.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'Nenhuma loja encontrada para "$_searchQuery".'
                        : (_selectedCategoryId != 'all'
                            ? 'Nenhuma loja encontrada na categoria "${_categories.firstWhere((c) => c.id == _selectedCategoryId).name}".'
                            : 'Nenhuma loja para exibir no momento.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                itemCount: _filteredStores.length,
                itemBuilder: (context, index) {
                  return _buildStoreListItem(_filteredStores[index]);
                },
              ),
      ),
    );
  }
}