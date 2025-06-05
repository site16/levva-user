// lib/screens/ride_history/ride_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
 // Para BitmapDescriptor
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:levva/models/enums.dart'; // Para RideRequestStatus e RideHistoryStatus
import 'package:levva/providers/ride_request_provider.dart';
import 'package:provider/provider.dart';

import '../../providers/ride_history_provider.dart';
import '../../widgets/ride_history_item_card.dart';
import '../../models/ride_detail_model.dart'; // Para o tipo RideDetailModel
// Removido: import '../ride_detail/ride_detail_screen.dart'; pois não será mais usado para navegação direta

// <<< NOVO IMPORT para o BottomSheet de Detalhes da Corrida >>>
// Ajuste o caminho se o seu RideDetailBottomSheet estiver em um local diferente
// Ex: se estiver em lib/screens/ride_detail/RideDetailBottomSheet.dart
import '../ride_detail/RideDetailBottomSheet.dart';
// Ou, se você o moveu para uma pasta de widgets compartilhada:
// import '../../widgets/ride/RideDetailBottomSheet.dart';

// Import da tela de pedidos Eats e HomeScreen (se ainda não estiverem)
import 'package:levva/screens/orders/orders_screen.dart'; // Para EatsOrdersScreen.routeName
import '../home/home_screen.dart'; // Para HomeScreen.routeName se usado no AppBar


class RideHistoryScreen extends StatefulWidget {
  static const routeName = '/ride-history';
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  BitmapDescriptor? _originIcon;
  BitmapDescriptor? _destinationIcon;
  // _driverIcon não é usualmente necessário para histórico, mas o bottom sheet pode aceitá-lo como opcional

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons(); // Carrega os ícones dos marcadores
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RideHistoryProvider>(context, listen: false);
      // Busca o histórico apenas se estiver vazio e não carregando
      if (provider.rides.isEmpty && !provider.isLoading && provider.errorMessage == null) {
        provider.fetchRideHistory();
      }
    });
  }

  Future<void> _loadMarkerIcons() async {
    // Lógica similar à antiga RideDetailScreen para carregar ícones
    _originIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    _destinationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    // _driverIcon (se necessário para o bottom sheet e se quiser mostrar algo diferente para motorista no histórico)
    // _driverIcon = await BitmapDescriptor.fromAssetImage(
    //   const ImageConfiguration(size: Size(48, 48)),
    //   'assets/images/motorcycle_marker.png', // Certifique-se que este asset existe
    // ).catchError((e) => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange));

    if (mounted) {
      setState(() {}); // Atualiza para garantir que os ícones estejam prontos
    }
  }

  Future<void> _refreshHistory(BuildContext context) async {
    await Provider.of<RideHistoryProvider>(context, listen: false).fetchRideHistory();
  }

  // Função para converter RideHistoryStatus para RideRequestStatus (para o _buildStatusChip no BottomSheet)
  RideRequestStatus _convertHistoryStatusToRequestStatus(RideHistoryStatus historyStatus) {
    switch (historyStatus) {
      case RideHistoryStatus.completed:
        return RideRequestStatus.rideCompleted;
      case RideHistoryStatus.cancelled:
        return RideRequestStatus.rideCancelledByUser; // Ou um status de cancelado mais genérico
      case RideHistoryStatus.inProgress: // Se um histórico puder estar "em progresso"
        return RideRequestStatus.rideInProgressToDestination; // Ou um status de erro/incompleto
      default:
        return RideRequestStatus.unknown; // Um fallback
    }
  }

  void _showRideDetailSheet(BuildContext context, RideDetailModel ride) {
    // Como é um item do histórico, isLiveRide será false.
    // O currentStatus é derivado do ride.status.
    // Outros dados como driverLocation e polylinePoints podem não estar disponíveis ou serem nulos.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) {
        return RideDetailBottomSheet(
          rideData: ride,
          currentStatus: _convertHistoryStatusToRequestStatus(ride.status),
          isLiveRide: false, // Histórico de corridas não é "ao vivo"
          driverName: ride.driverName,
          vehicleDetails: ride.vehicleDetails,
          confirmationCode: ride.confirmationCode,
          // Para histórico, driverLocation e polylinePoints geralmente não são relevantes
          // ou já estão implícitos no mapa estático (se houver um path salvo).
          // Passe nulo ou listas vazias se não aplicável.
          driverLocation: null, // Não aplicável para histórico
          polylinePoints: const [], // Não aplicável para histórico, a menos que você salve a rota
          // routeBounds: // Pode ser calculado a partir de origin/destination se não tiver polyline
          originIcon: _originIcon,
          destinationIcon: _destinationIcon,
          driverIcon: null, // Não aplicável para histórico
          // onCancelRide e onShowInfoDialog podem não ser relevantes para histórico, passe null.
          onCancelRide: null,
          // onShowInfoDialog: (title, content) { /* ... */ }, // Se precisar de um dialog de info
        );
      },
    );
  }

  Widget _buildStatePlaceholder(BuildContext context, {required IconData icon, required String message, String? buttonText, VoidCallback? onButtonPressed}) {
    // ... (seu método _buildStatePlaceholder como antes)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Text(buttonText),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rideHistoryProvider = Provider.of<RideHistoryProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushNamedAndRemoveUntil(context, HomeScreen.routeName, (route) => false);
            }
          },
        ),
        title: const Text(
          'Histórico de Corridas',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1.0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.receipt_long_outlined, color: Colors.black54), // Ícone ajustado para pedidos
            tooltip: 'Ver Pedidos Eats',
            onPressed: () {
              Navigator.of(context).pushNamed(EatsOrdersScreen.routeName);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshHistory(context),
        color: Colors.black,
        child: Builder(
          builder: (context) {
            // ... (sua lógica de estados de loading, error, empty como antes) ...
            if (rideHistoryProvider.isLoading && rideHistoryProvider.rides.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Colors.black));
            }
            
            if (rideHistoryProvider.errorMessage != null && rideHistoryProvider.rides.isEmpty) {
              return _buildStatePlaceholder(
                context,
                icon: Icons.error_outline_rounded,
                message: rideHistoryProvider.errorMessage ?? "Ocorreu um erro ao buscar seu histórico. Tente novamente.",
                buttonText: "Tentar Novamente",
                onButtonPressed: () => _refreshHistory(context),
              );
            }
            
            if (rideHistoryProvider.rides.isEmpty && !rideHistoryProvider.isLoading) {
              return _buildStatePlaceholder(
                context,
                icon: Icons.history_rounded,
                message: "Seu histórico de corridas está vazio.",
              );
            }
              if (rideHistoryProvider.rides.isEmpty && rideHistoryProvider.isLoading) { // Esta condição pode ser redundante
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
              itemCount: rideHistoryProvider.rides.length,
              itemBuilder: (ctx, index) {
                final ride = rideHistoryProvider.rides[index]; // ride é um RideDetailModel
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: RideHistoryItemCard( // Seu card do histórico
                    ride: ride,
                    onTap: () {
                      // <<< CHAMADA ATUALIZADA PARA MOSTRAR O BOTTOMSHEET >>>
                      print("Exibindo detalhes da corrida (histórico) ID: ${ride.rideId}");
                      _showRideDetailSheet(context, ride);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}