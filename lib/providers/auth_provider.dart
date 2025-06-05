// lib/providers/auth_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider; // Esconde o AuthProvider do Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // Contém a classe AppUser
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/enums.dart'; // Contém AuthStatus

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AppUser? _currentUserModel;
  AuthStatus _authStatus = AuthStatus.uninitialized;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isUserFetched = false;

  AppUser? get currentUser => _currentUserModel;
  AuthStatus get authStatus => _authStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUserFetched => _isUserFetched;

  AuthProvider(this._authService, this._firestoreService, [this._currentUserModel]) {
    print("AuthProvider: Inicializando e ouvindo authStateChanges...");
    _authService.authStateChanges.listen(
      _onAuthStateChanged,
      onError: (error, stackTrace) {
        print("AuthProvider: ERRO NO STREAM authStateChanges: $error");
        _currentUserModel = null;
        _authStatus = AuthStatus.error;
        _errorMessage = "Erro crítico no fluxo de autenticação: $error";
        _isLoading = false;
        _isUserFetched = true;
        notifyListeners();
      }
    );
    _checkInitialAuthStatus();
  }

  Future<void> _checkInitialAuthStatus() async {
    print("AuthProvider: Verificando estado inicial...");
    _isLoading = true;
    User? firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      print("AuthProvider: Usuário inicial encontrado (${firebaseUser.uid}). Carregando perfil...");
      await _loadUserProfile(firebaseUser);
    } else {
      print("AuthProvider: Nenhum usuário inicial encontrado.");
      _authStatus = AuthStatus.unauthenticated;
      _isLoading = false;
      _isUserFetched = true;
      notifyListeners();
    }
    print("AuthProvider: Verificação inicial processada. Status: $_authStatus, UserFetched: $_isUserFetched");
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    print("AuthProvider: _onAuthStateChanged chamado. User: ${firebaseUser?.uid}");
    _isLoading = true;

    if (firebaseUser == null) {
      print("AuthProvider: firebaseUser é nulo (logout).");
      _currentUserModel = null;
      _authStatus = AuthStatus.unauthenticated;
      _isLoading = false;
      _isUserFetched = true; 
      notifyListeners();
    } else {
      print("AuthProvider: firebaseUser recebido (${firebaseUser.uid}). Carregando perfil se necessário...");
      if (_currentUserModel == null || _currentUserModel!.uid != firebaseUser.uid || !_isUserFetched) {
        await _loadUserProfile(firebaseUser);
      } else {
        _authStatus = AuthStatus.authenticated;
        _isLoading = false; 
        _isUserFetched = true;
        notifyListeners(); 
        print("AuthProvider: firebaseUser (${firebaseUser.uid}) já carregado. Status: $_authStatus");
      }
    }
    print("AuthProvider: _onAuthStateChanged processado. Status: $_authStatus, UserFetched: $_isUserFetched");
  }

  Future<void> _loadUserProfile(User firebaseUser) async {
    print("AuthProvider: Iniciando _loadUserProfile para ${firebaseUser.uid}");
    bool needsInitialNotification = !_isLoading; // Store initial state
    _isLoading = true;
    if (needsInitialNotification) { // Notify only if it wasn't already loading
        notifyListeners();
    }

    try {
      AppUser? userProfile = await _firestoreService.getUserProfile(firebaseUser.uid);
      bool needsDBSave = false;

      if (userProfile == null) {
        print("AuthProvider: Perfil não encontrado no Firestore. Criando novo...");
        userProfile = AppUser(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName?.split(' ').firstWhere((s) => s.isNotEmpty, orElse: () => '') ?? '',
          lastName: firebaseUser.displayName != null && firebaseUser.displayName!.split(' ').length > 1
              ? firebaseUser.displayName!.split(' ').sublist(1).join(' ')
              : '',
          cpf: '', phoneNumber: firebaseUser.phoneNumber ?? '',
          street: '', number: '', neighborhood: '', city: '', state: '', zipCode: '', // Endereço inicializado vazio
          email: firebaseUser.email,
          profileImageUrl: firebaseUser.photoURL,
          createdAt: Timestamp.now(),
        );
        needsDBSave = true;
      } else {
        // Lógica para atualizar email/foto do Firebase se estiverem vazios no perfil local
        bool profileWasModified = false;
        String? currentEmail = userProfile.email;
        String? currentPhotoUrl = userProfile.profileImageUrl;

        if ((currentEmail == null || currentEmail.isEmpty) && (firebaseUser.email?.isNotEmpty ?? false)) {
          currentEmail = firebaseUser.email;
          profileWasModified = true;
        }
        if ((currentPhotoUrl == null || currentPhotoUrl.isEmpty) && (firebaseUser.photoURL?.isNotEmpty ?? false)) {
          currentPhotoUrl = firebaseUser.photoURL;
          profileWasModified = true;
        }
        if (profileWasModified) {
          userProfile = userProfile.copyWith( // copyWith atualiza os campos
            email: currentEmail,
            profileImageUrl: currentPhotoUrl,
            updatedAt: Timestamp.now(), // Também atualiza o updatedAt
          );
          needsDBSave = true;
        }
      }

      if (needsDBSave) {
        print("AuthProvider: Salvando/Atualizando perfil inicial no Firestore...");
        await _firestoreService.updateUserProfileData(userProfile.uid, userProfile.toFirestore());
      }

      _currentUserModel = userProfile;
      _authStatus = AuthStatus.authenticated;
      _errorMessage = null;
    } catch (e, s) {
      _errorMessage = "Erro ao carregar/criar perfil: ${e.toString()}";
      _authStatus = AuthStatus.error;
      _currentUserModel = null;
      print("AuthProvider: ERRO em _loadUserProfile: $e \nStack: $s");
    } finally {
        _isLoading = false;
        _isUserFetched = true; // Marca que o fetch (ou tentativa) foi concluído
        notifyListeners();
    }
  }

  Future<bool> updateUserProfileData(Map<String, dynamic> dataToUpdate, BuildContext context) async {
    if (_currentUserModel == null) {
      _errorMessage = "Usuário não encontrado para atualização.";
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    bool success = false;
    try {
      // Adiciona/atualiza o campo 'updatedAt' no mapa de dados a ser enviado para o Firestore.
      // O método toFirestore do AppUser também pode ser configurado para sempre enviar FieldValue.serverTimestamp() para updatedAt.
      Map<String, dynamic> finalDataToUpdate = Map.from(dataToUpdate);
      finalDataToUpdate['updatedAt'] = FieldValue.serverTimestamp();

      await _firestoreService.updateUserProfileData(_currentUserModel!.uid, finalDataToUpdate);
      
      // Atualiza o modelo local com os novos dados
      // É importante que o copyWith não sobrescreva campos com null se não for a intenção
      _currentUserModel = _currentUserModel!.copyWith(
        name: dataToUpdate.containsKey('name') ? dataToUpdate['name'] as String? : _currentUserModel!.name,
        lastName: dataToUpdate.containsKey('lastName') ? dataToUpdate['lastName'] as String? : _currentUserModel!.lastName,
        cpf: dataToUpdate.containsKey('cpf') ? dataToUpdate['cpf'] as String? : _currentUserModel!.cpf,
        phoneNumber: dataToUpdate.containsKey('phoneNumber') ? dataToUpdate['phoneNumber'] as String? : _currentUserModel!.phoneNumber,
        street: dataToUpdate.containsKey('street') ? dataToUpdate['street'] as String? : _currentUserModel!.street,
        number: dataToUpdate.containsKey('number') ? dataToUpdate['number'] as String? : _currentUserModel!.number,
        neighborhood: dataToUpdate.containsKey('neighborhood') ? dataToUpdate['neighborhood'] as String? : _currentUserModel!.neighborhood,
        city: dataToUpdate.containsKey('city') ? dataToUpdate['city'] as String? : _currentUserModel!.city,
        state: dataToUpdate.containsKey('state') ? dataToUpdate['state'] as String? : _currentUserModel!.state,
        zipCode: dataToUpdate.containsKey('zipCode') ? dataToUpdate['zipCode'] as String? : _currentUserModel!.zipCode,
        // email e profileImageUrl geralmente são atualizados por métodos específicos
        // mas se vierem em dataToUpdate, também podem ser atualizados aqui.
        email: dataToUpdate.containsKey('email') ? dataToUpdate['email'] as String? : _currentUserModel!.email,
        // updatedAt será atualizado quando o perfil for recarregado do Firestore ou pode ser setado manualmente se o timestamp for retornado.
      );
      success = true;
    } catch (e, s) {
      print("AuthProvider: ERRO ao atualizar dados do perfil: $e \nStack: $s");
      _errorMessage = "Erro ao salvar perfil: ${e.toString()}";
      success = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateUserProfileImage(File imageFile, BuildContext context) async {
    if (_currentUserModel == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    bool success = false;
    try {
      final imageUrl = await _firestoreService.uploadProfileImage(_currentUserModel!.uid, imageFile);
      await _firestoreService.updateUserProfileImageUrl(_currentUserModel!.uid, imageUrl); // Salva no Firestore
      _currentUserModel = _currentUserModel!.copyWith(profileImageUrl: imageUrl, updatedAt: Timestamp.now()); // Atualiza localmente
      success = true;
    } catch (e, s) {
      print("AuthProvider: ERRO ao atualizar imagem de perfil: $e \nStack: $s");
      _errorMessage = "Erro ao atualizar imagem: ${e.toString()}";
      success = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    _isLoading = true; // Inicia loading
    _authStatus = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      UserCredential? userCredential = await _authService.signInWithGoogle();
      if (userCredential?.user == null) {
        _errorMessage = "Login com Google cancelado ou falhou.";
        _authStatus = AuthStatus.unauthenticated;
        _isLoading = false; // Termina loading
        notifyListeners(); // Notifica a mudança de status
      }
      // _onAuthStateChanged será chamado automaticamente, que lidará com _isLoading = false
    } on FirebaseAuthException catch (e) {
      _errorMessage = "Erro no login com Google: ${e.message} (${e.code})";
      _authStatus = AuthStatus.error;
      _isLoading = false; // Termina loading
      notifyListeners(); // Notifica a mudança de status
    } catch (e) {
      _errorMessage = "Ocorreu um erro: ${e.toString()}";
      _authStatus = AuthStatus.error;
      _isLoading = false; // Termina loading
      notifyListeners(); // Notifica a mudança de status
    }
    // Não é mais necessário notificar explicitamente aqui se _isLoading já foi tratado,
    // pois _onAuthStateChanged cuidará da transição final de estado.
    
    if (_errorMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> signOut(BuildContext context) async {
    _isLoading = true; // Inicia loading
    notifyListeners();
    try {
      await _authService.signOut();
      // _onAuthStateChanged cuidará de limpar _currentUserModel e mudar status.
      // _isLoading será setado para false em _onAuthStateChanged.
    } catch (e) {
      _errorMessage = "Erro ao sair: ${e.toString()}";
      // _currentUserModel = null; // Redundante, _onAuthStateChanged fará
      _authStatus = AuthStatus.error;
      _isLoading = false; // Termina loading em caso de erro no signOut
      notifyListeners();
      if (context.mounted && _errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }
}