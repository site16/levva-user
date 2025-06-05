// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  String name;
  String lastName;
  String cpf;
  String phoneNumber;

  // Campos de Endereço
  String street;
  String number;
  String? complement; // <<<<<<<<<<<<<<<<<<<<<<< ADICIONADO AQUI (pode ser nulo)
  String neighborhood;
  String city;
  String state;
  String zipCode;

  String? email;
  String? profileImageUrl;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.lastName,
    required this.cpf,
    required this.phoneNumber,
    required this.street,
    required this.number,
    this.complement, // <<<<<<<<<<<<<<<<<<<<<<< ADICIONADO AQUI
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    this.email,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  AppUser copyWith({
    String? name,
    String? lastName,
    String? cpf,
    String? phoneNumber,
    String? street,
    String? number,
    String? complement, // <<<<<<<<<<<<<<<<<<<<<<< ADICIONADO AQUI
    String? neighborhood,
    String? city,
    String? state,
    String? zipCode,
    String? email,
    String? profileImageUrl,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      cpf: cpf ?? this.cpf,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement, // <<<<<<<<<<<<<<<<<<<<<<< ADICIONADO AQUI
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return AppUser(
      uid: snapshot.id,
      name: data?['name'] ?? '',
      lastName: data?['lastName'] ?? '',
      cpf: data?['cpf'] ?? '',
      phoneNumber: data?['phoneNumber'] ?? '',
      street: data?['street'] ?? '',
      number: data?['number'] ?? '',
      complement: data?['complement'] as String?, // <<<<<<<<<<<<<<<<<<<<<<< ADICIONADO AQUI
      neighborhood: data?['neighborhood'] ?? '',
      city: data?['city'] ?? '',
      state: data?['state'] ?? '',
      zipCode: data?['zipCode'] ?? '',
      email: data?['email'] as String?,
      profileImageUrl: data?['profileImageUrl'] as String?,
      createdAt: data?['createdAt'] as Timestamp?,
      updatedAt: data?['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'lastName': lastName,
      'cpf': cpf,
      'phoneNumber': phoneNumber,
      'street': street,
      'number': number,
      'complement': complement, // <<<<<<<<<<<<<<<<<<<<<<< ADICIONADO AQUI
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get fullName => '$name $lastName'.trim();
}