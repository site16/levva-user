// lib/data/all_eats_stores.dart
import 'package:flutter/material.dart'; // Para IconData
// Ajuste o caminho para o seu modelo EatsStoreModel
import '../models/eats_store_model.dart';

// Esta é uma lista placeholder de TODAS as lojas disponíveis no seu app.
// Em um app real, isso viria de um backend/API.
// Certifique-se que os IDs são únicos.
final List<EatsStoreModel> allEatsStores = [
  EatsStoreModel(id: 's1', name: 'Pizzaria Forno Mágico', type: 'Pizza', imageUrl: 'https://via.placeholder.com/300x150/FFCDD2/000000?Text=Pizza+Banner', logo: Icons.local_pizza_outlined, rating: 4.7, deliveryTimeEstimate: '25-40 min', deliveryFee: 'R\$ 4,50', isOpen: true),
  EatsStoreModel(id: 's2', name: 'Burger Supremo', type: 'Lanches', imageUrl: 'https://via.placeholder.com/300x150/F8BBD0/000000?Text=Burger+Banner', logo: Icons.lunch_dining_outlined, rating: 4.3, deliveryTimeEstimate: '20-30 min', deliveryFee: 'Grátis', isOpen: true),
  EatsStoreModel(id: 's3', name: 'Sushi Imperial', type: 'Japonesa', imageUrl: 'https://via.placeholder.com/300x150/B2EBF2/000000?Text=Sushi+Banner', logo: Icons.ramen_dining_outlined, rating: 4.9, deliveryTimeEstimate: '35-50 min', deliveryFee: 'R\$ 8,00', isOpen: true),
  EatsStoreModel(id: 's4', name: 'Mercadinho da Vila', type: 'Mercado', imageUrl: 'https://via.placeholder.com/300x150/C8E6C9/000000?Text=Market+Banner', logo: Icons.store_mall_directory_outlined, rating: 4.1, deliveryTimeEstimate: '30-40 min', deliveryFee: 'R\$ 6,00', isOpen: false),
  EatsStoreModel(id: 's5', name: 'Farmácia Saúde Já', type: 'Farmácia', imageUrl: null, logo: Icons.medical_services_outlined, rating: 4.6, deliveryTimeEstimate: '15-25 min', deliveryFee: 'R\$ 3,00', isOpen: true),
  EatsStoreModel(id: 's6', name: 'Açaí Power', type: 'Açaí', imageUrl: null, logo: Icons.icecream_outlined, rating: 4.4, deliveryTimeEstimate: '20-35 min', deliveryFee: 'R\$ 5,50', isOpen: true),
  EatsStoreModel(id: 's7', name: 'Padaria Pão de Ouro', type: 'Padaria', imageUrl: 'https://via.placeholder.com/300x150/FFF9C4/000000?Text=Bakery', logo: Icons.bakery_dining_outlined, rating: 4.5, deliveryTimeEstimate: '10-20 min', deliveryFee: 'R\$ 2,00', isOpen: true),
  EatsStoreModel(id: 's8', name: 'Empório de Bebidas Geladas', type: 'Bebidas', imageUrl: null, logo: Icons.local_bar_outlined, rating: 4.0, deliveryTimeEstimate: '20-30 min', deliveryFee: 'R\$ 7,00', isOpen: false),
  EatsStoreModel(id: 's9', name: 'Delícias da Fazenda - Orgânicos', type: 'Hortifruti', imageUrl: 'https://via.placeholder.com/300x150/AED581/000000?Text=Orgânicos', logo: Icons.eco_outlined, rating: 4.8, deliveryTimeEstimate: '25-35 min', deliveryFee: 'R\$ 6,50', isOpen: true),
  EatsStoreModel(id: 's10', name: 'Pet Levva Shop Central', type: 'Pet Shops', imageUrl: 'https://via.placeholder.com/300x150/A1887F/FFFFFF?Text=PetShop+Central', logo: Icons.pets_outlined, rating: 4.6, deliveryTimeEstimate: '25-40 min', deliveryFee: 'R\$ 5,00', isOpen: true),
  // Adicione mais lojas aqui para ter uma base de dados mais completa
];

// Função helper para buscar uma loja pelo ID (usada pela tela de favoritos)
EatsStoreModel? getStoreById(String storeId) {
  try {
    return allEatsStores.firstWhere((store) => store.id == storeId);
  } catch (e) {
    return null; // Retorna null se não encontrar a loja
  }
}