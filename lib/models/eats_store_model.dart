// lib/models/eats_store_model.dart
import 'package:flutter/material.dart'; // Necessário para IconData

class EatsStoreModel {
  final String id;
  final String name;
  final String type; // Tipo de estabelecimento, ex: "Pizzaria", "Farmácia"
  final String?
  imageUrl; // URL para uma imagem de banner/destaque da loja (opcional)
  final IconData logo; // Ícone principal para representar a loja em listas
  final double rating; // Avaliação da loja (ex: 4.5)
  final String
  deliveryTimeEstimate; // Estimativa de tempo de entrega (ex: "25-40 min")
  final String deliveryFee; // Custo do frete (ex: "R$ 5,99" ou "Grátis")
  final bool isOpen;
  final String? deliveryServiceInfo; // Indica se a loja está aberta ou fechada

  EatsStoreModel({
    required this.id,
    required this.name,
    required this.type,
    this.imageUrl, // Agora opcional
    required this.logo,
    required this.rating,
    required this.deliveryTimeEstimate,
    required this.deliveryFee,
    required this.isOpen,
    this.deliveryServiceInfo,
  });
}
