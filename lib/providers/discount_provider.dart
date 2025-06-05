// lib/providers/discount_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/discount_model.dart';
import '../services/discount_service.dart';
import 'auth_provider.dart'; // Para obter o ID do usuário

class DiscountProvider with ChangeNotifier {
  final DiscountService _discountService;
  final AuthProvider? _authProvider; // Para escutar mudanças de usuário

  List<DiscountModel> _allDiscounts = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  DiscountProvider(this._discountService, this._authProvider) {
    _authProvider?.addListener(_onAuthChanged);
    // Carrega inicialmente se o usuário já estiver logado
    if (_authProvider?.currentUser != null) {
      fetchDiscounts();
    }
  }

  List<DiscountModel> get allDiscounts => _allDiscounts;
  List<DiscountModel> get availableDiscounts =>
      _allDiscounts.where((d) => d.isValidNow).toList();
  List<DiscountModel> get usedOrExpiredDiscounts =>
      _allDiscounts.where((d) => !d.isValidNow).toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _onAuthChanged() {
    if (_authProvider?.currentUser != null) {
      fetchDiscounts(); // Busca descontos quando o usuário loga
    } else {
      // Limpa os descontos se o usuário deslogar
      _allDiscounts = [];
      _isLoading = false;
      _errorMessage = null;
      _safeNotifyListeners();
    }
  }

  Future<void> fetchDiscounts() async {
    final userId = _authProvider?.currentUser?.uid;
    if (userId == null) {
      _allDiscounts = [];
      _errorMessage = "Usuário não autenticado para buscar descontos.";
      _safeNotifyListeners();
      return;
    }

    if (_isLoading || _isDisposed) return;

    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _allDiscounts = await _discountService.getDiscountsForUser(userId);
      // Ordena: válidos primeiro, depois por data de expiração mais próxima
      _allDiscounts.sort((a, b) {
        if (a.isValidNow && !b.isValidNow) return -1;
        if (!a.isValidNow && b.isValidNow) return 1;
        return a.validUntil.compareTo(b.validUntil);
      });
    } catch (e) {
      _errorMessage = "Não foi possível carregar os descontos: ${e.toString()}";
      _allDiscounts = [];
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      // Verifica se o widget tree está sendo construído/desenhado
      if (WidgetsBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        // Adiciona o notifyListeners para o final da frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) notifyListeners();
        });
      } else {
        // Pode notificar diretamente se não estiver no meio de uma build/layout/paint
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }
}
