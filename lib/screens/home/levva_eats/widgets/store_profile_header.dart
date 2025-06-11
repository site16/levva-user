import 'package:flutter/material.dart';
import 'package:levva/models/eats_store_model.dart';

class StoreProfileHeader extends StatelessWidget {
  final EatsStoreModel store;
  final double? distanceKm;
  final String? deliveryTimeEstimate;
  final String? deliveryFee;

  const StoreProfileHeader({
    super.key,
    required this.store,
    this.distanceKm,
    this.deliveryTimeEstimate,
    this.deliveryFee,
  });

  @override
  Widget build(BuildContext context) {
    const double bannerHeight = 120.0;
    const double logoSize = 68.0;
    const double cardRadius = 22.0;
    const double cardVerticalPadding = 16.0;
    const double cardHorizontalPadding = 16.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    const double logoOverlap = 44.0;

    return SizedBox(
      height: bannerHeight + logoSize / 2 + 110,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner neutro
          Positioned.fill(
            child: Container(
              height: bannerHeight,
              color: Colors.grey[200],
            ),
          ),
          // Card com informações da loja
          Positioned(
            left: 14,
            right: 14,
            top: bannerHeight,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(cardRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: cardVerticalPadding,
                  horizontal: cardHorizontalPadding,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(cardRadius),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome da loja e avaliação na mesma linha
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 19,
                                  color: Colors.black87,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 2),
                            Text(
                              store.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Distância e tempo estimado
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (distanceKm != null)
                            Text(
                              '${distanceKm!.toStringAsFixed(1)} km',
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ),
                          if (deliveryTimeEstimate != null) ...[
                            const SizedBox(width: 14),
                            Icon(Icons.timer, color: Colors.black, size: 16),
                            const SizedBox(width: 2),
                            Text(
                              deliveryTimeEstimate!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tipo de entrega, frete
                    Row(
                      children: [
                        Text(
                          store.deliveryServiceInfo ?? 'Entrega da Loja',
                          style: TextStyle(color: Colors.grey[800], fontSize: 13),
                        ),
                        if (deliveryFee != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.local_shipping, color: Colors.black, size: 16),
                          Text(
                            deliveryFee!.toLowerCase().contains("grátis")
                                ? "Grátis"
                                : deliveryFee!,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: deliveryFee!.toLowerCase().contains("grátis")
                                  ? Colors.green
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Logo circular centralizado e MAIS ALTO
          Positioned(
            top: bannerHeight - logoOverlap,
            left: screenWidth / 2 - logoSize / 2,
            child: Container(
              height: logoSize,
              width: logoSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.black,
                child: Icon(store.logo, size: 36, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}