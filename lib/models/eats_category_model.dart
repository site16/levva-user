// lib/models/eats_category_model.dart
import 'package:flutter/material.dart'; // Necessário para IconData e Color

class EatsCategoryModel {
  final String id;
  final String name;
  final IconData? icon;         // Ícone para a categoria (opcional)
  final String? imageUrl;       // URL de imagem para a categoria (opcional)
  final Color backgroundColor;  // Cor de fundo para o chip/card da categoria (opcional)

  EatsCategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.imageUrl,
    this.backgroundColor = Colors.grey, // Uma cor padrão
  }) : assert(icon != null || imageUrl != null,
            'EatsCategoryModel deve ter um ícone ou uma imageUrl para representação visual. '
            'Se categorias sem imagem/ícone são permitidas, remova esta asserção.');
            // A asserção acima é uma sugestão. Se você quiser categorias
            // que não tenham nem ícone nem imagem no modelo, pode remover o assert.
}