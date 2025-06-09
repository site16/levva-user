import 'package:flutter/material.dart';
import 'package:levva/models/enums.dart';
import '../models/ride_detail_model.dart';
import '../services/firestore_service.dart';
import 'ride_request_provider.dart'; // Para verificar se a corrida é "ao vivo" e obter status/dados ao vivo

class RideDetailProvider with ChangeNotifier {
  final String rideId;
  final String userId;
  final FirestoreService _firestoreService;
  final RideRequestProvider
  _rideRequestProvider; // Para interagir com a corrida ativa

  RideDetailModel? _rideDetails; // Detalhes da corrida buscados do Firestore
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  RideDetailProvider({
    required this.userId,
    required this.rideId,
    required FirestoreService firestoreService,
    required RideRequestProvider rideRequestProvider,
  }) : _firestoreService = firestoreService,
       _rideRequestProvider = rideRequestProvider {
    print("RideDetailProvider: Inicializado para rideId: $rideId");
    _fetchRideDetails(); // Busca os detalhes assim que o provider é criado

    // Ouve mudanças no RideRequestProvider para atualizar a UI se esta for a corrida ativa
    _rideRequestProvider.addListener(_updateLiveRideDetails);
  }

  // Getters
  RideDetailModel? get rideDetails => _rideDetails;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Verifica se a corrida detalhada por este provider é a corrida atualmente ativa no RideRequestProvider.
  bool get isLiveRide => _rideRequestProvider.currentRideId == rideId;

  /// Determina o status a ser exibido na tela, priorizando o status ao vivo se for a corrida ativa.
  RideRequestStatus? get currentDisplayStatus {
    if (isLiveRide) {
      return _rideRequestProvider.status; // Status da corrida ao vivo
    }
    // Se for uma corrida do histórico, converte RideHistoryStatus para RideRequestStatus
    if (_rideDetails != null) {
      switch (_rideDetails!.status) {
        case RideHistoryStatus.completed:
          return RideRequestStatus.rideCompleted;
        case RideHistoryStatus.cancelled:
          // Pode-se ter diferentes status de cancelamento no RideRequestStatus se necessário
          return RideRequestStatus
              .rideCancelledByUser; // Ou um RideRequestStatus.rideCancelled genérico
        case RideHistoryStatus.inProgress:
          // Para uma corrida histórica marcada como "inProgress", pode-se assumir que
          // o último estado conhecido foi em andamento para o destino, ou um estado pendente.
          return RideRequestStatus.rideInProgressToDestination;
      }
    }
    return null;
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> _fetchRideDetails() async {
    if (_isDisposed) return;
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners(); // Notifica que o carregamento começou

    try {
      final fetchedDetails = await _firestoreService.getRideDetailsById(userId, rideId); // <<< CORRIGIDO: Adicionado this.userId
      if (_isDisposed) return;

      if (fetchedDetails != null) {
        _rideDetails = fetchedDetails;
        _errorMessage = null;
        print(
          "RideDetailProvider: Detalhes da corrida $rideId carregados: ${fetchedDetails.originName} -> ${fetchedDetails.destinationName}",
        );
      } else {
        _errorMessage = "Detalhes da corrida com ID $rideId não encontrados.";
        _rideDetails = null; // Garante que não há dados antigos
        print(
          "RideDetailProvider: Detalhes da corrida $rideId não encontrados.",
        );
      }
    } catch (e, s) {
      if (_isDisposed) return;
      _errorMessage =
          "Erro ao buscar detalhes da corrida $rideId: ${e.toString()}";
      _rideDetails = null;
      print(
        "RideDetailProvider: Erro em _fetchRideDetails para $rideId: $e\n$s",
      );
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotifyListeners(); // Notifica que o carregamento terminou (com sucesso ou erro)
      }
    }
  }

  /// Listener para o RideRequestProvider. Se esta for a corrida ativa,
  /// notifica os ouvintes (a RideDetailScreen) para que ela possa reconstruir
  /// e pegar os dados mais recentes do RideRequestProvider.
  void _updateLiveRideDetails() {
    if (_isDisposed) return;

    if (isLiveRide) {
      print(
        "RideDetailProvider: Atualização ao vivo para rideId $rideId recebida do RideRequestProvider. Novo status: ${_rideRequestProvider.status}",
      );
      // A RideDetailScreen, ao consumir este provider e o RideRequestProvider,
      // já vai pegar os dados mais recentes ao reconstruir.
      // Apenas notificar que algo mudou é suficiente para que os Consumers/Selectors reajam.
      _safeNotifyListeners();
    }
  }

  /// Permite que a UI solicite uma nova busca dos detalhes da corrida.
  Future<void> refreshDetails() async {
    print(
      "RideDetailProvider: Tentando recarregar detalhes para rideId: $rideId",
    );
    await _fetchRideDetails();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _rideRequestProvider.removeListener(
      _updateLiveRideDetails,
    ); // Remove o listener!
    print("RideDetailProvider: Disposed para rideId: $rideId");
    super.dispose();
  }
}
