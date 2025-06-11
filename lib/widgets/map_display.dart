import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/ride_request_provider.dart';
import '../providers/deliveryman_provider.dart';

class MapDisplay extends StatefulWidget {
  final LatLng? initialTarget;
  final double initialZoom;
  final bool showMyLocation;
  // final bool showMyLocationButton; // removido do construtor, não faz sentido se sempre será false
  // final bool showZoomControls; // removido do construtor, não faz sentido se sempre será false
  final bool showCompass;
  final bool showMapToolbar;
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final void Function(GoogleMapController controller)? onMapCreatedCallback;
  final LatLngBounds? routeBoundsToFit;

  const MapDisplay({
    super.key,
    this.initialTarget,
    this.initialZoom = 14.0,
    this.showMyLocation = true,
    // this.showMyLocationButton = true, // removido
    // this.showZoomControls = false, // removido
    this.showCompass = false,
    this.showMapToolbar = false,
    this.markers,
    this.polylines,
    this.onMapCreatedCallback,
    this.routeBoundsToFit,
    required String customMapStyleJsonPath,
  });

  @override
  State<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  final Completer<GoogleMapController> _controllerCompleter = Completer<GoogleMapController>();
  GoogleMapController? _mapController;
  String? _mapStyleJsonString;
  BitmapDescriptor? _deliverymanIcon;
  BitmapDescriptor? _locationIcon;

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _loadMapStyle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeliverymanProvider>(
        context,
        listen: false,
      ).fetchDeliverymen();
    });
  }

  Future<void> _loadMapStyle() async {
    try {
      _mapStyleJsonString = await rootBundle.loadString(
        'assets/map_styles/map_style_silver.json',
      );
      if (mounted && _mapController != null && _mapStyleJsonString != null) {
        await _mapController!.setMapStyle(_mapStyleJsonString);
      }
    } catch (e) {
      debugPrint('Erro ao carregar estilo do mapa: $e');
    }
  }

  Future<void> _loadIcons() async {
    try {
      final locationIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(36, 36)),
        'assets/icons/location_marker.png',
      );
      final deliverymanIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(36, 36)),
        'assets/icons/deliveryman.png',
      );
      if (mounted) {
        setState(() {
          _locationIcon = locationIcon;
          _deliverymanIcon = deliverymanIcon;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar ícones: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(controller);
    }

    if (_mapStyleJsonString != null) {
      await _mapController!.setMapStyle(_mapStyleJsonString);
    }

    if (widget.routeBoundsToFit != null) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(widget.routeBoundsToFit!, 80),
      );
    }

    if (widget.onMapCreatedCallback != null) {
      widget.onMapCreatedCallback!(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = Provider.of<RideRequestProvider>(context);
    final deliverymanProvider = Provider.of<DeliverymanProvider>(context);

    if (_deliverymanIcon == null || _locationIcon == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final Set<Marker> deliverymenMarkers = _getDeliverymenMarkers(
      deliverymanProvider.deliverymenOnline,
    );

    final Set<Marker> baseMarkers =
        widget.markers ?? _getMarkersFromProvider(rideProvider);

    final Set<Marker> markers = {...baseMarkers, ...deliverymenMarkers};
    final polylines =
        widget.polylines ?? _getPolylinesFromProvider(rideProvider);

    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: widget.initialTarget ??
            rideProvider.origin?.location ??
            const LatLng(-15.3250, -49.1510),
        zoom: widget.initialZoom,
      ),
      onMapCreated: _onMapCreated,
      myLocationEnabled: widget.showMyLocation,
      myLocationButtonEnabled: false, // OCULTA O BOTÃO DE LOCALIZAÇÃO ATUAL
      zoomControlsEnabled: false,     // OCULTA OS BOTÕES DE ZOOM +/-
      compassEnabled: widget.showCompass,
      mapToolbarEnabled: widget.showMapToolbar,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      markers: markers,
      polylines: polylines,
    );
  }

  Set<Marker> _getMarkersFromProvider(RideRequestProvider provider) {
    final Set<Marker> markers = {};
    if (provider.origin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: provider.origin!.location,
          infoWindow: const InfoWindow(title: 'Origem'),
          icon: _locationIcon!,
        ),
      );
    }
    if (provider.destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dest'),
          position: provider.destination!.location,
          infoWindow: const InfoWindow(title: 'Destino'),
          icon: _locationIcon!,
        ),
      );
    }
    if (provider.assignedDriverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: provider.assignedDriverLocation!,
          infoWindow: const InfoWindow(title: 'Entregador'),
          icon: _deliverymanIcon!,
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _getPolylinesFromProvider(RideRequestProvider provider) {
    final Set<Polyline> polylines = {};
    if (provider.polylinePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: provider.polylinePoints,
          color: Colors.white, // Linha da rota branca
          width: 6,
        ),
      );
    }
    return polylines;
  }

  Set<Marker> _getDeliverymenMarkers(List deliverymen) {
    if (_deliverymanIcon == null) return {};
    if (deliverymen.isEmpty) {
      // Simulação: 2 online caso lista esteja vazia
      final base = widget.initialTarget ?? const LatLng(-15.3250, -49.1510);
      deliverymen = [
        Deliveryman(
          id: 'sim1',
          name: 'Entregador 1',
          location: LatLng(base.latitude + 0.003, base.longitude + 0.003),
          online: true,
        ),
        Deliveryman(
          id: 'sim3',
          name: 'Entregador 3',
          location: LatLng(base.latitude + 0.002, base.longitude - 0.003),
          online: true,
        ),
      ];
    }

    return deliverymen.map<Marker>((entregador) {
      return Marker(
        markerId: MarkerId('deliveryman_${entregador.id}'),
        position: entregador.location,
        icon: _deliverymanIcon!,
        infoWindow: InfoWindow(title: entregador.name),
      );
    }).toSet();
  }
}