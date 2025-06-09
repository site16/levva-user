import 'package:flutter/material.dart';
import 'package:levva/models/enums.dart';
import 'package:provider/provider.dart';
import '../providers/ride_request_provider.dart';

class RideInProgressPanel extends StatelessWidget {
  const RideInProgressPanel({super.key});

  String _getDisplayStatus(
    RideRequestStatus status,
    RideRequestProvider provider,
  ) {
    switch (status) {
      case RideRequestStatus.rideAccepted:
        return 'Entregador confirmado!';
      case RideRequestStatus.driverEnRouteToPickup:
        return 'Entregador a caminho da coleta';
      case RideRequestStatus.driverArrivedAtPickup:
        return 'Entregador chegou para coletar';
      case RideRequestStatus.rideInProgressToDestination:
        return 'Em rota para o destino';
      default:
        return 'Processando sua Levva...';
    }
  }

  String? _getDisplayEta(
    RideRequestStatus status,
    RideRequestProvider provider,
  ) {
    switch (status) {
      case RideRequestStatus.driverEnRouteToPickup:
        return provider.assignedDriverEtaToPickup;
      case RideRequestStatus.driverArrivedAtPickup:
        return "Chegou!";
      case RideRequestStatus.rideInProgressToDestination:
        return provider.assignedDriverEtaToDestination;
      default:
        return null;
    }
  }

  Future<void> _confirmCancelRide(
    BuildContext context,
    RideRequestProvider rideProvider,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text('Cancelar Levva?'),
          content: const Text(
            'Tem certeza de que deseja cancelar esta Levva em andamento?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Não'),
              onPressed: () {
                Navigator.of(ctx).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Sim, Cancelar'),
              onPressed: () {
                Navigator.of(ctx).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      rideProvider.cancelRideByUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = Provider.of<RideRequestProvider>(context);
    final theme = Theme.of(context);

    if (rideProvider.status.index < RideRequestStatus.rideAccepted.index ||
        rideProvider.status.index >= RideRequestStatus.rideCompleted.index) {
      return const SizedBox.shrink();
    }

    String displayStatus = _getDisplayStatus(rideProvider.status, rideProvider);
    String? displayEta = _getDisplayEta(rideProvider.status, rideProvider);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 8.0,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      displayStatus,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColorDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (displayEta != null && displayEta.isNotEmpty)
                    Text(
                      displayEta,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        rideProvider.assignedDriverProfileImageUrl != null &&
                                rideProvider
                                    .assignedDriverProfileImageUrl!
                                    .isNotEmpty
                            ? NetworkImage(
                                rideProvider.assignedDriverProfileImageUrl!,
                              )
                            : null,
                    child: (rideProvider.assignedDriverProfileImageUrl == null ||
                            rideProvider
                                .assignedDriverProfileImageUrl!.isEmpty)
                        ? Icon(
                            Icons.person,
                            size: 28,
                            color: Colors.grey.shade500,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rideProvider.assignedDriverName ?? 'Entregador Levva',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (rideProvider.assignedDriverVehicleDetails != null &&
                            rideProvider
                                .assignedDriverVehicleDetails!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              rideProvider.assignedDriverVehicleDetails!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel_schedule_send_outlined, size: 20),
                label: const Text('Cancelar Levva'),
                onPressed: () => _confirmCancelRide(context, rideProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
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