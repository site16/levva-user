// ... imports mantidos como antes ...
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:levva/widgets/delivery_options_bottom_sheet.dart';
import 'package:levva/widgets/pin_on_map_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_request_provider.dart';
import '../widgets/pulsing_logo_loader.dart';

class AddressSearchBottomSheet extends StatefulWidget {
  const AddressSearchBottomSheet({super.key});

  @override
  State<AddressSearchBottomSheet> createState() => _AddressSearchBottomSheetState();
}

class _AddressSearchBottomSheetState extends State<AddressSearchBottomSheet> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  List<Map<String, String>> _destinationAutocompleteResults = [];

  final FocusNode _destinationFocusNode = FocusNode();

  Timer? _debounceDestination;

  bool _isLoadingDestinationSuggestions = false;
  bool _canProceed = false;
  bool _isDisposed = false;
  bool _isGettingLocation = false;

  Position? _userPosition;
  String? _userCity;

  static const String _logoPath = 'assets/images/levva_icon_transp.png';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      final rideRequestProvider = Provider.of<RideRequestProvider>(
        context,
        listen: false,
      );
      if (rideRequestProvider.origin != null) {
        _originController.text = rideRequestProvider.origin!.name;
      } else {
        _originController.text = "";
      }
      if (rideRequestProvider.destination != null) {
        _destinationController.text = rideRequestProvider.destination!.name;
      }
      _updateCanProceed();
    });

    _destinationController.addListener(_destinationListener);
    _destinationFocusNode.addListener(_destinationFocusListener);
  }

  Future<void> _getUserLocation() async {
    setStateSafe(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setStateSafe(() => _isGettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          setStateSafe(() => _isGettingLocation = false);
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _userPosition = pos;
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        _userCity = placemarks.first.locality;
      }
      setStateSafe(() {});
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
    } finally {
      setStateSafe(() => _isGettingLocation = false);
    }
  }

  void _destinationListener() {
    _updateCanProceed();
    if (_destinationFocusNode.hasFocus) {
      _debounceDestination?.cancel();
      _debounceDestination = Timer(const Duration(milliseconds: 400), () {
        if (!mounted || _isDisposed) return;
        if (_destinationController.text.length > 2) {
          _searchAddress(_destinationController.text);
        } else {
          setStateSafe(() => _destinationAutocompleteResults = []);
        }
      });
    }
  }

  void _destinationFocusListener() {
    if (!_destinationFocusNode.hasFocus && mounted && !_isDisposed) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted || _isDisposed) return;
        if (!_destinationFocusNode.hasFocus) {
          setStateSafe(() => _destinationAutocompleteResults = []);
        }
      });
    } else if (_destinationFocusNode.hasFocus &&
        _destinationController.text.length > 2 &&
        mounted && !_isDisposed) {
      _searchAddress(_destinationController.text);
    }
  }

  void _updateCanProceed() {
    if (!mounted || _isDisposed) return;
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );
    final bool originFilled = _originController.text.isNotEmpty && rideProvider.origin != null;
    final bool destinationTextNotEmpty = _destinationController.text.isNotEmpty;
    final bool providerDestinationSet = rideProvider.destination != null;

    final bool canProceedNow =
        originFilled &&
        destinationTextNotEmpty &&
        providerDestinationSet;

    if (canProceedNow != _canProceed) {
      setStateSafe(() {
        _canProceed = canProceedNow;
      });
    }
  }

  Future<void> _searchAddress(String query) async {
    if (!mounted || _isDisposed) return;
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );
    setStateSafe(() => _isLoadingDestinationSuggestions = true);

    try {
      final results = await rideProvider.getAutocompleteSuggestions(query);
      if (!mounted || _isDisposed) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setStateSafe(() {
          _destinationAutocompleteResults = results;
        });
      });
    } catch (e) {
      if (!mounted || _isDisposed) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro ao buscar: ${e.toString().substring(0, (e.toString().length > 60) ? 60 : e.toString().length)}...",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      });
    } finally {
      if (!mounted || _isDisposed) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setStateSafe(() {
          _isLoadingDestinationSuggestions = false;
        });
      });
    }
  }

  /// Botão para localização atual
  Future<void> _useCurrentLocationAsOrigin() async {
    if (_userPosition == null) {
      await _getUserLocation();
      if (_userPosition == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Não foi possível obter sua localização atual."),
              backgroundColor: Colors.redAccent,
            ),
          );
        });
        return;
      }
    }
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );
    setStateSafe(() => _isGettingLocation = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        _userPosition!.latitude,
        _userPosition!.longitude,
      );
      String address = placemarks.isNotEmpty
          ? "${placemarks.first.street}, ${placemarks.first.locality}"
          : "Local Atual";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _originController.text = address;
      });
      await rideProvider.setOrigin(
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
        address,
        address: address,
        placeId: "current-location",
      );
      _updateCanProceed();
    } catch (e) {
      debugPrint('Erro ao usar localização atual como origem: $e');
    } finally {
      setStateSafe(() => _isGettingLocation = false);
    }
  }

  /// Botão do alfinete (origem)
  Future<void> _selectOnMapOrigin() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PinOnMapScreen(
          title: "Selecione a origem",
          initialPosition: _userPosition != null
              ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
              : const LatLng(-15.3250, -49.1510),
        ),
      ),
    );

    if (result != null && result is Map) {
      final LatLng latLng = result['latLng'] as LatLng;
      final String address = result['address'] as String? ?? '';
      final rideProvider = Provider.of<RideRequestProvider>(context, listen: false);

      _originController.text = address;
      await rideProvider.setOrigin(latLng, address, address: address, placeId: "pin-on-map");
      _updateCanProceed();
      FocusScope.of(context).requestFocus(_destinationFocusNode);
    }
  }

  /// Botão do alfinete (destino)
  Future<void> _selectOnMapDestination() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PinOnMapScreen(
          title: "Selecione o destino",
          initialPosition: _userPosition != null
              ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
              : const LatLng(-15.3250, -49.1510),
        ),
      ),
    );

    if (result != null && result is Map) {
      final LatLng latLng = result['latLng'] as LatLng;
      final String address = result['address'] as String? ?? '';
      final rideProvider = Provider.of<RideRequestProvider>(context, listen: false);

      _destinationController.text = address;
      await rideProvider.setDestination(latLng, address, address: address, placeId: "pin-on-map");
      _updateCanProceed();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _selectPlace(
    Map<String, String> placeData,
    bool isOrigin,
  ) async {
    if (!mounted || _isDisposed) return;
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );
    final String description = placeData['description']!;
    final String placeId = placeData['place_id']!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setStateSafe(() {
        _isLoadingDestinationSuggestions = true;
        _destinationController.text = description;
        _destinationAutocompleteResults = [];
      });
    });

    try {
      final placeDetail = await rideProvider
          .getPlaceDetailsFromPlaceId(placeId, description);

      if (!mounted || _isDisposed) return;

      if (placeDetail != null) {
        await rideProvider.setDestination(
          placeDetail.location,
          placeDetail.name,
          address: placeDetail.address,
          placeId: placeDetail.placeId,
        );
        if (mounted && !_isDisposed)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FocusScope.of(context).unfocus();
          });
        _updateCanProceed();
      } else {
        throw Exception("Detalhes do local não encontrados.");
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro ao obter detalhes: ${e.toString().substring(0, (e.toString().length > 60) ? 60 : e.toString().length)}...",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        setStateSafe(() {
          _destinationController.clear();
        });
      });
    } finally {
      if (!mounted || _isDisposed) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setStateSafe(() {
          _isLoadingDestinationSuggestions = false;
        });
      });
    }
  }

  void _proceedToDeliveryOptions() {
    if (!mounted || _isDisposed) return;
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );
    _updateCanProceed();
    if (_canProceed) {
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext bc) {
            return ChangeNotifierProvider.value(
              value: rideProvider,
              child: const DeliveryOptionsBottomSheet(),
            );
          },
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Selecione uma origem e um destino válidos da lista."),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      });
    }
  }

  void setStateSafe(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle ||
          SchedulerBinding.instance.schedulerPhase == SchedulerPhase.postFrameCallbacks) {
        setState(fn);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposed) setState(fn);
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceDestination?.cancel();
    _destinationController.removeListener(_destinationListener);
    _destinationFocusNode.removeListener(_destinationFocusListener);
    _originController.dispose();
    _destinationController.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  /// Campo de endereço bloqueado + botões (origem)
  Widget _buildOriginFieldUI() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey("originFieldLocked"),
            controller: _originController,
            enabled: false,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Ponto de Partida',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          icon: const Icon(Icons.my_location, color: Colors.blue, size: 26),
          tooltip: "Usar minha localização",
          onPressed: _isGettingLocation ? null : _useCurrentLocationAsOrigin,
        ),
        IconButton(
          icon: const Icon(Icons.push_pin_outlined, color: Colors.black87, size: 26),
          tooltip: "Selecionar no mapa",
          onPressed: _isGettingLocation ? null : _selectOnMapOrigin,
        ),
      ],
    );
  }

  /// Campo de destino + botão alfinete (editável normalmente)
  Widget _buildDestinationFieldUI() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey("destinationField"),
            controller: _destinationController,
            focusNode: _destinationFocusNode,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            cursorColor: Colors.black,
            decoration: InputDecoration(
              hintText: 'Para onde vamos?',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.black87, size: 22),
              suffixIcon: _destinationController.text.isNotEmpty && !_isLoadingDestinationSuggestions
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () {
                        _destinationController.clear();
                        final rideProvider = Provider.of<RideRequestProvider>(
                          context,
                          listen: false,
                        );
                        rideProvider.clearDestination();
                        setStateSafe(() => _destinationAutocompleteResults = []);
                        _updateCanProceed();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          icon: const Icon(Icons.push_pin_outlined, color: Colors.black87, size: 26),
          tooltip: "Selecionar destino no mapa",
          onPressed: _isGettingLocation ? null : _selectOnMapDestination,
        ),
      ],
    );
  }

  Widget _buildSearchResultsList(
    List<Map<String, String>> results,
  ) {
    if (results.isEmpty) return const SizedBox.shrink();
    return Material(
      elevation: 3.0,
      borderRadius: BorderRadius.circular(8.0),
      color: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.25,
        ),
        child: ListView.builder(
          key: const ValueKey("destList"),
          shrinkWrap: true,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final placeData = results[index];
            return ListTile(
              key: ValueKey(placeData['place_id'] ?? placeData['description']),
              title: Text(
                placeData['description']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: const Icon(
                Icons.location_on_outlined,
                color: Colors.grey,
              ),
              dense: true,
              onTap: () => _selectPlace(placeData, false),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    double estimatedContentHeight = 220;
    if (_destinationFocusNode.hasFocus && _destinationAutocompleteResults.isNotEmpty) {
      estimatedContentHeight += (_destinationAutocompleteResults.length * 48.0).clamp(0, 120.0);
    }
    final initialSheetHeightFactor = (estimatedContentHeight / screenHeight).clamp(0.35, 0.90);

    return DraggableScrollableSheet(
      initialChildSize: initialSheetHeightFactor,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
          child: Container(
            padding: const EdgeInsets.only(top: 12.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Expanded(
                  child: ListView(
                    key: const ValueKey("mainListView"),
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      _buildOriginFieldUI(),
                      if (_isGettingLocation)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: PulsingLogoLoader(
                              imagePath: _logoPath,
                              size: 30,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      _buildDestinationFieldUI(),
                      if (_destinationFocusNode.hasFocus && _isLoadingDestinationSuggestions)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: PulsingLogoLoader(
                              imagePath: _logoPath,
                              size: 30,
                            ),
                          ),
                        )
                      else if (_destinationFocusNode.hasFocus && !_isLoadingDestinationSuggestions)
                        _buildSearchResultsList(
                          _destinationAutocompleteResults,
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                    top: 8.0,
                  ),
                  child: ElevatedButton(
                    onPressed: _canProceed ? _proceedToDeliveryOptions : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canProceed ? Colors.black : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ).copyWith(
                      elevation: MaterialStateProperty.all(
                        _canProceed ? 2.0 : 0.0,
                      ),
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}