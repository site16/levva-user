import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
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
    _authService.authStateChanges.listen(
      _onAuthStateChanged,
      onError: (error, stackTrace) {
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
    _isLoading = true;
    User? firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      await _loadUserProfile(firebaseUser);
    } else {
      _authStatus = AuthStatus.unauthenticated;
      _isLoading = false;
      _isUserFetched = true;
      notifyListeners();
    }
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _isLoading = true;
    if (firebaseUser == null) {
      _currentUserModel = null;
      _authStatus = AuthStatus.unauthenticated;
      _isLoading = false;
      _isUserFetched = true;
      notifyListeners();
    } else {
      if (_currentUserModel == null || _currentUserModel!.uid != firebaseUser.uid || !_isUserFetched) {
        await _loadUserProfile(firebaseUser);
      } else {
        _authStatus = AuthStatus.authenticated;
        _isLoading = false;
        _isUserFetched = true;
        notifyListeners();
      }
    }
  }

  Future<void> _loadUserProfile(User firebaseUser) async {
    bool needsInitialNotification = !_isLoading;
    _isLoading = true;
    if (needsInitialNotification) {
      notifyListeners();
    }
    try {
      AppUser? userProfile = await _firestoreService.getUserProfile(firebaseUser.uid);
      bool needsDBSave = false;

      if (userProfile == null) {
        userProfile = AppUser(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName?.split(' ').firstWhere((s) => s.isNotEmpty, orElse: () => '') ?? '',
          lastName: firebaseUser.displayName != null && firebaseUser.displayName!.split(' ').length > 1
              ? firebaseUser.displayName!.split(' ').sublist(1).join(' ')
              : '',
          cpf: '',
          phoneNumber: firebaseUser.phoneNumber ?? '',
          street: '', number: '', neighborhood: '', city: '', state: '', zipCode: '',
          email: firebaseUser.email,
          profileImageUrl: firebaseUser.photoURL,
          createdAt: Timestamp.now(),
        );
        needsDBSave = true;
      } else {
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
          userProfile = userProfile.copyWith(
            email: currentEmail,
            profileImageUrl: currentPhotoUrl,
            updatedAt: Timestamp.now(),
          );
          needsDBSave = true;
        }
      }

      if (needsDBSave) {
        await _firestoreService.updateUserProfileData(userProfile.uid, userProfile.toFirestore());
      }

      _currentUserModel = userProfile;
      _authStatus = AuthStatus.authenticated;
      _errorMessage = null;
    } catch (e, s) {
      _errorMessage = "Erro ao carregar/criar perfil: ${e.toString()}";
      _authStatus = AuthStatus.error;
      _currentUserModel = null;
    } finally {
      _isLoading = false;
      _isUserFetched = true;
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
      Map<String, dynamic> finalDataToUpdate = Map.from(dataToUpdate);
      finalDataToUpdate['updatedAt'] = FieldValue.serverTimestamp();

      await _firestoreService.updateUserProfileData(_currentUserModel!.uid, finalDataToUpdate);

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
        email: dataToUpdate.containsKey('email') ? dataToUpdate['email'] as String? : _currentUserModel!.email,
      );
      success = true;
    } catch (e, s) {
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
      await _firestoreService.updateUserProfileImageUrl(_currentUserModel!.uid, imageUrl);
      _currentUserModel = _currentUserModel!.copyWith(profileImageUrl: imageUrl, updatedAt: Timestamp.now());
      success = true;
    } catch (e, s) {
      _errorMessage = "Erro ao atualizar imagem: ${e.toString()}";
      success = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    _isLoading = true;
    _authStatus = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      UserCredential? userCredential = await _authService.signInWithGoogle();
      if (userCredential?.user == null) {
        _errorMessage = "Login com Google cancelado ou falhou.";
        _authStatus = AuthStatus.unauthenticated;
        _isLoading = false;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = "Erro no login com Google: ${e.message} (${e.code})";
      _authStatus = AuthStatus.error;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Ocorreu um erro: ${e.toString()}";
      _authStatus = AuthStatus.error;
      _isLoading = false;
      notifyListeners();
    }
    if (_errorMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> signOut(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
    } catch (e) {
      _errorMessage = "Erro ao sair: ${e.toString()}";
      _authStatus = AuthStatus.error;
      _isLoading = false;
      notifyListeners();
      if (context.mounted && _errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }
}