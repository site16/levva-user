// lib/screens/home/levva_eats/store_list_screen.dart
import 'package:flutter/material.dart';

// Ajuste estes caminhos de importação conforme a estrutura REAL do seu projeto:
import '../../../models/eats_store_model.dart'; // Para EatsStoreModel
// Se StoreListItemWidget está em lib/screens/home/levva_eats/widgets/
import './widgets/store_list_item_widget.dart';
// Se StoreListItemWidget está em lib/screens/levva_eats/widgets/ (um nível acima de 'home')
// import '../../levva_eats/widgets/store_list_item_widget.dart';

import './store_details_screen.dart'; // Para navegação para detalhes da loja

class StoreListScreen extends StatefulWidget {
  static const routeName = '/levva-eats-store-list';
  final Map<String, dynamic>? routeArgs;

  const StoreListScreen({super.key, this.routeArgs});

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  String _screenTitle = 'Lojas';
  List<EatsStoreModel> _displayedStores = [];

  // DADOS PLACEHOLDER ATUALIZADOS:
  // Certifique-se que cada EatsStoreModel aqui inclua todos os campos obrigatórios:
  // id, name, type, logo (IconData), rating, deliveryTimeEstimate, deliveryFee, isOpen.
  // imageUrl é opcional (String?).
  final List<EatsStoreModel> _allAvailableStores = [
    EatsStoreModel(id: 's3', name: 'Sushi Imperial', type: 'Japonesa', imageUrl: 'https://via.placeholder.com/300x150/B2EBF2/000000?Text=Sushi+Banner', logo: Icons.ramen_dining_outlined, rating: 4.9, deliveryTimeEstimate: '35-50 min', deliveryFee: 'R\$ 8,00', isOpen: true),
    EatsStoreModel(id: 's1', name: 'Pizzaria Forno Mágico', type: 'Pizza', imageUrl: 'https://via.placeholder.com/300x150/FFCDD2/000000?Text=Pizza+Banner', logo: Icons.local_pizza_outlined, rating: 4.7, deliveryTimeEstimate: '25-40 min', deliveryFee: 'R\$ 4,50', isOpen: true),
    EatsStoreModel(id: 's5', name: 'Farmácia Saúde Já', type: 'Farmácia', imageUrl: null, logo: Icons.medical_services_outlined, rating: 4.6, deliveryTimeEstimate: '15-25 min', deliveryFee: 'R\$ 3,00', isOpen: true), // Exemplo com imageUrl nula
    EatsStoreModel(id: 's10', name: 'Pet Levva Shop', type: 'Pet Shops', imageUrl: 'https://via.placeholder.com/300x150/A1887F/FFFFFF?Text=PetShop+Banner', logo: Icons.pets_outlined, rating: 4.6, deliveryTimeEstimate: '25-40 min', deliveryFee: 'R\$ 5,00', isOpen: false),
    EatsStoreModel(id: 's7', name: 'Padaria Pão de Ouro', type: 'Padaria', imageUrl: null, logo: Icons.bakery_dining_outlined, rating: 4.5, deliveryTimeEstimate: '10-20 min', deliveryFee: 'R\$ 2,00', isOpen: true),
    EatsStoreModel(id: 's2', name: 'Burger Supremo', type: 'Lanches', imageUrl: 'https://via.placeholder.com/300x150/F8BBD0/000000?Text=Burger+Banner', logo: Icons.lunch_dining_outlined, rating: 4.3, deliveryTimeEstimate: '20-30 min', deliveryFee: 'Grátis', isOpen: true),
    EatsStoreModel(id: 's4', name: 'Mercadinho da Vila', type: 'Mercado', imageUrl: 'https://via.placeholder.com/300x150/C8E6C9/000000?Text=Market+Banner', logo: Icons.store_mall_directory_outlined, rating: 4.1, deliveryTimeEstimate: '30-40 min', deliveryFee: 'R\$ 6,00', isOpen: false),
    EatsStoreModel(id: 's6', name: 'Açaí Power', type: 'Açaí', imageUrl: null, logo: Icons.icecream_outlined, rating: 4.4, deliveryTimeEstimate: '20-35 min', deliveryFee: 'R\$ 5,50', isOpen: true),
  ];

  @override
  void initState() {
    super.initState();
    _filterAndSortStores();
  }

  @override
  void didUpdateWidget(covariant StoreListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se os argumentos da rota puderem mudar enquanto a tela está visível,
    // você pode querer re-filtrar. Isso é menos comum para navegação simples.
    if (widget.routeArgs != oldWidget.routeArgs) {
      _filterAndSortStores();
    }
  }

  void _filterAndSortStores() {
    final args = widget.routeArgs;
    List<EatsStoreModel> tempStores = List.from(_allAvailableStores); // Cria uma cópia para manipulação

    // Lógica de Título e Filtro
    if (args != null) {
      if (args.containsKey('title')) {
         _screenTitle = args['title']; // Usa o título passado diretamente se houver
      }

      if (args.containsKey('categoryName')) {
        final categoryName = args['categoryName'] as String;
        _screenTitle = categoryName; // Sobrescreve o título com o nome da categoria
        final categoryLower = categoryName.toLowerCase().replaceAll('ç', 'c').replaceAll('á', 'a').replaceAll('ã', 'a');
         tempStores = tempStores.where((store) {
            final storeTypeLower = store.type.toLowerCase().replaceAll('ç', 'c').replaceAll('á', 'a').replaceAll('ã', 'a');
            if (categoryLower == "restaurantes") {
                return ['pizza', 'lanches', 'japonesa', 'acai', 'padaria'].contains(storeTypeLower);
            }
            return storeTypeLower.contains(categoryLower);
        }).toList();
      } else if (args.containsKey('searchQuery')) {
        final query = (args['searchQuery'] as String).toLowerCase();
        // O título já pode ter sido definido por 'title', então não sobrescrevemos necessariamente
        // _screenTitle = 'Resultados para "$query"';
        tempStores = tempStores.where((store) =>
            store.name.toLowerCase().contains(query) ||
            store.type.toLowerCase().contains(query)).toList();
      }
    } else {
       _screenTitle = 'Lojas'; // Título padrão se nenhum argumento for passado
    }

    // Lógica de Ordenação: Lojas abertas primeiro, depois por avaliação (maior para menor)
    tempStores.sort((a, b) {
      if (a.isOpen && !b.isOpen) return -1; // a (aberta) antes de b (fechada)
      if (!a.isOpen && b.isOpen) return 1;  // b (aberta) antes de a (fechada)
      return b.rating.compareTo(a.rating); // Ordena por avaliação descendente
    });

    if (mounted) {
      setState(() {
        _displayedStores = tempStores;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_screenTitle, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 1.0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _displayedStores.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Nenhuma loja encontrada para os critérios selecionados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _displayedStores.length,
              itemBuilder: (context, index) {
                final store = _displayedStores[index];
                // Usando o StoreListItemWidget que já lida com 'logo', 'isOpen' e 'imageUrl' opcional
                return StoreListItemWidget(
                  store: store,
                  onTap: () {
                    // A navegação para StoreDetailsScreen já é tratada pelo onTap do widget se store.isOpen
                    // O StoreListItemWidget já deve desabilitar o onTap se !store.isOpen
                    // Apenas precisamos garantir que o widget faça a navegação correta.
                    // Se StoreListItemWidget não faz a navegação, faça aqui:
                    if (store.isOpen) {
                       Navigator.of(context).pushNamed(StoreDetailsScreen.routeName, arguments: store);
                    } else {
                      // Opcional: Mostrar uma mensagem se tentar clicar em loja fechada,
                      // embora o widget já deva estar visualmente diferente e o onTap desabilitado.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${store.name} está fechada no momento.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}