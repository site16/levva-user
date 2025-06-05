import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para Clipboard

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:levva/providers/ride_request_provider.dart';

import '../../models/ride_detail_model.dart'; // Seu modelo
import '../../models/enums.dart'; // Para RideRequestStatus
import '../../widgets/map_display.dart'; // Seu widget de mapa
// import '../home/levva_eats/store_details_screen.dart'; // Se for navegar para detalhes da loja

// Widget SectionTitle (mantido ou movido para um local comum)
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 28.0,
        bottom: 12.0,
      ), // Aumentado espaçamento
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class RideDetailBottomSheet extends StatelessWidget {
  final RideDetailModel rideData; // Assumindo não nulo
  final RideRequestStatus? currentStatus;
  final bool isLiveRide;
  final String? driverName;
  final String? vehicleDetails;
  final String? confirmationCode;
  final LatLng? driverLocation;
  final List<LatLng> polylinePoints;
  final LatLngBounds? routeBounds;
  final BitmapDescriptor? originIcon;
  final BitmapDescriptor? destinationIcon;
  final BitmapDescriptor? driverIcon;
  final VoidCallback? onCancelRide;

  const RideDetailBottomSheet({
    super.key,
    required this.rideData,
    this.currentStatus,
    required this.isLiveRide,
    this.driverName,
    this.vehicleDetails,
    this.confirmationCode,
    this.driverLocation,
    this.polylinePoints = const [],
    this.routeBounds,
    this.originIcon,
    this.destinationIcon,
    this.driverIcon,
    this.onCancelRide,
  });

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd/MM/yy \'às\' HH:mm', 'pt_BR').format(dt);
  }

  String _formatTime(DateTime dt) {
    return DateFormat('HH:mm', 'pt_BR').format(dt);
  }

  String _formatPrice(double price) {
    return "R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}";
  }

  // NOVO WIDGET PARA O BANNER DE STATUS DA CORRIDA
  Widget _buildRideStatusBanner(BuildContext context) {
    if (currentStatus == null) {
      return const SizedBox.shrink();
    }

    String title;
    String? subtitle;
    IconData iconData;
    Color bannerColor;
    Color contentColor;
    final theme = Theme.of(context);

    switch (currentStatus!) {
      case RideRequestStatus.rideCompleted:
        title = 'Corrida Concluída';
        subtitle =
            'Finalizada em ${_formatDateTime(rideData.rideDate.toDate())}';
        iconData = Icons.check_circle_rounded;
        bannerColor = Colors.green.withOpacity(0.1);
        contentColor = Colors.green.shade800;
        break;
      case RideRequestStatus.rideCancelledByUser:
      case RideRequestStatus.rideCancelledByDriver:
      case RideRequestStatus.rideFailed:
        title = 'Corrida Cancelada';
        // Você pode querer adicionar um timestamp de cancelamento ao seu RideDetailModel
        // subtitle = 'Cancelada em HH:MM';
        iconData = Icons.cancel_rounded;
        bannerColor = Colors.red.withOpacity(0.1);
        contentColor = Colors.red.shade800;
        break;
      case RideRequestStatus.searchingDriver:
        title = 'Procurando Entregador';
        subtitle = 'Aguarde um momento...';
        iconData = Icons.search_rounded;
        bannerColor = Colors.blue.withOpacity(0.1);
        contentColor = Colors.blue.shade800;
        break;
      case RideRequestStatus.driverEnRouteToPickup:
        title = 'Entregador a Caminho';
        subtitle =
            driverName != null ? 'Com ${driverName!}' : 'Coleta em breve';
        iconData = Icons.directions_bike_outlined;
        bannerColor = theme.primaryColor.withOpacity(0.1);
        contentColor = theme.primaryColorDark;
        break;
      case RideRequestStatus.driverArrivedAtPickup:
        title = 'Entregador no Local de Coleta';
        subtitle =
            driverName != null ? '${driverName!} chegou!' : 'Aguardando coleta';
        iconData = Icons.location_on_rounded;
        bannerColor = Colors.teal.withOpacity(0.1);
        contentColor = Colors.teal.shade800;
        break;
      case RideRequestStatus.rideInProgressToDestination:
        title = 'Viagem em Andamento';
        subtitle = 'Destino: ${rideData.destinationName}';
        iconData = Icons.route_rounded;
        bannerColor = theme.primaryColor.withOpacity(0.15);
        contentColor = theme.primaryColorDark;
        break;
      default:
        title =
            'Status: ${currentStatus.toString().split('.').last.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}').trim()}';
        iconData = Icons.info_outline_rounded;
        bannerColor = Colors.grey.shade200;
        contentColor = Colors.grey.shade800;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16.0, bottom: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(iconData, size: 32, color: contentColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: contentColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: contentColor.withOpacity(0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String? value, {
    VoidCallback? onCopy,
    String? copyTooltip,
    bool highlightValue = false,
  }) {
    // ... (seu _buildInfoRow como antes, talvez com pequenos ajustes de estilo se desejar) ...
    final theme = Theme.of(context);
    final displayValue = value ?? 'Não informado';
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 9.0,
      ), // Espaçamento ajustado
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary.withOpacity(0.9),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        highlightValue ? FontWeight.bold : FontWeight.w500,
                    color:
                        highlightValue
                            ? theme.colorScheme.primary
                            : Colors.black.withOpacity(0.87),
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null && value != null && value.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.copy_outlined,
                size: 19,
                color: Colors.grey.shade600,
              ),
              padding: const EdgeInsets.all(4), // Área de toque um pouco maior
              constraints: const BoxConstraints(),
              tooltip: copyTooltip ?? "Copiar $label",
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // rideData já é obrigatório no construtor, então não precisa de verificação de nulo aqui,
    // a tela chamadora é que deve garantir que ele não seja nulo.
    // Se ainda assim quiser uma segurança extra:
    // if (rideData == null) { return Center(child: Text("Erro ao carregar dados."));}
    // final data = rideData!; // Usado abaixo

    Set<Marker> markers = {};
    if (rideData.originLocation != null && originIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: rideData.originLocation!,
          icon: originIcon!,
          infoWindow: InfoWindow(title: "Origem", snippet: rideData.originName),
        ),
      );
    }
    if (rideData.destinationLocation != null && destinationIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: rideData.destinationLocation!,
          icon: destinationIcon!,
          infoWindow: InfoWindow(
            title: "Destino",
            snippet: rideData.destinationName,
          ),
        ),
      );
    }
    if (isLiveRide && driverLocation != null && driverIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverLocation!,
          icon: driverIcon!,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: driverName ?? "Entregador"),
        ),
      );
    }

    Set<Polyline> polylinesSet = {};
    if (polylinePoints.isNotEmpty) {
      polylinesSet.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: theme.primaryColor.withOpacity(0.7),
          width: 5,
        ),
      );
    }

    LatLng initialMapTarget =
        rideData.originLocation ?? const LatLng(-15.7942, -47.8825);
    LatLngBounds? boundsToFit = routeBounds;
    if (!isLiveRide &&
        rideData.originLocation != null &&
        rideData.destinationLocation != null) {
      boundsToFit = LatLngBounds(
        /* ... cálculo de bounds ... */
        southwest: LatLng(
          rideData.originLocation!.latitude <
                  rideData.destinationLocation!.latitude
              ? rideData.originLocation!.latitude
              : rideData.destinationLocation!.latitude,
          rideData.originLocation!.longitude <
                  rideData.destinationLocation!.longitude
              ? rideData.originLocation!.longitude
              : rideData.destinationLocation!.longitude,
        ),
        northeast: LatLng(
          rideData.originLocation!.latitude >
                  rideData.destinationLocation!.latitude
              ? rideData.originLocation!.latitude
              : rideData.destinationLocation!.latitude,
          rideData.originLocation!.longitude >
                  rideData.destinationLocation!.longitude
              ? rideData.originLocation!.longitude
              : rideData.destinationLocation!.longitude,
        ),
      );
    }

    bool showConfirmationDetails =
        isLiveRide &&
        confirmationCode != null &&
        confirmationCode!.isNotEmpty &&
        (currentStatus == RideRequestStatus.driverArrivedAtPickup ||
            currentStatus == RideRequestStatus.rideInProgressToDestination);

    bool canUserCancelRide =
        isLiveRide &&
        onCancelRide != null &&
        (currentStatus == RideRequestStatus.searchingDriver ||
            // ... outras condições para cancelamento
            currentStatus == RideRequestStatus.driverEnRouteToPickup);

    return Material(
      color: Colors.white,
      elevation: 0, // O ModalBottomSheet já tem sua própria elevação
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        padding: const EdgeInsets.only(top: 8.0), // Apenas para o handle
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              // Handle
              width: 48,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Botão X foi REMOVIDO
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  22.0,
                  0.0,
                  22.0,
                  20.0,
                ), // Padding lateral ajustado
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (rideData.originLocation != null ||
                        rideData.destinationLocation !=
                            null) // Mostra mapa se houver locais
                      SizedBox(
                        height: 180, // Altura do mapa reduzida
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: MapDisplay(
                            initialTarget: initialMapTarget,
                            initialZoom: 13.0,
                            markers: markers,
                            polylines: polylinesSet,
                            routeBoundsToFit: boundsToFit,
                            // customMapStyleJsonPath: 'assets/map_styles/map_style_levva.json',
                          ),
                        ),
                      ),

                    // NOVO BANNER DE STATUS
                    _buildRideStatusBanner(context),

                    if (showConfirmationDetails) // Card do código de confirmação
                      Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: (theme.primaryColorDark ?? theme.primaryColor)
                              .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: (theme.primaryColorDark ??
                                    theme.primaryColor)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "CÓDIGO DE ENTREGA/COLETA",
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    theme.primaryColorDark ??
                                    theme.primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              confirmationCode!,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Informe este código para confirmar.",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              icon: const Icon(Icons.copy_outlined, size: 18),
                              label: const Text("Copiar Código"),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    theme.primaryColorDark ??
                                    theme.primaryColor,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: confirmationCode!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Código copiado!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                    const SectionTitle("Resumo da Viagem"),
                    _buildInfoRow(
                      context,
                      Icons.calendar_month_outlined,
                      "Data e Hora",
                      _formatDateTime(rideData.rideDate.toDate()),
                    ),
                    _buildInfoRow(
                      context,
                      Icons.receipt_long_outlined,
                      "ID da Corrida",
                      rideData.rideId,
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: rideData.rideId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ID da Corrida copiado!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    _buildInfoRow(
                      context,
                      Icons.linear_scale_rounded,
                      "Trajeto",
                      "${rideData.originName} para ${rideData.destinationName}",
                    ), // Ícone diferente para trajeto
                    _buildInfoRow(
                      context,
                      Icons.payments_outlined,
                      "Valor Pago",
                      _formatPrice(rideData.price),
                      highlightValue: true,
                    ),

                    if (driverName != null && driverName!.isNotEmpty) ...[
                      const SectionTitle("Entregador"),
                      _buildInfoRow(
                        context,
                        Icons.person_pin_outlined,
                        "Nome",
                        driverName,
                      ),
                      if (vehicleDetails != null && vehicleDetails!.isNotEmpty)
                        _buildInfoRow(
                          context,
                          Icons.motorcycle_outlined,
                          "Veículo",
                          vehicleDetails,
                        ),
                    ],

                    if (canUserCancelRide) ...[
                      const SizedBox(height: 24),
                      Center(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            Icons.cancel_presentation_rounded,
                            color: Colors.red.shade700,
                          ),
                          label: Text(
                            "Cancelar Corrida",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.red.shade300,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: onCancelRide,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Botão inferior foi removido
          ],
        ),
      ),
    );
  }
}
