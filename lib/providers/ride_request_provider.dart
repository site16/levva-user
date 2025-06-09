import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:levva/services/google_maps_service.dart';

import '../models/enums.dart';
import '../models/ride_detail_model.dart';
import '../services/firestore_service.dart';

// Classe para detalhes do local (origem/destino)
class PlaceDetail {
  final LatLng location;
  final String name;
  final String? address;
  final String? placeId;

  PlaceDetail({
    required this.location,
    required this.name,
    this.address,
    this.placeId,
  });
}

class RideRequestProvider with ChangeNotifier {
  final GoogleMapsService _googleMapsService;
  final FirestoreService _firestoreService;

  // --- LÓGICA DE TIPO DE SERVIÇO ---
  ServiceType _serviceType = ServiceType.passenger;
  ServiceType get serviceType => _serviceType;
  void setServiceType(ServiceType type) {
    if (_serviceType != type) {
      _serviceType = type;
      notifyListeners();
      print("RideRequestProvider: ServiceType alterado para $_serviceType");
    }
  }

  // --- CAMPOS DE STATUS, DADOS E FLUXO ---
  RideRequestStatus _status = RideRequestStatus.none;
  PlaceDetail? _origin;
  PlaceDetail? _destination;

  List<LatLng> _polylineCoordinates = [];
  String? _distanceText;
  int? _distanceValue;
  String? _durationText;
  int? _durationValue;
  LatLngBounds? _routeBounds;

  DeliveryType? _selectedDeliveryType;
  VehicleType? _selectedVehicleType;
  PaymentType? _selectedPaymentType;
  double _calculatedPrice = 0.0;
  String? _paymentChangeFor;

  // Novos campos para entrega de produto
  String? _receiverName;
  String? _receiverCell;
  String? _itemType;
  String? _itemObservation;

  // Detalhes do Entregador
  String? _assignedDriverId;
  String? _assignedDriverName;
  String? _assignedDriverVehicleDetails;
  String? _assignedDriverProfileImageUrl;
  LatLng? _assignedDriverLocation;
  String? _assignedDriverEtaToPickup;
  String? _assignedDriverEtaToDestination;

  String? _currentRideId;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  RideRequestStatus get status => _status;
  PlaceDetail? get origin => _origin;
  PlaceDetail? get destination => _destination;
  List<LatLng> get polylinePoints => _polylineCoordinates;
  String? get distanceText => _distanceText;
  int? get distanceValue => _distanceValue;
  String? get durationText => _durationText;
  int? get durationValue => _durationValue;
  LatLngBounds? get routeBounds => _routeBounds;
  DeliveryType? get selectedDeliveryType => _selectedDeliveryType;
  VehicleType? get selectedVehicleType => _selectedVehicleType;
  PaymentType? get selectedPaymentType => _selectedPaymentType;
  double get calculatedPrice => _calculatedPrice;
  String? get paymentChangeFor => _paymentChangeFor;

  String? get assignedDriverId => _assignedDriverId;
  String? get assignedDriverName => _assignedDriverName;
  String? get assignedDriverVehicleDetails => _assignedDriverVehicleDetails;
  String? get assignedDriverProfileImageUrl => _assignedDriverProfileImageUrl;
  LatLng? get assignedDriverLocation => _assignedDriverLocation;
  String? get assignedDriverEtaToPickup => _assignedDriverEtaToPickup;
  String? get assignedDriverEtaToDestination => _assignedDriverEtaToDestination;

  String? get currentRideId => _currentRideId;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // Getters para dados de entrega de produto
  String? get receiverName => _receiverName;
  String? get receiverCell => _receiverCell;
  String? get itemType => _itemType;
  String? get itemObservation => _itemObservation;

  RideRequestProvider(this._googleMapsService, this._firestoreService);

  void _setLoading(bool loading, {bool notify = true}) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    if (notify) notifyListeners();
  }

  void _setError(String message, {bool notify = true}) {
    _errorMessage = message;
    _updateStatus(RideRequestStatus.error, notify: false);
    _isLoading = false;
    if (notify) notifyListeners();
    print("RideRequestProvider Error: $message");
  }

  void _updateStatus(RideRequestStatus newStatus, {bool notify = true}) {
    if (_status == newStatus) return;
    _status = newStatus;
    print("RideRequestProvider Status: $_status");
    if (notify) notifyListeners();
  }

  void clearRideDetailsAndReset() {
    _origin = null;
    _destination = null;
    _polylineCoordinates = [];
    _distanceText = null;
    _distanceValue = null;
    _durationText = null;
    _durationValue = null;
    _routeBounds = null;
    _selectedDeliveryType = null;
    _selectedVehicleType = null;
    _selectedPaymentType = null;
    _calculatedPrice = 0.0;
    _paymentChangeFor = null;
    _assignedDriverId = null;
    _assignedDriverName = null;
    _assignedDriverVehicleDetails = null;
    _assignedDriverProfileImageUrl = null;
    _assignedDriverLocation = null;
    _assignedDriverEtaToPickup = null;
    _assignedDriverEtaToDestination = null;
    _currentRideId = null;
    _errorMessage = null;
    _isLoading = false;
    _serviceType = ServiceType.passenger;
    // Limpa também campos de entrega de produto
    _receiverName = null;
    _receiverCell = null;
    _itemType = null;
    _itemObservation = null;
    _updateStatus(RideRequestStatus.none);
    print("RideRequestProvider: Detalhes da corrida e estado reiniciados.");
  }

  Future<void> setOrigin(
    LatLng location,
    String name, {
    String? address,
    String? placeId,
  }) async {
    _origin = PlaceDetail(
      location: location,
      name: name,
      address: address,
      placeId: placeId,
    );
    _polylineCoordinates = [];
    _routeBounds = null;
    _distanceText = null;
    _durationText = null;
    _updateStatus(
      _destination == null
          ? RideRequestStatus.originSelected
          : RideRequestStatus.destinationSelected,
      notify: false,
    );
    notifyListeners();
    if (_destination != null) await calculateRoute();
  }

  void clearOrigin() {
    _origin = null;
    _polylineCoordinates = [];
    _routeBounds = null;
    _distanceText = null;
    _durationText = null;
    _updateStatus(
      _destination == null
          ? RideRequestStatus.none
          : RideRequestStatus.destinationSelected,
    );
  }

  Future<void> setDestination(
    LatLng location,
    String name, {
    String? address,
    String? placeId,
  }) async {
    _destination = PlaceDetail(
      location: location,
      name: name,
      address: address,
      placeId: placeId,
    );
    _updateStatus(RideRequestStatus.destinationSelected, notify: false);
    notifyListeners();
    if (_origin != null) await calculateRoute();
  }

  void clearDestination() {
    _destination = null;
    _polylineCoordinates = [];
    _routeBounds = null;
    _distanceText = null;
    _durationText = null;
    _updateStatus(
      _origin == null
          ? RideRequestStatus.none
          : RideRequestStatus.originSelected,
    );
  }

  Future<List<Map<String, String>>> getAutocompleteSuggestions(
    String query, {
    String? sessionToken,
  }) async {
    if (query.length < 3) return [];
    try {
      return await _googleMapsService.searchPlaceAutoComplete(
        query,
        sessionToken: sessionToken,
      );
    } catch (e) {
      print("RideRequestProvider: Erro ao buscar sugestões de autocompletar: $e");
      throw e;
    }
  }

  Future<PlaceDetail?> getPlaceDetailsFromPlaceId(
    String placeId,
    String description, {
    String? sessionToken,
  }) async {
    if (placeId.isEmpty) return null;
    try {
      final latLng = await _googleMapsService.getPlaceDetails(
        placeId,
        sessionToken: sessionToken,
      );
      if (latLng != null) {
        return PlaceDetail(
          location: latLng,
          name: description,
          placeId: placeId,
          address: description,
        );
      }
      return null;
    } catch (e) {
      print("RideRequestProvider: Erro ao obter detalhes do local pelo Place ID: $e");
      throw e;
    }
  }

  Future<void> calculateRoute() async {
    if (_origin == null || _destination == null) {
      _setError("Origem e Destino devem ser definidos para calcular a rota.");
      return;
    }
    _setLoading(true, notify: false);
    _updateStatus(RideRequestStatus.calculatingRoute);
    _errorMessage = null;
    try {
      final directionsData = await _googleMapsService.getDirections(
        _origin!.location,
        _destination!.location,
      );
      if (directionsData != null) {
        _polylineCoordinates =
            directionsData['polyline_points'] as List<LatLng>? ?? [];
        _distanceText = directionsData['distance_text'] as String?;
        _distanceValue = directionsData['distance_value'] as int?;
        _durationText = directionsData['duration_text'] as String?;
        _durationValue = directionsData['duration_value'] as int?;
        _routeBounds = directionsData['bounds'] as LatLngBounds?;
        _updateStatus(RideRequestStatus.routeCalculated);
      } else {
        _polylineCoordinates = [];
        _setError("Não foi possível calcular a rota. Verifique os endereços.");
      }
    } catch (e) {
      _polylineCoordinates = [];
      _setError("Erro ao calcular rota: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  void setDeliveryOptions({
    required DeliveryType deliveryType,
    required VehicleType vehicleType,
    required PaymentType paymentType,
    required double calculatedPrice,
    String? changeFor,
    // Novos parâmetros opcionais para entrega de produto:
    String? receiverName,
    String? receiverCell,
    String? itemType,
    String? itemObservation,
  }) {
    _selectedDeliveryType = deliveryType;
    _selectedVehicleType = vehicleType;
    _selectedPaymentType = paymentType;
    _calculatedPrice = calculatedPrice;
    _paymentChangeFor = changeFor;
    // Salva os dados da entrega de produto, se vierem
    _receiverName = receiverName;
    _receiverCell = receiverCell;
    _itemType = itemType;
    _itemObservation = itemObservation;
    _updateStatus(RideRequestStatus.selectingOptions);
    print(
      "RideRequestProvider: Opções de entrega definidas. Preço: R\$$_calculatedPrice. Troco para: $_paymentChangeFor",
    );
    notifyListeners();
  }

  void updateCalculatedPrice(double price) {
    if (_calculatedPrice == price) return;
    _calculatedPrice = price;
    print(
      "RideRequestProvider: Preço calculado atualizado para: R\$$_calculatedPrice",
    );
    notifyListeners();
  }

  Future<void> requestRideAndFindDriver() async {
    if (_status != RideRequestStatus.selectingOptions ||
        _origin == null ||
        _destination == null) {
      _setError(
        "Complete a seleção de origem, destino e opções de entrega primeiro.",
      );
      return;
    }
    _setLoading(true, notify: false);
    _updateStatus(RideRequestStatus.searchingDriver);
    _errorMessage = null;

    _currentRideId = "levva_ride_${DateTime.now().millisecondsSinceEpoch}";
    print(
      "RideRequestProvider: Iniciando busca por entregador para a corrida ID: $_currentRideId",
    );

    await Future.delayed(const Duration(seconds: 3));

    _assignedDriverId = "driver_id_${DateTime.now().second}";
    _assignedDriverName = _serviceType == ServiceType.passenger
        ? "Motorista Levva"
        : "Ana Transportes";
    _assignedDriverVehicleDetails = _serviceType == ServiceType.passenger
        ? "Carro Sedan - Placa LEV-0A99"
        : "Moto Yamaha Factor - Placa LEV-0A00";
    _assignedDriverProfileImageUrl = _serviceType == ServiceType.passenger
        ? "https://placehold.co/100x100/4FC3F7/01579B?text=Passageiro"
        : "https://placehold.co/100x100/D1C4E9/4527A0&text=Ana";
    if (_origin != null) {
      _assignedDriverLocation = LatLng(
        _origin!.location.latitude + 0.004,
        _origin!.location.longitude - 0.003,
      );
    }
    _updateStatus(RideRequestStatus.driverAssigned);
    _setLoading(false);

    print(
      "RideRequestProvider: Entregador/Motorista ${_assignedDriverName} designado para a corrida $_currentRideId.",
    );
    confirmRideAcceptance();
  }

  void confirmRideAcceptance() {
    if (_status != RideRequestStatus.driverFound &&
        _status != RideRequestStatus.driverAssigned) {
      print(
        "RideRequestProvider: Não é possível confirmar a corrida neste estado: $_status",
      );
      return;
    }
    _updateStatus(RideRequestStatus.rideAccepted);
    print(
      "RideRequestProvider: Corrida $_currentRideId aceita/confirmada. Entregador/Motorista será notificado (simulação).",
    );

    _simulateDriverToPickup();
  }

  Future<void> _simulateDriverToPickup() async {
    _updateStatus(RideRequestStatus.driverEnRouteToPickup);
    _assignedDriverEtaToPickup = "4 min";
    notifyListeners();

    print(
      "RideRequestProvider: Entregador/Motorista a caminho da coleta. ETA: $_assignedDriverEtaToPickup",
    );
    for (int i = 0; i < 4; i++) {
      if (_status != RideRequestStatus.driverEnRouteToPickup)
        return;
      await Future.delayed(const Duration(seconds: 3));
      if (_origin != null && _assignedDriverLocation != null) {
        _assignedDriverLocation = LatLng(
          _assignedDriverLocation!.latitude -
              (_assignedDriverLocation!.latitude - _origin!.location.latitude) *
                  0.25,
          _assignedDriverLocation!.longitude -
              (_assignedDriverLocation!.longitude -
                      _origin!.location.longitude) *
                  0.25,
        );
      }
      _assignedDriverEtaToPickup = "${3 - i} min";
      if (i == 3) _assignedDriverEtaToPickup = "Chegando...";
      notifyListeners();
    }

    if (_status != RideRequestStatus.driverEnRouteToPickup)
      return;

    _updateStatus(RideRequestStatus.driverArrivedAtPickup);
    _assignedDriverEtaToPickup = "Chegou!";
    if (_origin != null)
      _assignedDriverLocation = _origin!.location;
    notifyListeners();
    print("RideRequestProvider: Entregador/Motorista chegou no local de coleta.");

    await Future.delayed(const Duration(seconds: 4));
    if (_status != RideRequestStatus.driverArrivedAtPickup)
      return;

    _simulateRideToDestination();
  }

  Future<void> _simulateRideToDestination() async {
    _updateStatus(RideRequestStatus.rideInProgressToDestination);
    _assignedDriverEtaToDestination = "8 min";
    _assignedDriverEtaToPickup = null;
    notifyListeners();
    print(
      "RideRequestProvider: Em rota para o destino. ETA: $_assignedDriverEtaToDestination",
    );

    if (_destination != null && _assignedDriverLocation != null) {
      double startLat = _assignedDriverLocation!.latitude;
      double startLng = _assignedDriverLocation!.longitude;
      double endLat = _destination!.location.latitude;
      double endLng = _destination!.location.longitude;

      for (int i = 1; i <= 4; i++) {
        if (_status != RideRequestStatus.rideInProgressToDestination) return;
        await Future.delayed(const Duration(seconds: 4));
        _assignedDriverLocation = LatLng(
          startLat + (endLat - startLat) * (i / 4.0),
          startLng + (endLng - startLng) * (i / 4.0),
        );
        _assignedDriverEtaToDestination = "${8 - i * 2} min";
        if (i == 4) _assignedDriverEtaToDestination = "Chegando...";
        notifyListeners();
        print(
          "RideRequestProvider: Posição do entregador/motorista atualizada: ${_assignedDriverLocation}. ETA Destino: ${_assignedDriverEtaToDestination}",
        );
      }
    } else {
      await Future.delayed(const Duration(seconds: 16));
    }

    if (_status != RideRequestStatus.rideInProgressToDestination) return;

    completeRide();
  }

  Future<void> completeRide() async {
    _updateStatus(RideRequestStatus.rideCompleted);
    _assignedDriverEtaToDestination = "Entrega/Viagem Concluída!";
    if (_destination != null)
      _assignedDriverLocation = _destination!.location;
    notifyListeners();
    print("RideRequestProvider: Corrida ID $_currentRideId completada!");

    await _saveCurrentRideToHistory(RideHistoryStatus.completed);

    Future.delayed(const Duration(seconds: 4), () {
      if (_status == RideRequestStatus.rideCompleted) {
        clearRideDetailsAndReset();
      }
    });
  }

  Future<void> cancelRideByUser() async {
    if (_status.index >= RideRequestStatus.rideCompleted.index &&
        _status.index <= RideRequestStatus.rideFailed.index) {
      print(
        "RideRequestProvider: Corrida $_currentRideId já finalizada ou formalmente cancelada, não pode cancelar novamente.",
      );
      return;
    }

    RideRequestStatus previousStatus = _status;
    _updateStatus(RideRequestStatus.rideCancelledByUser);
    print(
      "RideRequestProvider: Corrida $_currentRideId cancelada pelo usuário.",
    );

    if (_currentRideId != null &&
        previousStatus.index >= RideRequestStatus.searchingDriver.index) {
      await _saveCurrentRideToHistory(RideHistoryStatus.cancelled);
    }

    clearRideDetailsAndReset();
  }

  Future<void> _saveCurrentRideToHistory(
    RideHistoryStatus historyStatus,
  ) async {
    if (_origin == null || _destination == null || _currentRideId == null) {
      print(
        "RideRequestProvider: Informações insuficientes para salvar corrida no histórico.",
      );
      return;
    }
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print(
        "RideRequestProvider: Usuário não logado, não é possível salvar histórico.",
      );
      return;
    }

    final rideDetail = RideDetailModel(
      rideId: _currentRideId!,
      originName: _origin!.name,
      destinationName: _destination!.name,
      originLocation: _origin!.location,
      destinationLocation: _destination!.location,
      rideDate: Timestamp.now(),
      price: _calculatedPrice,
      status: historyStatus,
      driverName: _assignedDriverName,
      vehicleDetails: _assignedDriverVehicleDetails,
    );

    try {
      await _firestoreService.saveRideToHistory(currentUser.uid, rideDetail);
      print(
        "RideRequestProvider: Corrida ID ${_currentRideId} 'salva' no histórico do usuário ${currentUser.uid} com status $historyStatus.",
      );
    } catch (e) {
      print(
        "RideRequestProvider: Erro ao tentar salvar corrida ID ${_currentRideId} no histórico: $e",
      );
    }
  }

  void cancelSearchForDriver() {
    if (_status == RideRequestStatus.searchingDriver ||
        _status == RideRequestStatus.driverFound ||
        _status == RideRequestStatus.driverAssigned) {
      _setLoading(false);
      _updateStatus(RideRequestStatus.selectingOptions);
      _errorMessage = null;
      _currentRideId = null;
      _assignedDriverId = null;
      _assignedDriverName = null;
      _assignedDriverVehicleDetails = null;
      _assignedDriverProfileImageUrl = null;
      _assignedDriverLocation = null;
      print("RideRequestProvider: Busca por entregador/motorista cancelada pelo usuário.");
    }
  }

  void setDestinationAddress(String address) {}

  void setPassengerOptions({required String passengerName, required String passengerCpf, required String passengerPhone, required PaymentType paymentType, required bool isForMe}) {}
}