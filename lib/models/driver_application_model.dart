// lib/models/driver_application_model.dart
// Para File
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Timestamp
import 'package:levva/models/enums.dart'; // Para VehicleType

class DriverApplicationModel {
  final String? id; // UID do usuário Firebase ou ID da aplicação
  final VehicleType vehicleType;
  final String fullName;
  final String cpf;
  final String dateOfBirth; // Formato DD/MM/AAAA
  final String whatsappNumber;
  final String email;

  // Campos específicos para Moto
  final String? cnhNumber;
  final String? motorcyclePlate;
  final String? renavam;

  // Caminhos locais dos arquivos selecionados (para exibição na UI e processo de upload)
  final String? photoPath;         // Caminho local da foto de perfil
  final String? cnhPhotoPath;      // Caminho local da foto da CNH
  final String? vehicleDocumentPhotoPath; // Caminho local do documento do veículo
  final String? personalIdPhotoPath;    // Caminho local do documento pessoal (para bike)

  // URLs dos arquivos após upload (para salvar no Firestore)
  final String? photoUrl;
  final String? cnhPhotoUrl;
  final String? vehicleDocumentPhotoUrl;
  final String? personalIdPhotoUrl;

  final String? status; // Ex: PENDING_REVIEW, APPROVED, REJECTED
  final Timestamp? submissionTimestamp;
  final Timestamp? lastUpdateTimestamp;

  DriverApplicationModel({
    this.id,
    required this.vehicleType,
    this.fullName = '',
    this.cpf = '',
    this.dateOfBirth = '',
    this.whatsappNumber = '',
    this.email = '',
    this.cnhNumber,
    this.motorcyclePlate,
    this.renavam,
    this.photoPath, // Adicionado
    this.cnhPhotoPath, // Adicionado
    this.vehicleDocumentPhotoPath, // Adicionado
    this.personalIdPhotoPath, // Adicionado
    this.photoUrl,
    this.cnhPhotoUrl, // Adicionado
    this.vehicleDocumentPhotoUrl, // Adicionado
    this.personalIdPhotoUrl, // Adicionado
    this.status,
    this.submissionTimestamp,
    this.lastUpdateTimestamp,
  });

  // Construtor inicial para facilitar
  factory DriverApplicationModel.initial({required VehicleType vehicleType, String? email}) {
    return DriverApplicationModel(
      vehicleType: vehicleType,
      email: email ?? '',
      status: 'INITIAL', // Um status inicial padrão
      // Outros campos podem ser inicializados como string vazia ou null conforme o construtor principal
      fullName: '',
      cpf: '',
      dateOfBirth: '',
      whatsappNumber: '',
    );
  }

  DriverApplicationModel copyWith({
    String? id,
    VehicleType? vehicleType,
    String? fullName,
    String? cpf,
    String? dateOfBirth,
    String? whatsappNumber,
    String? email,
    String? cnhNumber,
    String? motorcyclePlate,
    String? renavam,
    String? photoPath,
    String? cnhPhotoPath,
    String? vehicleDocumentPhotoPath,
    String? personalIdPhotoPath,
    String? photoUrl,
    String? cnhPhotoUrl,
    String? vehicleDocumentPhotoUrl,
    String? personalIdPhotoUrl,
    String? status,
    Timestamp? submissionTimestamp,
    Timestamp? lastUpdateTimestamp,
    bool clearPhotoPath = false, // Flags para limpar caminhos específicos se necessário
    bool clearCnhPhotoPath = false,
    bool clearVehicleDocumentPhotoPath = false,
    bool clearPersonalIdPhotoPath = false,
  }) {
    return DriverApplicationModel(
      id: id ?? this.id,
      vehicleType: vehicleType ?? this.vehicleType,
      fullName: fullName ?? this.fullName,
      cpf: cpf ?? this.cpf,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      email: email ?? this.email,
      cnhNumber: cnhNumber ?? this.cnhNumber,
      motorcyclePlate: motorcyclePlate ?? this.motorcyclePlate,
      renavam: renavam ?? this.renavam,
      photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
      cnhPhotoPath: clearCnhPhotoPath ? null : (cnhPhotoPath ?? this.cnhPhotoPath),
      vehicleDocumentPhotoPath: clearVehicleDocumentPhotoPath ? null : (vehicleDocumentPhotoPath ?? this.vehicleDocumentPhotoPath),
      personalIdPhotoPath: clearPersonalIdPhotoPath ? null : (personalIdPhotoPath ?? this.personalIdPhotoPath),
      photoUrl: photoUrl ?? this.photoUrl,
      cnhPhotoUrl: cnhPhotoUrl ?? this.cnhPhotoUrl,
      vehicleDocumentPhotoUrl: vehicleDocumentPhotoUrl ?? this.vehicleDocumentPhotoUrl,
      personalIdPhotoUrl: personalIdPhotoUrl ?? this.personalIdPhotoUrl,
      status: status ?? this.status,
      submissionTimestamp: submissionTimestamp ?? this.submissionTimestamp,
      lastUpdateTimestamp: lastUpdateTimestamp ?? this.lastUpdateTimestamp,
    );
  }

  Map<String, dynamic> toJson() { // Renomeado de toFirestore para consistência
    final Map<String, dynamic> data = {
      // uid é geralmente o ID do documento, não um campo dentro dele, a menos que você precise duplicar.
      // Se 'id' for o UID do usuário, pode ser 'userId': id,
      if (id != null) 'applicantId': id, // Ou o ID da aplicação se for diferente do UID do usuário
      'vehicleType': vehicleType.name, // Salva o nome do enum (ex: 'moto', 'bike')
      'fullName': fullName,
      'cpf': cpf,
      'dateOfBirth': dateOfBirth,
      'whatsappNumber': whatsappNumber,
      'email': email,
      'status': status ?? 'PENDING_REVIEW',
      'submissionTimestamp': submissionTimestamp ?? FieldValue.serverTimestamp(),
      'lastUpdateTimestamp': FieldValue.serverTimestamp(), // Sempre atualiza
      
      // URLs das imagens após upload
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (cnhPhotoUrl != null) 'cnhPhotoUrl': cnhPhotoUrl,
      if (vehicleDocumentPhotoUrl != null) 'vehicleDocumentPhotoUrl': vehicleDocumentPhotoUrl,
      if (personalIdPhotoUrl != null) 'personalIdPhotoUrl': personalIdPhotoUrl,
    };

    if (vehicleType == VehicleType.moto) {
      if (cnhNumber != null) data['cnhNumber'] = cnhNumber;
      if (motorcyclePlate != null) data['motorcyclePlate'] = motorcyclePlate;
      if (renavam != null) data['renavam'] = renavam;
    }
    return data;
  }

  // Você pode querer um factory fromJson/fromFirestore se for ler esses dados de volta
  factory DriverApplicationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return DriverApplicationModel(
      id: doc.id,
      vehicleType: VehicleType.values.firstWhere((e) => e.name == data['vehicleType'], orElse: () => VehicleType.moto /*padrão*/),
      fullName: data['fullName'] ?? '',
      cpf: data['cpf'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? '',
      whatsappNumber: data['whatsappNumber'] ?? '',
      email: data['email'] ?? '',
      cnhNumber: data['cnhNumber'] as String?,
      motorcyclePlate: data['motorcyclePlate'] as String?,
      renavam: data['renavam'] as String?,
      photoUrl: data['photoUrl'] as String?,
      cnhPhotoUrl: data['cnhPhotoUrl'] as String?,
      vehicleDocumentPhotoUrl: data['vehicleDocumentPhotoUrl'] as String?,
      personalIdPhotoUrl: data['personalIdPhotoUrl'] as String?,
      status: data['status'] as String?,
      submissionTimestamp: data['submissionTimestamp'] as Timestamp?,
      lastUpdateTimestamp: data['lastUpdateTimestamp'] as Timestamp?,
      // Os campos ...Path não são lidos do Firestore, são apenas para o processo de upload local
    );
  }
}
