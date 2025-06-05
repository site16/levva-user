// TODO Implement this library.
// lib/providers/levva_pay_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para o tipo Timestamp
import '../models/transaction_model.dart'; // Importa o seu modelo de transação

class LevvaPayProvider with ChangeNotifier {
  double _currentBalance =
      125.50; // Saldo simulado inicial, como no seu artefato
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false; // Para evitar chamadas após o dispose

  LevvaPayProvider() {
    // Carrega as transações simuladas quando o provider é instanciado
    _fetchSimulatedTransactions();
  }

  // Getters para acessar os dados de fora
  double get currentBalance => _currentBalance;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Método seguro para notificar os ouvintes, verificando se o provider foi descartado
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      // Garante que notifyListeners seja chamado após a fase de build, se necessário
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) {
          // Verifica novamente, pois o callback é assíncrono
          notifyListeners();
        }
      });
    }
  }

  // Método para buscar/carregar as transações (atualmente simuladas)
  void _fetchSimulatedTransactions() {
    if (_isDisposed || _isLoading)
      return; // Não faz nada se já estiver carregando ou descartado
    _isLoading = true;
    _errorMessage = null; // Limpa erros anteriores
    _safeNotifyListeners(); // Notifica que o carregamento começou

    // Simula um atraso de rede
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_isDisposed) return; // Verifica novamente após o delay

      // Dados simulados (baseados no seu artefato)
      _transactions = [
        TransactionModel(
          id: 'txn1',
          description: 'Corrida para Centro',
          amount: -15.50,
          date: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          ),
          type: TransactionType.gastoCorrida,
          rideId: 'ride1_simulada',
        ),
        TransactionModel(
          id: 'txn2',
          description: 'Bônus de boas-vindas',
          amount: 20.00,
          date: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 5)),
          ),
          type: TransactionType.bonus,
        ),
        TransactionModel(
          id: 'txn3',
          description: 'Corrida para Shopping',
          amount: -8.75,
          date: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2, hours: 5)),
          ),
          type: TransactionType.gastoCorrida,
          rideId: 'ride2_simulada',
        ),
        TransactionModel(
          id: 'txn4',
          description: 'Corrida Supermercado',
          amount: -7.20,
          date: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 10)),
          ),
          type: TransactionType.gastoCorrida,
          rideId: 'ride4_simulada',
        ),
        TransactionModel(
          id: 'txn5',
          description: 'Depósito Simulado',
          amount: 150.00,
          date: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 7)),
          ),
          type: TransactionType.deposito,
        ),
        TransactionModel(
          id: 'txn6',
          description: 'Saque Simulado',
          amount: -50.00,
          date: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 3)),
          ),
          type: TransactionType.saque,
        ),
      ];
      // Ordena as transações pela data mais recente primeiro
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      _isLoading = false; // Finaliza o carregamento
      _safeNotifyListeners(); // Notifica que os dados foram carregados
      print(
        "LevvaPayProvider: Transações simuladas carregadas. Saldo: $_currentBalance",
      );
    });
  }

  /// Permite que a UI solicite uma atualização das transações.
  Future<void> refreshTransactions() async {
    // Em uma aplicação real, aqui você chamaria seu backend ou Firestore
    // para buscar as transações e o saldo atualizados.
    // Por enquanto, apenas recarrega os dados simulados.
    print("LevvaPayProvider: Refreshing transactions...");
    _fetchSimulatedTransactions();
  }

  // TODO: Implementar métodos para funcionalidades reais do LevvaPay:
  // - Future<void> addFunds(double amount, PaymentMethodDetails details) async { ... }
  // - Future<void> withdrawFunds(double amount, BankDetails details) async { ... }
  // - Future<void> processPaymentForRide(String rideId, double amount) async { ... }
  // Estes métodos deveriam interagir com o FirestoreService ou um serviço de backend de pagamentos,
  // atualizar o _currentBalance e adicionar uma nova TransactionModel a _transactions.

  @override
  void dispose() {
    _isDisposed = true;
    print("LevvaPayProvider: Disposed.");
    super.dispose();
  }
}
