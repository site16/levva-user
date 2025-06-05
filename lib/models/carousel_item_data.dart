// lib/models/carousel_item_data.dart
import 'package:flutter/material.dart';

class CarouselItemData {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final String?
  imageUrl; // Opcional: para uma imagem de fundo no card do carrossel
  final VoidCallback? onTap; // Opcional: ação ao tocar no card

  CarouselItemData({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    this.imageUrl,
    this.onTap,
  });
}
