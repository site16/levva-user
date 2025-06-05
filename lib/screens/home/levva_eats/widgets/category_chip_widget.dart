// lib/screens/levva_eats/widgets/category_chip_widget.dart
import 'package:flutter/material.dart';
import 'package:levva/models/eats_category_model.dart';
// Ajuste o caminho se o seu modelo estiver em lib/models/

class CategoryChipWidget extends StatelessWidget {
  final EatsCategoryModel category;
  final VoidCallback onTap;

  const CategoryChipWidget({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Para acessar cores do tema, se necessário

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0), // Raio da borda para o efeito do toque
      child: Card(
        elevation: 1.0, // Sombra sutil para o card
        color: category.backgroundColor.withOpacity(0.9), // Usa a cor de fundo do modelo com leve opacidade
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          // side: BorderSide(color: Colors.grey.shade300, width: 0.5), // Borda opcional
        ),
        child: Container(
          width: 90, // Largura fixa para cada chip de categoria
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Para que a coluna se ajuste ao conteúdo
            mainAxisAlignment: MainAxisAlignment.center, // Centraliza o conteúdo verticalmente
            children: [
              Icon(
                category.icon,
                size: 30, // Tamanho do ícone
                color: theme.primaryColorDark, // Usa uma cor escura do tema para bom contraste
              ),
              const SizedBox(height: 8), // Espaço entre o ícone e o texto
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800, // Cor do texto
                ),
                maxLines: 2, // Permite que o nome da categoria quebre em duas linhas se for longo
                overflow: TextOverflow.ellipsis, // Adiciona "..." se o texto for muito longo
              ),
            ],
          ),
        ),
      ),
    );
  }
}