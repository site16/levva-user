// lib/screens/home/levva_eats/widgets/product_list_item_widget.dart
import 'package:flutter/material.dart';
import 'package:levva/models/eats_product_model.dart';
// Ajuste o caminho do import para o seu modelo EatsProductModel


class ProductListItemWidget extends StatelessWidget {
  final EatsProductModel product;
  final VoidCallback? onTap; // Ação ao tocar no card (pode levar aos detalhes ou iniciar adição)

  const ProductListItemWidget({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValidNetworkImage =
        product.imageUrl != null && product.imageUrl!.startsWith('http');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5.0), // Margem vertical um pouco menor
      elevation: 0.8, // Elevação sutil
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: Colors.grey.shade200, width: 0.7),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagem do Produto
              Container(
                width: 55, // Largura da imagem ainda menor
                height: 55, // Altura da imagem ainda menor
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6.0),
                  image: hasValidNetworkImage
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrl!),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {},
                        )
                      : null,
                ),
                child: !hasValidNetworkImage
                    ? Icon(Icons.image_outlined, size: 22, color: Colors.grey.shade400)
                    : null,
              ),
              const SizedBox(width: 10),

              // Nome e Descrição
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14, // Levemente menor
                        fontWeight: FontWeight.w600, // Um pouco menos bold que antes
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3.0),
                        child: Text(
                          product.description,
                          style: TextStyle(
                            fontSize: 11.5, // Descrição menor
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Preço do Produto (NO LUGAR DO BOTÃO "ADD")
              Padding(
                padding: const EdgeInsets.only(left: 8.0), // Espaço à esquerda do preço
                child: Text(
                  'R\$ ${product.price.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold, // Preço em negrito
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}