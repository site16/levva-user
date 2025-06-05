import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:levva/services/google_maps_service.dart';

import '../models/enums.dart'; // Seus enums DeliveryType, VehicleType, PaymentType
import '../models/ride_detail_model.dart'; // Seu modelo RideDetailModel
import '../services/firestore_service.dart';

// Enum com todos os status detalhados da corrida (conforme o seu último envio)
enum RideRequestStatus {
  none,
  originSelected,
  destinationSelected,
  calculatingRoute,
  routeCalculated,
  selectingOptions,

  searchingDriver,
  driverFound,
  driverAssigned,

  rideAccepted,
  driverEnRouteToPickup,
  driverArrivedAtPickup,
  rideInProgressToDestination,

  rideCompleted,
  rideCancelledByUser,
  rideCancelledByDriver,
  rideFailed,

  error,
  notFound, unknown, // movido para o final com error, conforme seu último código
}

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
  String? _paymentChangeFor; // Para troco, se pagamento em dinheiro

  // Detalhes do Entregador
  String? _assignedDriverId;
  String? _assignedDriverName;
  String? _assignedDriverVehicleDetails;
  String? _assignedDriverProfileImageUrl;
  LatLng? _assignedDriverLocation;
  String? _assignedDriverEtaToPickup;
  String? _assignedDriverEtaToDestination;

  String? _currentRideId; // ID da corrida ativa

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

  // Construtor aceitando ambos os serviços
  RideRequestProvider(this._googleMapsService, this._firestoreService);

  void _setLoading(bool loading, {bool notify = true}) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    if (notify) notifyListeners();
  }

  void _setError(String message, {bool notify = true}) {
    _errorMessage = message;
    _updateStatus(
      RideRequestStatus.error,
      notify: false,
    ); // Atualiza status para erro
    _isLoading = false; // Garante que loading é falso em caso de erro
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
    _updateStatus(RideRequestStatus.none); // Notifica ouvintes
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
    notifyListeners(); // Notifica após atualizar o origin e o status
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
    // Atualiza o status baseado se a origem já foi selecionada
    _updateStatus(
      _origin == null
          ? RideRequestStatus.destinationSelected
          : RideRequestStatus.destinationSelected,
      notify: false,
    );
    notifyListeners(); // Notifica após atualizar o destino e o status
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
      throw e; // Re-lança para que a UI possa tratar
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
      throw e; // Re-lança para que a UI possa tratar
    }
  }

  Future<void> calculateRoute() async {
    if (_origin == null || _destination == null) {
      _setError("Origem e Destino devem ser definidos para calcular a rota.");
      return;
    }
    _setLoading(
      true,
      notify: false,
    ); // Evita notificação duplicada se _updateStatus notificar
    _updateStatus(RideRequestStatus.calculatingRoute);
    _errorMessage = null; // Limpa erro anterior
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
        _polylineCoordinates = []; // Garante que não há polilinhas antigas
        _setError("Não foi possível calcular a rota. Verifique os endereços.");
      }
    } catch (e) {
      _polylineCoordinates = [];
      _setError("Erro ao calcular rota: ${e.toString()}");
    } finally {
      _setLoading(false); // Notifica ao final, independentemente do resultado
    }
  }

  void setDeliveryOptions({
    required DeliveryType deliveryType,
    required VehicleType vehicleType,
    required PaymentType paymentType,
    required double calculatedPrice,
    String? changeFor, // Troco para qual valor, se pagamento em dinheiro
  }) {
    _selectedDeliveryType = deliveryType;
    _selectedVehicleType = vehicleType;
    _selectedPaymentType = paymentType;
    _calculatedPrice = calculatedPrice;
    _paymentChangeFor = changeFor; // Armazena a informação de troco
    _updateStatus(RideRequestStatus.selectingOptions);
    print(
      "RideRequestProvider: Opções de entrega definidas. Preço: R\$$_calculatedPrice. Troco para: $_paymentChangeFor",
    );
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

    // Simulação de criação de ID de corrida
    _currentRideId = "levva_ride_${DateTime.now().millisecondsSinceEpoch}";
    print(
      "RideRequestProvider: Iniciando busca por entregador para a corrida ID: $_currentRideId",
    );

    // Simulação de busca por entregador
    await Future.delayed(const Duration(seconds: 3)); // Simula tempo de busca

    // Simulação de dados do entregador encontrado
    _assignedDriverId = "driver_id_${DateTime.now().second}"; // ID Fictício
    _assignedDriverName = "Ana Transportes"; // Nome Fictício
    _assignedDriverVehicleDetails =
        "Moto Yamaha Factor - Placa LEV-0A00"; // Detalhes Fictícios
    _assignedDriverProfileImageUrl =
        "https://placehold.co/100x100/D1C4E9/4527A0&text=Ana"; // URL Fictícia
    if (_origin != null) {
      // Simula posição inicial do entregador perto da origem
      _assignedDriverLocation = LatLng(
        _origin!.location.latitude + 0.004,
        _origin!.location.longitude - 0.003,
      );
    }
    _updateStatus(
      RideRequestStatus.driverAssigned,
    ); // Novo status indicando que um motorista foi designado
    _setLoading(false); // Para de carregar após "encontrar" o motorista

    print(
      "RideRequestProvider: Entregador ${_assignedDriverName} designado para a corrida $_currentRideId.",
    );
    // Procede para a confirmação e aceitação da corrida
    confirmRideAcceptance();
  }

  void confirmRideAcceptance() {
    // Permite confirmação se motorista foi encontrado ou já designado
    if (_status != RideRequestStatus.driverFound &&
        _status != RideRequestStatus.driverAssigned) {
      print(
        "RideRequestProvider: Não é possível confirmar a corrida neste estado: $_status",
      );
      return;
    }
    _updateStatus(RideRequestStatus.rideAccepted);
    print(
      "RideRequestProvider: Corrida $_currentRideId aceita/confirmada. Entregador será notificado (simulação).",
    );

    // Inicia simulação do entregador indo para o local de coleta
    _simulateDriverToPickup();
  }

  // Simulação do entregador indo para o local de coleta
  Future<void> _simulateDriverToPickup() async {
    _updateStatus(RideRequestStatus.driverEnRouteToPickup);
    _assignedDriverEtaToPickup = "4 min";
    notifyListeners(); // Notifica para UI atualizar ETA e localização do motorista

    print(
      "RideRequestProvider: Entregador a caminho da coleta. ETA: $_assignedDriverEtaToPickup",
    );
    for (int i = 0; i < 4; i++) {
      // Simula 4 passos de atualização
      if (_status != RideRequestStatus.driverEnRouteToPickup)
        return; // Permite cancelamento
      await Future.delayed(
        const Duration(seconds: 3),
      ); // Intervalo entre atualizações
      if (_origin != null && _assignedDriverLocation != null) {
        // Simula movimento do entregador em direção à origem
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
      return; // Verifica novamente antes de mudar status

    _updateStatus(RideRequestStatus.driverArrivedAtPickup);
    _assignedDriverEtaToPickup = "Chegou!";
    if (_origin != null)
      _assignedDriverLocation =
          _origin!.location; // Coloca o motorista exatamente na origem
    notifyListeners();
    print("RideRequestProvider: Entregador chegou no local de coleta.");

    await Future.delayed(const Duration(seconds: 4)); // Simula tempo de coleta
    if (_status != RideRequestStatus.driverArrivedAtPickup)
      return; // Permite cancelamento

    // Inicia simulação da corrida para o destino
    _simulateRideToDestination();
  }

  // Simulação da corrida para o destino
  Future<void> _simulateRideToDestination() async {
    _updateStatus(RideRequestStatus.rideInProgressToDestination);
    _assignedDriverEtaToDestination = "8 min"; // ETA para o destino
    _assignedDriverEtaToPickup = null; // Limpa ETA da coleta
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
        // Simula 4 passos
        if (_status != RideRequestStatus.rideInProgressToDestination) return;
        await Future.delayed(const Duration(seconds: 4)); // Intervalo
        _assignedDriverLocation = LatLng(
          startLat +
              (endLat - startLat) * (i / 4.0), // Interpolação linear simples
          startLng + (endLng - startLng) * (i / 4.0),
        );
        _assignedDriverEtaToDestination = "${8 - i * 2} min";
        if (i == 4) _assignedDriverEtaToDestination = "Chegando...";
        notifyListeners();
        print(
          "RideRequestProvider: Posição do entregador atualizada: ${_assignedDriverLocation}. ETA Destino: ${_assignedDriverEtaToDestination}",
        );
      }
    } else {
      await Future.delayed(
        const Duration(seconds: 16),
      ); // Duração total se não houver locais
    }

    if (_status != RideRequestStatus.rideInProgressToDestination) return;

    completeRide(); // Completa a corrida
  }

  Future<void> completeRide() async {
    _updateStatus(RideRequestStatus.rideCompleted);
    _assignedDriverEtaToDestination = "Entrega Concluída!";
    if (_destination != null)
      _assignedDriverLocation = _destination!.location; // Coloca no destino
    notifyListeners();
    print("RideRequestProvider: Corrida ID $_currentRideId completada!");

    await _saveCurrentRideToHistory(RideHistoryStatus.completed);

    // Reseta o estado após um tempo para o usuário ver a conclusão
    Future.delayed(const Duration(seconds: 4), () {
      if (_status == RideRequestStatus.rideCompleted) {
        // Garante que o estado não mudou
        clearRideDetailsAndReset();
      }
    });
  }

  Future<void> cancelRideByUser() async {
    // Verifica se a corrida pode ser cancelada (não pode se já completada, falhou, etc.)
    if (_status.index >= RideRequestStatus.rideCompleted.index &&
        _status.index <= RideRequestStatus.rideFailed.index) {
      print(
        "RideRequestProvider: Corrida $_currentRideId já finalizada ou formalmente cancelada, não pode cancelar novamente.",
      );
      return;
    }

    RideRequestStatus previousStatus =
        _status; // Guarda o status anterior para lógica de save
    _updateStatus(RideRequestStatus.rideCancelledByUser);
    print(
      "RideRequestProvider: Corrida $_currentRideId cancelada pelo usuário.",
    );

    // Salva no histórico se a corrida já tinha um ID (ou seja, busca por motorista iniciada)
    if (_currentRideId != null &&
        previousStatus.index >= RideRequestStatus.searchingDriver.index) {
      await _saveCurrentRideToHistory(RideHistoryStatus.cancelled);
    }

    // Limpa todos os detalhes e reseta o estado
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
      rideDate: Timestamp.now(), // Data/hora atual da conclusão/cancelamento
      price: _calculatedPrice,
      status: historyStatus, // Status final para o histórico
      driverName: _assignedDriverName,
      vehicleDetails: _assignedDriverVehicleDetails,
      // Adicione outros campos relevantes se necessário (ex: confirmationCode)
    );

    try {
      // IMPORTANTE: Este método precisa existir no seu FirestoreService!
      await _firestoreService.saveRideToHistory(currentUser.uid, rideDetail);
      print(
        "RideRequestProvider: Corrida ID ${_currentRideId} 'salva' no histórico do usuário ${currentUser.uid} com status $historyStatus.",
      );
    } catch (e) {
      print(
        "RideRequestProvider: Erro ao tentar salvar corrida ID ${_currentRideId} no histórico: $e",
      );
      // Considere notificar o usuário ou tentar novamente, dependendo da política do app
    }
  }

  // Método para o usuário cancelar a busca por motorista
  void cancelSearchForDriver() {
    if (_status == RideRequestStatus.searchingDriver ||
        _status == RideRequestStatus.driverFound ||
        _status == RideRequestStatus.driverAssigned) {
      _setLoading(false);
      _updateStatus(
        RideRequestStatus.selectingOptions,
      ); // Volta para a tela de seleção de opções
      _errorMessage = null;
      _currentRideId = null; // Limpa o ID da corrida que estava sendo buscada
      // Limpa detalhes do motorista se algum já tivesse sido pré-assignado (no caso de driverFound/driverAssigned)
      _assignedDriverId = null;
      _assignedDriverName = null;
      _assignedDriverVehicleDetails = null;
      _assignedDriverProfileImageUrl = null;
      _assignedDriverLocation = null;
      print(
        "RideRequestProvider: Busca por entregador cancelada pelo usuário.",
      );
    }
  }

  // Os métodos searchForDriver() {} e cancelSearch() {} foram removidos pois suas lógicas
  // parecem estar implementadas em requestRideAndFindDriver() e cancelSearchForDriver() / cancelRideByUser() respectivamente.
  // Se eles tinham um propósito diferente, você pode adicioná-los novamente.
}
