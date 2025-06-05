import 'dart:async'; // Para Completer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle; // Para carregar o JSON do estilo do mapa
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapDisplay extends StatefulWidget {
  final LatLng initialTarget;
  final double initialZoom;
  final String? customMapStyleJsonPath;
  final bool showMyLocation;
  final bool showMyLocationButton;
  final bool showZoomControls;
  final bool showCompass;
  final bool showMapToolbar;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  // Callback para quando o mapa é criado e o controller está disponível
  // Certifique-se de que o tipo é void Function(GoogleMapController controller)?
  final void Function(GoogleMapController controller)? onMapCreatedCallback;

  const MapDisplay({
    super.key,
    this.initialTarget = const LatLng(
      -15.3250,
      -49.1510,
    ), // Padrão para Goianésia
    this.initialZoom = 14.0,
    this.customMapStyleJsonPath,
    this.showMyLocation = true,
    this.showMyLocationButton = true,
    this.showZoomControls = false,
    this.showCompass = false,
    this.showMapToolbar = false,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.onMapCreatedCallback,
    LatLngBounds? routeBoundsToFit, // Adiciona o callback ao construtor
  });

  @override
  State<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  final Completer<GoogleMapController> _controllerCompleter =
      Completer<GoogleMapController>();
  GoogleMapController? _mapController;
  String? _mapStyleJsonString;

  @override
  void initState() {
    super.initState();
    if (widget.customMapStyleJsonPath != null) {
      _loadMapStyle();
    }
  }

  Future<void> _loadMapStyle() async {
    if (widget.customMapStyleJsonPath == null) return;
    try {
      _mapStyleJsonString = await rootBundle.loadString(
        widget.customMapStyleJsonPath!,
      );
      if (mounted && _mapController != null && _mapStyleJsonString != null) {
        print(
          "Aplicando estilo de mapa personalizado após carregamento do estilo.",
        );
        await _mapController!.setMapStyle(_mapStyleJsonString);
      }
    } catch (e) {
      print('Erro ao carregar estilo do mapa: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller; // Guarda a referência localmente
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(controller);
    }

    // Aplica o estilo JSON se já foi carregado
    if (_mapStyleJsonString != null) {
      print("Aplicando estilo de mapa personalizado em _onMapCreated.");
      _mapController!.setMapStyle(_mapStyleJsonString);
    }

    // Chama o callback passado pela HomeScreen, se existir
    if (widget.onMapCreatedCallback != null) {
      widget.onMapCreatedCallback!(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: widget.initialTarget,
        zoom: widget.initialZoom,
      ),
      onMapCreated: _onMapCreated, // Usa o método interno _onMapCreated
      myLocationEnabled: widget.showMyLocation,
      myLocationButtonEnabled: widget.showMyLocationButton,
      zoomControlsEnabled: widget.showZoomControls,
      compassEnabled: widget.showCompass,
      mapToolbarEnabled: widget.showMapToolbar,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      markers: widget.markers,
      polylines: widget.polylines,
      // mapId: "SEU_MAP_ID_AQUI",
    );
  }
}
