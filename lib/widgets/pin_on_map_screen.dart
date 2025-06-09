import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
// Importe seu MarkerAssets normalmente
import '../utils/marker_assets.dart';

class PinOnMapScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final String title;
  const PinOnMapScreen({
    super.key,
    this.initialPosition,
    required this.title,
  });

  @override
  State<PinOnMapScreen> createState() => _PinOnMapScreenState();
}

class _PinOnMapScreenState extends State<PinOnMapScreen>
    with SingleTickerProviderStateMixin {
  late LatLng _selectedLatLng;
  String? _address;
  bool _loadingAddress = false;
  late BitmapDescriptor _locationIcon;
  GoogleMapController? _mapController;
  String? _mapStyleJsonString;

  // Para animação de flutuação
  late AnimationController _animationController;
  late Animation<double> _markerYOffset;
  bool _isDragging = false; // está mexendo o mapa?

  @override
  void initState() {
    super.initState();
    _selectedLatLng =
        widget.initialPosition ?? const LatLng(-15.3250, -49.1510); // fallback
    _getAddress(_selectedLatLng);
    _locationIcon = MarkerAssets.locationIcon!;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    // Efeito mais suave (só 12 pixels)
    _markerYOffset = Tween<double>(begin: 0, end: -12)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    try {
      _mapStyleJsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/map_styles/map_style_silver.json');
      if (_mapController != null && _mapStyleJsonString != null) {
        await _mapController!.setMapStyle(_mapStyleJsonString);
      }
    } catch (e) {
      debugPrint('Erro ao carregar estilo do mapa: $e');
    }
  }

  Future<void> _getAddress(LatLng latLng) async {
    setState(() {
      _loadingAddress = true;
      _address = null;
    });
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _address =
              "${p.street ?? ''}, ${p.subLocality ?? ''} - ${p.locality ?? ''}";
        });
      } else {
        setState(() => _address = "Endereço não encontrado");
      }
    } catch (e) {
      setState(() => _address = "Endereço não encontrado");
    }
    setState(() => _loadingAddress = false);
  }

  void _onCameraMove(CameraPosition pos) {
    setState(() {
      _selectedLatLng = pos.target;
      if (!_isDragging) {
        _isDragging = true;
        _animationController.forward();
      }
    });
  }

  void _onCameraIdle() {
    if (_isDragging) {
      _animationController.reverse();
      setState(() {
        _isDragging = false;
      });
      _getAddress(_selectedLatLng);
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    if (_mapStyleJsonString != null) {
      await _mapController!.setMapStyle(_mapStyleJsonString);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLatLng,
              zoom: 16,
            ),
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            // markers removido: vamos desenhar o pin manualmente!
          ),
          // Marker flutuante central (somente o PNG, sem borda/sombra)
          IgnorePointer(
            child: Center(
              child: AnimatedBuilder(
                animation: _markerYOffset,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _markerYOffset.value),
                    child: child,
                  );
                },
                child: Image.asset(
                  "assets/icons/location_marker.png",
                  height: 46,
                  width: 46,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: _loadingAddress
                        ? const Text(
                            "Buscando endereço...",
                            style: TextStyle(color: Colors.black54),
                          )
                        : Text(
                            _address ?? "Selecione um local...",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _loadingAddress
                      ? null
                      : () {
                          Navigator.of(context).pop({
                            'latLng': _selectedLatLng,
                            'address': _address ?? '',
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Confirmar ponto"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}