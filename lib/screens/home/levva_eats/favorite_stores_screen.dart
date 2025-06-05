// lib/screens/home/levva_eats/favorite_stores_screen.dart
import 'package:flutter/material.dart';
// Ajuste os caminhos dos imports conforme sua estrutura
import '../../../models/eats_store_model.dart';
import '../../../utils/favorite_service.dart';
import '../../../data/all_eats_stores.dart';    // Nossa lista mestra de lojas
import './widgets/store_list_item_widget.dart'; // Para exibir cada loja
import './store_details_screen.dart';         // Para navegar para os detalhes da loja

// IMPORTS PARA O CARROSSEL
import '../../../widgets/promotional_carousel_widget.dart'; // Ajuste o caminho se necessário
import '../../../models/carousel_item_data.dart';      // Ajuste o caminho se necessário

class FavoriteStoresScreen extends StatefulWidget {
  static const routeName = '/levva-eats-favorites';

  const FavoriteStoresScreen({super.key});

  @override
  State<FavoriteStoresScreen> createState() => _FavoriteStoresScreenState();
}

class _FavoriteStoresScreenState extends State<FavoriteStoresScreen> {
  List<EatsStoreModel> _favoritedStores = [];
  bool _isLoading = true;

  // Dados para o carrossel de promoções (como tínhamos antes)
  final List<CarouselItemData> _carouselDataItems = [
    CarouselItemData(
      title: "Ofertas Exclusivas!",
      subtitle: "Descontos especiais nas suas lojas favoritas.",
      backgroundColor: Colors.orange.shade100,
      // imageUrl: 'https://via.placeholder.com/400x150/FFCC80/000000?Text=Promo+Fav',
      onTap: () { print("Carrossel de Favoritos 1 clicado"); }
    ),
    CarouselItemData(
      title: "Descubra Mais",
      subtitle: "Explore novas opções e adicione aos seus favoritos.",
      backgroundColor: Colors.teal.shade100,
      onTap: () { print("Carrossel de Favoritos 2 clicado"); }
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFavoritedStores();
  }

  Future<void> _loadFavoritedStores() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    final favoriteIds = await FavoriteService.getFavoriteStoreIds();
    final List<EatsStoreModel> tempFavoritedStores = [];

    for (String id in favoriteIds) {
      final store = getStoreById(id); // Usando a função helper de all_eats_stores.dart
      if (store != null) {
        tempFavoritedStores.add(store);
      }
    }
    tempFavoritedStores.sort((a, b) => a.name.compareTo(b.name));
    
    if (mounted) {
      setState(() {
        _favoritedStores = tempFavoritedStores;
        _isLoading = false;
      });
    }
  }

  void _refreshFavorites() {
    _loadFavoritedStores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Fundo da tela
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        title: const Text(
          'FAVORITOS', // Título centralizado
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1.0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : CustomScrollView( // Usando CustomScrollView para o carrossel e a lista
              slivers: [
                // Carrossel Promocional NO TOPO
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 0.0), // Ajustado bottom padding
                    child: PromotionalCarouselWidget(
                      items: _carouselDataItems,
                      height: 150, // Altura do carrossel
                    ),
                  ),
                ),

                // Conteúdo da lista de favoritos ou mensagem de vazio
                _favoritedStores.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Você ainda não favoritou nenhuma loja.', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              Text('Toque no ❤️ nas lojas para adicioná-las aqui.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16.0), // Padding para a lista de lojas
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final store = _favoritedStores[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: StoreListItemWidget(
                                  store: store,
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      StoreDetailsScreen.routeName,
                                      arguments: store,
                                    ).then((_) {
                                      _refreshFavorites();
                                    });
                                  },
                                ),
                              );
                            },
                            childCount: _favoritedStores.length,
                          ),
                        ),
                      ),
              ],
            ),
    );
  }
}