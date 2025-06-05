// lib/providers/driver_registration_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:levva/models/driver_application_model.dart'; // Certifique-se que este é o modelo ATUALIZADO
import 'package:levva/models/enums.dart'; // Certifique-se que DocumentType, VehicleType, RegistrationStatus estão aqui
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Timestamp

// Se RegistrationStatus não estiver em enums.dart, defina-o aqui ou no local apropriado.
// Supondo que já está em lib/models/enums.dart
// enum RegistrationStatus { idle, loading, success, error }

class DriverRegistrationProvider with ChangeNotifier {
  // final FirestoreService _firestoreService; // Para integração real
  // final FirebaseStorage _firebaseStorage; // Para integração real

  RegistrationStatus _status = RegistrationStatus.idle;
  String? _errorMessage;
  
  // Arquivo para a foto de perfil do entregador
  File? _pickedImageFile; 
  
  // NOVOS CAMPOS PARA OS DOCUMENTOS
  File? _cnhImageFile;
  File? _vehicleDocumentImageFile;
  File? _personalDocumentImageFile;

  // Modelo que armazena todos os dados da aplicação
  // Ele será atualizado para incluir os caminhos/URLs dos novos documentos
  DriverApplicationModel? _applicationData;

  final ImagePicker _picker = ImagePicker();

  // DriverRegistrationProvider(this._firestoreService, this._firebaseStorage); // Construtor para integração real
  DriverRegistrationProvider(); // Construtor para simulação

  // Getters
  RegistrationStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DriverApplicationModel? get applicationData => _applicationData;
  
  File? get pickedImageFile => _pickedImageFile; // Foto de perfil
  File? get cnhImageFile => _cnhImageFile;
  File? get vehicleDocumentImageFile => _vehicleDocumentImageFile;
  File? get personalDocumentImageFile => _personalDocumentImageFile;


  void initializeApplication(VehicleType vehicleType, {String? email}) {
    // Usa o construtor factory .initial() do modelo atualizado
    _applicationData = DriverApplicationModel.initial( // Certifique-se que seu modelo tem .initial()
      vehicleType: vehicleType,
      email: email,
    );
    _pickedImageFile = null;
    _cnhImageFile = null;
    _vehicleDocumentImageFile = null;
    _personalDocumentImageFile = null;
    _status = RegistrationStatus.idle;
    _errorMessage = null;
    // notifyListeners(); // Não é ideal chamar no initState diretamente
  }

  // Método para selecionar a foto de perfil (atualiza _pickedImageFile e o photoPath no _applicationData)
  Future<void> pickImage(ImageSource source) async { // Este é para a foto de perfil
    try {
      final XFile? pickedXFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (pickedXFile != null) {
        _pickedImageFile = File(pickedXFile.path);
        // Atualiza o modelo com o caminho do arquivo local
        // Seu DriverApplicationModel PRECISA do método copyWith e do campo photoPath
        _applicationData = _applicationData?.copyWith(photoPath: _pickedImageFile!.path);
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = "Erro ao selecionar foto de perfil: ${e.toString()}";
      print(_errorMessage);
    }
    notifyListeners();
  }

  // MÉTODO ADICIONADO/CORRIGIDO para selecionar imagens de documentos
  Future<void> pickDocumentImage(ImageSource source, DocumentType docType) async {
    try {
      final XFile? pickedXFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, 
        maxWidth: 1024,
      );

      if (pickedXFile != null) {
        final file = File(pickedXFile.path);
        // Seu DriverApplicationModel PRECISA do método copyWith e dos campos de path relevantes
        switch (docType) {
          case DocumentType.cnh:
            _cnhImageFile = file;
            _applicationData = _applicationData?.copyWith(cnhPhotoPath: file.path);
            break;
          case DocumentType.vehicle:
            _vehicleDocumentImageFile = file;
            _applicationData = _applicationData?.copyWith(vehicleDocumentPhotoPath: file.path);
            break;
          case DocumentType.personalId:
            _personalDocumentImageFile = file;
            _applicationData = _applicationData?.copyWith(personalIdPhotoPath: file.path);
            break;
          case DocumentType.profile: 
            // Este caso deve ser idealmente tratado por pickImage, mas por segurança:
            _pickedImageFile = file;
            _applicationData = _applicationData?.copyWith(photoPath: file.path);
            break;
        }
        _errorMessage = null; 
      }
    } catch (e) {
      _errorMessage = "Erro ao selecionar imagem para ${docType.name}: ${e.toString()}";
      print(_errorMessage);
    }
    notifyListeners();
  }

  // Atualiza os dados textuais da aplicação
  void updateApplicationData({
    String? fullName,
    String? cpf,
    String? dateOfBirth,
    String? whatsappNumber,
    String? email,
    String? cnhNumber,
    String? motorcyclePlate,
    String? renavam,
  }) {
    if (_applicationData == null) return;

    // Seu DriverApplicationModel PRECISA do método copyWith
    _applicationData = _applicationData!.copyWith(
      fullName: fullName,
      cpf: cpf,
      dateOfBirth: dateOfBirth,
      whatsappNumber: whatsappNumber,
      email: email,
      cnhNumber: (_applicationData!.vehicleType == VehicleType.moto) ? cnhNumber : _applicationData!.cnhNumber,
      motorcyclePlate: (_applicationData!.vehicleType == VehicleType.moto) ? motorcyclePlate : _applicationData!.motorcyclePlate,
      renavam: (_applicationData!.vehicleType == VehicleType.moto) ? renavam : _applicationData!.renavam,
    );
  }

  Future<bool> submitApplication() async {
    if (_applicationData == null) {
      _errorMessage = "Dados da aplicação não inicializados.";
      _status = RegistrationStatus.error;
      notifyListeners();
      return false;
    }

    // Validação das imagens obrigatórias
    if (_pickedImageFile == null) {
      _errorMessage = "Por favor, envie sua foto de perfil.";
      _status = RegistrationStatus.error;
      notifyListeners();
      return false;
    }
    if (_applicationData!.vehicleType == VehicleType.moto) {
      if (_cnhImageFile == null) {
        _errorMessage = "Por favor, envie a foto da sua CNH.";
        _status = RegistrationStatus.error;
        notifyListeners();
        return false;
      }
      if (_vehicleDocumentImageFile == null) {
        _errorMessage = "Por favor, envie a foto do documento da moto.";
        _status = RegistrationStatus.error;
        notifyListeners();
        return false;
      }
    } else if (_applicationData!.vehicleType == VehicleType.bike) {
      if (_personalDocumentImageFile == null) {
        _errorMessage = "Por favor, envie a foto do seu documento pessoal (RG/CNH).";
        _status = RegistrationStatus.error;
        notifyListeners();
        return false;
      }
    }

    _status = RegistrationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      print("Simulando envio da aplicação...");
      await Future.delayed(const Duration(seconds: 2)); 

      String? simulatedProfilePhotoUrl = _pickedImageFile != null ? "simulated_url/profile/${_pickedImageFile!.path.split('/').last}" : null;
      String? simulatedCnhPhotoUrl = _cnhImageFile != null ? "simulated_url/cnh/${_cnhImageFile!.path.split('/').last}" : null;
      String? simulatedVehicleDocUrl = _vehicleDocumentImageFile != null ? "simulated_url/vehicle_doc/${_vehicleDocumentImageFile!.path.split('/').last}" : null;
      String? simulatedPersonalIdUrl = _personalDocumentImageFile != null ? "simulated_url/personal_id/${_personalDocumentImageFile!.path.split('/').last}" : null;

      // Seu DriverApplicationModel PRECISA do método copyWith e dos campos de URL
      _applicationData = _applicationData!.copyWith(
        photoUrl: simulatedProfilePhotoUrl,
        cnhPhotoUrl: simulatedCnhPhotoUrl,
        vehicleDocumentPhotoUrl: simulatedVehicleDocUrl,
        personalIdPhotoUrl: simulatedPersonalIdUrl,
        status: "PENDING_REVIEW",
        submissionTimestamp: Timestamp.now(),
      );
      
      print("Dados da Aplicação para Envio (Simulado):");
      // Seu DriverApplicationModel PRECISA do método toJson
      print(_applicationData!.toJson()); 

      _status = RegistrationStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Erro ao enviar solicitação: ${e.toString()}";
      _status = RegistrationStatus.error;
      notifyListeners();
      return false;
    }
  }
}
