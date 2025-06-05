// lib/widgets/ride_history_item_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:levva/models/enums.dart';
import '../models/ride_detail_model.dart'; // Certifique-se que este caminho está correto
                                          // e que RideDetailModel e RideHistoryStatus estão definidos.

class RideHistoryItemCard extends StatelessWidget {
  final RideDetailModel ride;
  final VoidCallback? onTap;

  const RideHistoryItemCard({super.key, required this.ride, this.onTap});

  Widget _buildStatusWidget(BuildContext context, RideHistoryStatus status) {
    IconData icon;
    Color color;
    String text;

    switch (status) {
      case RideHistoryStatus.completed:
        icon = Icons.check_circle_outline_rounded;
        color = Colors.green.shade700;
        text = "Concluída";
        break;
      case RideHistoryStatus.cancelled:
        icon = Icons.cancel_outlined;
        color = Colors.red.shade700;
        text = "Cancelada";
        break;
      case RideHistoryStatus.inProgress:
      default:
        icon = Icons.directions_car_filled_outlined; // Ícone genérico para "em andamento" de corrida
        color = Colors.orange.shade700;
        text = "Em Progresso";
        break;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final DateFormat dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

    // TODO: Se você tiver 'vehicleType' no seu RideDetailModel, pode mudar o ícone aqui.
    final IconData rideIcon = ride.vehicleDetails == VehicleType.moto // Exemplo, se VehicleType for um enum
        ? Icons.motorcycle_outlined
        : Icons.directions_car_outlined; 
    // Ou um ícone mais genérico se não tiver vehicleType:
    // final IconData rideIcon = Icons.route_outlined;


    return Card(
      elevation: 1.0,
      margin: EdgeInsets.zero, // A tela RideHistoryScreen controla o espaçamento
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: Colors.grey.shade200, width: 0.8),
      ),
      child: InkWell(
        onTap: ride.status == RideHistoryStatus.cancelled ? null : onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05), // Um cinza escuro leve
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(rideIcon, color: Colors.black54, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ride.rideDate != null
                              ? dateTimeFormatter.format(ride.rideDate!.toDate())
                              : 'Data indisponível',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                        _buildStatusWidget(context, ride.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Origem: ${ride.originName.isEmpty ? 'Não informado' : ride.originName}",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Destino: ${ride.destinationName.isEmpty ? 'Não informado' : ride.destinationName}",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ride.price != null
                        ? currencyFormatter.format(ride.price)
                        : 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  if (onTap != null && ride.status != RideHistoryStatus.cancelled)
                    Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}