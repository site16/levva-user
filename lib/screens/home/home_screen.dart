import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:levva/models/carousel_item_data.dart';
import 'package:levva/screens/home/levva_eats/eats_landing_screen.dart';
import 'package:levva/widgets/promotional_carousel_widget.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

// Providers
import '../../providers/auth_provider.dart';
import '../../providers/ride_request_provider.dart';
import '../../providers/notification_provider.dart';

// Widgets
import '../../widgets/app_drawer.dart';
import '../../widgets/address_search_bottom_sheet.dart';
import '../../widgets/map_display.dart';
import '../../widgets/ride_in_progress_panel.dart';
import '../../widgets/pulsing_logo_loader.dart';
import '../../widgets/passenger_option_card.dart';
import '../../widgets/delivery_option_card.dart';

// Telas
import '../../screens/notifications/notifications_screen.dart';

import '../../models/enums.dart'; // Importa ServiceType e RideRequestStatus

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _mapControllerCompleter =
      Completer<GoogleMapController>();
  GoogleMapController? _mapController;

  LatLng? _currentMapCenter;

  VoidCallback? _rideProviderListener;
  VoidCallback? _notificationProviderListener;

  StreamSubscription<Position>? _positionStreamSubscription;

  ServiceType _selectedService = ServiceType.passenger;
  final TextEditingController _searchController = TextEditingController();

  final List<CarouselItemData> _carouselDataItems = [
    CarouselItemData(
      title: "Promoção Especial!",
      subtitle: "Descontos incríveis esta semana para você.",
      backgroundColor: Colors.orangeAccent,
    ),
    CarouselItemData(
      title: "Novo no Levva?",
      subtitle: "Explore todas as funcionalidades e peça já.",
      backgroundColor: Colors.tealAccent,
    ),
    CarouselItemData(
      title: "Levva Entregas Ágeis",
      subtitle: "Envie seus pacotes com rapidez e segurança total.",
      backgroundColor: Colors.lightBlueAccent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestLocationPermissionAndGetCurrentLocation();

        final rideProvider = Provider.of<RideRequestProvider>(
          context,
          listen: false,
        );
        _rideProviderListener = () => _handleRideStatusChange(rideProvider);
        rideProvider.addListener(_rideProviderListener!);
        _handleRideStatusChange(rideProvider);

        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        _notificationProviderListener = () {
          if (mounted) setState(() {});
        };
        notificationProvider.addListener(_notificationProviderListener!);
        if (notificationProvider.notifications.isEmpty &&
            !notificationProvider.isLoading) {
          notificationProvider.fetchNotifications();
        }
      }
    });
  }

  void _handleRideStatusChange(RideRequestProvider rideProvider) {
    if (!mounted) return;

    if (rideProvider.status == RideRequestStatus.rideCompleted ||
        rideProvider.status == RideRequestStatus.rideCancelledByUser ||
        rideProvider.status == RideRequestStatus.rideCancelledByDriver ||
        rideProvider.status == RideRequestStatus.rideFailed) {
      if (rideProvider.status == RideRequestStatus.rideCompleted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sua Levva foi completada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      } else if ((rideProvider.status ==
                  RideRequestStatus.rideCancelledByUser ||
              rideProvider.status == RideRequestStatus.rideCancelledByDriver) &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sua Levva foi cancelada."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _requestLocationPermissionAndGetCurrentLocation();
      _stopListeningToDriverLocation();
    } else if (rideProvider.status == RideRequestStatus.routeCalculated &&
        rideProvider.routeBounds != null) {
      _animateToRouteBounds(rideProvider.routeBounds!);
    } else if (rideProvider.status.index >=
            RideRequestStatus.driverEnRouteToPickup.index &&
        rideProvider.status.index < RideRequestStatus.rideCompleted.index) {
      _startListeningToDriverLocation(rideProvider);
      _animateToRideFocus(rideProvider);
    }

    if (mounted) setState(() {});
  }

  void _startListeningToDriverLocation(RideRequestProvider rideProvider) {
    _stopListeningToDriverLocation();
    // Implemente a lógica real para ouvir a localização do motorista
  }

  void _stopListeningToDriverLocation() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<void> _animateToRideFocus(RideRequestProvider rideProvider) async {
    if (!mounted || _mapController == null) return;
    List<LatLng> pointsToInclude = [];
    if (rideProvider.origin != null)
      pointsToInclude.add(rideProvider.origin!.location);
    if (rideProvider.destination != null)
      pointsToInclude.add(rideProvider.destination!.location);
    if (rideProvider.assignedDriverLocation != null)
      pointsToInclude.add(rideProvider.assignedDriverLocation!);

    if (pointsToInclude.length < 2 && pointsToInclude.isNotEmpty) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pointsToInclude.first, 16.0),
      );
    } else if (pointsToInclude.length >= 2) {
      LatLngBounds bounds = _boundsFromLatLngList(pointsToInclude);
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  Future<void> _requestLocationPermissionAndGetCurrentLocation() async {
    if (!mounted) return;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, habilite o serviço de localização.'),
        ),
      );
      setState(() {
        _currentMapCenter = const LatLng(-15.3250, -49.1510);
      });
      if (_mapController != null && _currentMapCenter != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentMapCenter!, 14.0),
        );
      }
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de localização é necessária.')),
      );
      setState(() {
        _currentMapCenter = const LatLng(-15.3250, -49.1510);
      });
      if (_mapController != null && _currentMapCenter != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentMapCenter!, 14.0),
        );
      }
      return;
    }
    if (permission == LocationPermission.deniedForever && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permissão negada permanentemente. Habilite nas configurações.',
          ),
        ),
      );
      setState(() {
        _currentMapCenter = const LatLng(-15.3250, -49.1510);
      });
      if (_mapController != null && _currentMapCenter != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentMapCenter!, 14.0),
        );
      }
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      final newCenter = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentMapCenter = newCenter;
        });
        final GoogleMapController controller =
            await _mapControllerCompleter.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(newCenter, 15.5));
        final rideRequestProvider = Provider.of<RideRequestProvider>(
          context,
          listen: false,
        );
        if (rideRequestProvider.origin == null &&
            rideRequestProvider.status == RideRequestStatus.none) {
          rideRequestProvider.setOrigin(newCenter, "Meu Local Atual");
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível obter sua localização: ${e.toString()}',
            ),
          ),
        );
      setState(() {
        _currentMapCenter = const LatLng(-15.3250, -49.1510);
      });
      if (_mapController != null && _currentMapCenter != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentMapCenter!, 14.0),
        );
      }
    }
  }

  void _showAddressSearchSheet(BuildContext context) async {
    final rideRequestProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) => ChangeNotifierProvider.value(
        value: rideRequestProvider,
        child: const AddressSearchBottomSheet(),
      ),
    );
  }

  Future<void> _animateToRouteBounds(LatLngBounds bounds) async {
    if (!mounted || _mapController == null) return;
    try {
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70.0));
    } catch (e) {
      print("Erro ao animar câmera para os limites da rota: $e");
    }
  }

  @override
  void dispose() {
    if (_rideProviderListener != null)
      Provider.of<RideRequestProvider>(
        context,
        listen: false,
      ).removeListener(_rideProviderListener!);
    if (_notificationProviderListener != null)
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).removeListener(_notificationProviderListener!);
    _stopListeningToDriverLocation();
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceTap(ServiceType type) {
    setState(() => _selectedService = type);
    Provider.of<RideRequestProvider>(context, listen: false)
        .setServiceType(type);
  }

  @override
  Widget build(BuildContext context) {
    final rideRequestProvider = Provider.of<RideRequestProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    // Não passa markers do Home! Deixe o MapDisplay pegar direto do provider.
    // Isso garante que os markers sempre usem os ícones carregados corretamente.
    Set<Polyline> currentPolylines = {};
    if (rideRequestProvider.polylinePoints.isNotEmpty &&
        (rideRequestProvider.status == RideRequestStatus.routeCalculated ||
            rideRequestProvider.status == RideRequestStatus.selectingOptions ||
            (rideRequestProvider.status.index >=
                RideRequestStatus.rideAccepted.index &&
                rideRequestProvider.status.index <
                    RideRequestStatus.rideCompleted.index))) {
      currentPolylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: rideRequestProvider.polylinePoints,
          color: Colors.white, // Linha da rota branca
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }

    bool isRideActive =
        rideRequestProvider.status.index >=
            RideRequestStatus.rideAccepted.index &&
        rideRequestProvider.status.index <
            RideRequestStatus.rideCompleted.index;

    const String logoPathForOverlay =
        'assets/images/levva_icon_transp_branco.png';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBodyBehindAppBar: true,
      appBar: !isRideActive
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              surfaceTintColor: Colors.transparent,
              leading: Builder(
                builder: (BuildContext context) => IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                ),
              ),
              title: const Text(
                'Levva',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context)
                          .pushNamed(NotificationsScreen.routeName),
                      tooltip: 'Notificações',
                    ),
                    if (notificationProvider.unreadCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${notificationProvider.unreadCount > 9 ? "9+" : notificationProvider.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              shadowColor: Colors.transparent,
            )
          : null,
      drawer: const AppDrawer(),
      body: Stack(
        children: <Widget>[
          if (_currentMapCenter == null)
            const Center(
              child: PulsingLogoLoader(
                imagePath: 'assets/images/levva_icon_transp.png',
              ),
            )
          else
            MapDisplay(
              // markers: null faz o MapDisplay buscar direto do provider, sempre com os ícones certos!
              markers: null,
              polylines: currentPolylines,
              initialTarget: _currentMapCenter!,
              initialZoom: 15.5,
              showZoomControls: true,
              showMyLocationButton: !isRideActive,
              showMapToolbar: false,
              onMapCreatedCallback: (GoogleMapController controller) {
                if (!_mapControllerCompleter.isCompleted)
                  _mapControllerCompleter.complete(controller);
                _mapController = controller;
              },
              customMapStyleJsonPath: '',
            ),
          if (!isRideActive)
            Positioned(
              top: kToolbarHeight + 20, // logo abaixo do AppBar
              left: 0,
              right: 0,
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Card(
                  elevation: 3.0,
                  shadowColor: Colors.black.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            PassengerOptionCard(
                              isSelected:
                                  _selectedService == ServiceType.passenger,
                              onTap: () => _onServiceTap(ServiceType.passenger),
                            ),
                            const SizedBox(width: 8),
                            DeliveryOptionCard(
                              isSelected:
                                  _selectedService == ServiceType.delivery,
                              onTap: () => _onServiceTap(ServiceType.delivery),
                            ),
                            const SizedBox(width: 8),
                            _buildServiceSelectItem(
                              iconData: null,
                              imagePath: 'assets/images/levva_icon_transp.png',
                              labelWidget: Text(
                                "Levva Eats",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              isSelected: false,
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                    LevvaEatsLandingScreen.routeName);
                              },
                              iconSize: 32,
                              cardHeight: 100,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: (rideRequestProvider.status ==
                                      RideRequestStatus.calculatingRoute ||
                                  rideRequestProvider.isLoading)
                              ? null
                              : () => _showAddressSearchSheet(context),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(24.0),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.grey.shade700,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    rideRequestProvider.destination?.name ??
                                        'Para onde você vai?',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      color: rideRequestProvider
                                                  .destination?.name !=
                                              null
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!isRideActive && _currentMapCenter != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 16.0,
                  top: 8.0,
                  left: 8.0,
                  right: 8.0,
                ),
                child: PromotionalCarouselWidget(
                  items: _carouselDataItems,
                  height: 130,
                ),
              ),
            ),
          if (isRideActive) const RideInProgressPanel(),
          if (rideRequestProvider.isLoading &&
              (rideRequestProvider.status ==
                      RideRequestStatus.calculatingRoute ||
                  rideRequestProvider.status ==
                      RideRequestStatus.searchingDriver))
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: PulsingLogoLoader(
                    imagePath: logoPathForOverlay,
                    size: 80.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceSelectItem({
    required IconData? iconData,
    required String imagePath,
    required Widget labelWidget,
    required bool isSelected,
    required VoidCallback onTap,
    double iconSize = 26,
    double cardHeight = 100,
  }) {
    final Color backgroundColor = isSelected ? Colors.black : Colors.white;
    final Color contentColor = isSelected ? Colors.white : Colors.black87;

    Widget iconWidget;
    if (imagePath.isNotEmpty) {
      iconWidget = Image.asset(
        imagePath,
        color: contentColor,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.storefront, color: Colors.grey, size: iconSize),
      );
    } else if (iconData != null) {
      iconWidget = Icon(iconData, color: contentColor, size: iconSize);
    } else {
      iconWidget = SizedBox(width: iconSize, height: iconSize);
    }

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          height: cardHeight,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.15 : 0.08),
                spreadRadius: 1,
                blurRadius: isSelected ? 4 : 2,
                offset: Offset(0, isSelected ? 2 : 1),
              ),
            ],
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade300,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [iconWidget, const SizedBox(height: 8), labelWidget],
          ),
        ),
      ),
    );
  }
}