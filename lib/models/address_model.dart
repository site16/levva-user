// lib/models/address_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String? id; // ID do endereço, se armazenado separadamente (ex: lista de endereços do usuário)
  final String street;
  final String? number;
  final String? complement;
  final String? neighborhood; // Bairro
  final String city;
  final String state; // Estado/UF
  final String zipCode; // CEP
  final String country;
  final double? latitude;
  final double? longitude;
  final String? description; // Ex: "Casa", "Trabalho", "Portão Azul"

  AddressModel({
    this.id,
    required this.street,
    this.number,
    this.complement,
    this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.latitude,
    this.longitude,
    this.description,
  });

  // Método para criar um AddressModel a partir de um Map (geralmente vindo do Firestore)
  factory AddressModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return AddressModel(
      id: documentId ?? map['id'],
      street: map['street'] ?? '',
      number: map['number'],
      complement: map['complement'],
      neighborhood: map['neighborhood'],
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      country: map['country'] ?? 'Brasil', // Valor padrão se não fornecido
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      description: map['description'],
    );
  }

  // Método para converter um AddressModel para um Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'street': street,
      'number': number,
      'complement': complement,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      // Adicionar um timestamp se for útil para rastrear quando foi adicionado/modificado
      // 'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Helper para exibir o endereço formatado (opcional)
  String get formattedAddress {
    List<String> parts = [];
    parts.add(street);
    if (number != null && number!.isNotEmpty) parts.add(number!);
    if (neighborhood != null && neighborhood!.isNotEmpty) parts.add(neighborhood!);
    if (complement != null && complement!.isNotEmpty) parts.add(complement!);
    parts.add(city);
    parts.add(state);
    if (zipCode.isNotEmpty) parts.add('CEP: $zipCode');
    return parts.join(', ');
  }

   // Construtor de cópia com modificações (opcional, mas útil)
  AddressModel copyWith({
    String? id,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    double? latitude,
    double? longitude,
    String? description,
  }) {
    return AddressModel(
      id: id ?? this.id,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
    );
  }
}