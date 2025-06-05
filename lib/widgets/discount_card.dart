// lib/widgets/discount_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Certifique-se de ter o intl no pubspec.yaml
import '../models/discount_model.dart'; // Seu modelo de desconto

class DiscountCard extends StatelessWidget {
  final DiscountModel discount;
  final bool isAvailable; // Indica se o cupom está na lista de "Disponíveis"
  final VoidCallback? onApply;

  const DiscountCard({
    super.key,
    required this.discount,
    this.isAvailable = true,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final bool actualValidity = discount.isValidNow;
    // Verifica se o cupom pode ser aplicado
    final bool canActuallyApply = isAvailable && actualValidity && onApply != null;
    // Determina a opacidade do card se ele não for válido mas ainda estiver na lista de disponíveis
    final double cardOpacity = (isAvailable && !actualValidity) ? 0.5 : 1.0;

    return Opacity(
      opacity: cardOpacity,
      child: Card(
        elevation: 2.5,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canActuallyApply ? onApply : null,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            // Padding vertical aumentado para dar mais espaço à descrição
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0), // Antes era vertical: 12.0
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ícone à Esquerda
                Icon(
                  discount.iconData ?? Icons.local_offer_outlined,
                  color: Colors.grey.shade800,
                  size: 28,
                ),
                const SizedBox(width: 16),

                // Informações do Desconto (Centro)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        discount.description.isNotEmpty ? discount.description : discount.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2, // Mantido em 2, mas com mais espaço vertical, pode ser suficiente
                                     // Se ainda cortar, considere aumentar para 3.
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Válido até: ${DateFormat('dd/MM/yyyy', 'pt_BR').format(discount.validUntil.toDate())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Botão Aplicar (Direita)
                ElevatedButton(
                  onPressed: canActuallyApply ? onApply : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    elevation: canActuallyApply ? 1.5 : 0,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text(
                    'Aplicar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}