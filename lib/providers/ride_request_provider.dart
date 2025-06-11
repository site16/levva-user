import 'dart:async';
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

  ServiceType _serviceType = ServiceType.passenger;
  ServiceType get serviceType => _serviceType;
  void setServiceType(ServiceType type) {
    if (_serviceType != type) {
      _serviceType = type;
      notifyListeners();
      print("RideRequestProvider: ServiceType alterado para $_serviceType");
    }
  }

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

  String? _receiverName;
  String? _receiverCell;
  String? _itemType;
  String? _itemObservation;

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

  // --- Firestore order listener ---
  StreamSubscription<DocumentSnapshot>? _orderListener;

  // Novo: Armazena o código de confirmação gerado ao criar a corrida
  String? _confirmationCode;
  String? get confirmationCode => _confirmationCode;

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
    _receiverName = null;
    _receiverCell = null;
    _itemType = null;
    _itemObservation = null;
    _confirmationCode = null;
    _orderListener?.cancel();
    _updateStatus(RideRequestStatus.none);
    print("RideRequestProvider: Detalhes da corrida e estado reiniciados.");
  }

  // Função de mapeamento para paymentMethod conforme backend
  String mapPaymentType(PaymentType? type) {
    switch (type) {
      case PaymentType.dinheiro:
        return 'cash';
      case PaymentType.cartao:
      case PaymentType.cartaoCredito:
      case PaymentType.cartaoDebito:
        return 'cardMachine';
      case PaymentType.pix:
      case PaymentType.carteiraLevva:
        return 'online';
      default:
        return 'cash';
    }
  }

  // Função de mapeamento para type conforme backend
  String mapServiceType(DeliveryType? type) {
    switch (type) {
      case DeliveryType.levvaRapido:
        return 'package';
      case DeliveryType.levvaMoto:
        return 'moto';
      // Caso adicione DeliveryType.levvaFood, mapear para 'food'
      default:
        return 'package';
    }
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
      print(
        "RideRequestProvider: Erro ao buscar sugestões de autocompletar: $e",
      );
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
      print(
        "RideRequestProvider: Erro ao obter detalhes do local pelo Place ID: $e",
      );
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

  /// Criação real do pedido no Firestore (orders)
  Future<bool> requestRideAndFindDriver() async {
    if (_status != RideRequestStatus.selectingOptions ||
        _origin == null ||
        _destination == null) {
      _setError(
        "Complete a seleção de origem, destino e opções de entrega primeiro.",
      );
      return false;
    }

    _setLoading(true, notify: false);
    _updateStatus(RideRequestStatus.searchingDriver);
    _errorMessage = null;

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _setError("Usuário não autenticado.");
      return false;
    }

    try {
      // Geração do código de confirmação: 4 últimos dígitos do telefone do destinatário, ou aleatório
      String? phone = _receiverCell;
      String confirmationCode;
      if (phone != null && phone.replaceAll(RegExp(r'[^0-9]'), '').length >= 4) {
        String numericPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
        confirmationCode = numericPhone.substring(numericPhone.length - 4);
      } else {
        // fallback: gerar código aleatório de 4 dígitos
        confirmationCode = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
      }
      _confirmationCode = confirmationCode;

      Map<String, dynamic> orderData = {
        "userId": currentUser.uid,
        "type": mapServiceType(_selectedDeliveryType), // <-- CORRETO!
        "pickupAddress": _origin?.address ?? _origin?.name ?? "",
        "pickupLatitude": _origin?.location.latitude,
        "pickupLongitude": _origin?.location.longitude,
        "deliveryAddress": _destination?.address ?? _destination?.name ?? "",
        "deliveryLatitude": _destination?.location.latitude,
        "deliveryLongitude": _destination?.location.longitude,
        "estimatedValue": _calculatedPrice,
        "distanceToPickup": 0.0,
        "routeDistance": (_distanceValue ?? 0) / 1000.0,
        "status": "pendingAcceptance",
        "creationTime": FieldValue.serverTimestamp(),
        "customerName": currentUser.displayName ?? "",
        "recipientPhoneNumber": _receiverCell ?? "",
        "receiverName": _receiverName ?? "",
        "suitableVehicleTypes": [_selectedVehicleType?.name ?? "moto"],
        "paymentMethod": mapPaymentType(_selectedPaymentType), // <-- CORRETO!
        "notes": _itemObservation ?? "",
        "driverId": null,
        "confirmationCode": confirmationCode, // <-- NOVO CAMPO
      };

      DocumentReference doc = await FirebaseFirestore.instance
          .collection('orders')
          .add(orderData);

      _currentRideId = doc.id;
      print(
        "RideRequestProvider: Pedido criado no Firestore com id $_currentRideId, confirmationCode=$confirmationCode",
      );

      listenToOrderStatus(_currentRideId!);

      _updateStatus(RideRequestStatus.searchingDriver);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Erro ao criar pedido no servidor: $e");
      return false;
    }
  }

  /// Mapeamento robusto: status do Firestore -> enum local RideRequestStatus
  RideRequestStatus _statusFromFirestore(String statusString) {
    switch (statusString) {
      case 'pendingAcceptance':
        return RideRequestStatus.searchingDriver;
      case 'toPickup':
        return RideRequestStatus.driverEnRouteToPickup;
      case 'atPickup':
      case 'awaitingPickup':
        return RideRequestStatus.driverArrivedAtPickup;
      case 'driverFound':
        return RideRequestStatus.driverFound;
      case 'driverAssigned':
        return RideRequestStatus.driverAssigned;
      case 'rideAccepted':
        return RideRequestStatus.rideAccepted;
      case 'toDeliver':
      case 'atDelivery':
        return RideRequestStatus.rideInProgressToDestination;
      case 'completed':
        return RideRequestStatus.rideCompleted;
      case 'cancelledByCustomer':
        return RideRequestStatus.rideCancelledByUser;
      case 'cancelledByDriver':
      case 'cancelledBySystem':
        return RideRequestStatus.rideCancelledByDriver;
      case 'cancellationRequested':
        return RideRequestStatus.rideCancelledByUser;
      default:
        try {
          return RideRequestStatus.values.firstWhere(
            (e) => e.name == statusString,
          );
        } catch (_) {
          return RideRequestStatus.unknown;
        }
    }
  }

  /// Listener em tempo real para atualizações do pedido no Firestore
  void listenToOrderStatus(String orderId) {
    _orderListener?.cancel();
    _orderListener = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final statusString = data['status'] as String? ?? '';
            _status = _statusFromFirestore(statusString);
            _assignedDriverId = data['driverId'] as String?;
            _assignedDriverName = data['driverName'] as String?;
            _assignedDriverVehicleDetails =
                data['driverVehicleDetails'] as String?;
            _assignedDriverProfileImageUrl =
                data['driverProfileImageUrl'] as String?;
            // Atualizar confirmationCode, se presente, do backend
            if (data.containsKey('confirmationCode')) {
              _confirmationCode = data['confirmationCode'] as String?;
            }
            // Se salvar localização, eta etc. do entregador no pedido, pegue aqui também:
            // _assignedDriverLocation = ...;
            // _assignedDriverEtaToPickup = ...;
            // _assignedDriverEtaToDestination = ...;
            notifyListeners();
          }
        });
  }

  Future<void> cancelRideByUser() async {
    RideRequestStatus previousStatus = _status;
    _updateStatus(RideRequestStatus.rideCancelledByUser);
    print(
      "RideRequestProvider: Corrida $_currentRideId cancelada pelo usuário.",
    );
    clearRideDetailsAndReset();
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
      _orderListener?.cancel();
      print(
        "RideRequestProvider: Busca por entregador/motorista cancelada pelo usuário.",
      );
    }
  }

  void setDestinationAddress(String address) {}

  void setPassengerOptions({
    required String passengerName,
    required String passengerCpf,
    required String passengerPhone,
    required PaymentType paymentType,
    required bool isForMe,
  }) {}

  @override
  void dispose() {
    _orderListener?.cancel();
    super.dispose();
  }
}