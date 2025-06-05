import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/ride_detail_model.dart'; // Certifique-se que o caminho está correto
import '../services/firestore_service.dart';
import '../services/auth_service.dart'; // Importa AuthService

class RideHistoryProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthService _authService; // Dependência para obter o usuário atual

  List<RideDetailModel> _rides = [];
  bool _isLoading = false; // Campo para controlar o estado de carregamento
  String? _errorMessage;
  bool _isDisposed = false; // Flag para evitar chamadas após o dispose

  // Construtor agora recebe AuthService
  RideHistoryProvider(this._firestoreService, this._authService);

  // Getters públicos
  List<RideDetailModel> get rides => _rides;
  bool get isLoading => _isLoading; // Getter público para isLoading
  String? get errorMessage => _errorMessage;

  // Método seguro para notificar ouvintes
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      // Adia a notificação para após a fase de build, se estivermos nela.
      // Isso evita erros comuns com setState ou notifyListeners chamados durante o build.
      if (WidgetsBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) notifyListeners();
        });
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> fetchRideHistory() async {
    if (_isDisposed || _isLoading)
      return; // Não faz nada se já descartado ou carregando

    final currentUser =
        _authService.currentUser; // Obtém o usuário logado do AuthService
    if (currentUser == null) {
      _errorMessage =
          "Usuário não autenticado. Não é possível carregar o histórico.";
      _isLoading = false;
      _rides = []; // Limpa o histórico anterior
      _safeNotifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null; // Limpa erros anteriores
    _safeNotifyListeners(); // Notifica que o carregamento começou

    try {
      _rides = await _firestoreService.getRideHistory(currentUser.uid);
      // Ordena as corridas pela data mais recente primeiro (opcional, mas comum)
      _rides.sort((a, b) => b.rideDate.compareTo(a.rideDate));
      print(
        "RideHistoryProvider: Histórico de corridas carregado. ${_rides.length} corridas encontradas.",
      );
    } catch (e, s) {
      if (_isDisposed) return;
      _errorMessage =
          "Erro ao carregar o histórico de corridas: ${e.toString()}";
      _rides = []; // Garante que a lista está vazia em caso de erro
      print("RideHistoryProvider: Erro em fetchRideHistory - $e\n$s");
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotifyListeners(); // Notifica que o carregamento terminou (com sucesso ou erro)
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    print("RideHistoryProvider: Disposed.");
    super.dispose();
  }
}
