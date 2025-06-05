// lib/screens/home/levva_eats/widgets/store_list_item_widget.dart
import 'package:flutter/material.dart';
import 'package:levva/models/eats_store_model.dart';
// Ajuste o caminho para o seu modelo EatsStoreModel
 
// Ajuste o caminho para a tela de detalhes da loja, se a navegação for feita aqui
// import '../store_details_screen.dart'; 

class StoreListItemWidget extends StatelessWidget {
  final EatsStoreModel store; // Agora recebe o modelo fortemente tipado
  final VoidCallback onTap;

  const StoreListItemWidget({
    super.key,
    required this.store,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Lógica de status visual baseada no modelo
    final bool isOpen = store.isOpen;
    final double itemOpacity = isOpen ? 1.0 : 0.5;
    final Color statusColor = isOpen ? Colors.green.shade600 : Colors.red.shade700;
    final String statusText = isOpen ? "Aberto agora" : "Fechado";

    // Lógica para imagem (se imageUrl existir e for válida) ou logo (IconData)
    Widget imageOrLogoWidget;
    final bool hasValidNetworkImage = store.imageUrl != null &&
                                     store.imageUrl!.isNotEmpty &&
                                     store.imageUrl!.startsWith('http');

    if (hasValidNetworkImage) {
      imageOrLogoWidget = Image.network(
        store.imageUrl!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => 
            Icon(store.logo, size: 30, color: Colors.grey.shade700), // Fallback para o logo IconData
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2.0,
            ),
          );
        },
      );
    } else {
      imageOrLogoWidget = Icon(store.logo, size: 30, color: Colors.grey.shade700);
    }


    return Opacity(
      opacity: itemOpacity,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12.0),
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: Colors.grey.shade200, width: 0.8)
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: isOpen ? onTap : null, // Usa o onTap passado para o widget
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60, 
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ClipRRect( // Para garantir que a imagem também tenha bordas arredondadas
                    borderRadius: BorderRadius.circular(8.0),
                    child: imageOrLogoWidget,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              store.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                              const SizedBox(width: 3),
                              Text(
                                store.rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store.type,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 8, 
                            height: 8,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${store.deliveryTimeEstimate} • ${store.deliveryFee}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
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