import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/user_model.dart';
import '../models/ride_detail_model.dart'; // Garanta que este modelo tem um factory fromFirestore e os enums/extensions necessários

// Se você tiver um arquivo para seus enums, como RideHistoryStatus e suas extensões,
// certifique-se de que ele está importado ou defina-os aqui ou no ride_detail_model.dart
// Exemplo (coloque no local apropriado, preferencialmente com seu modelo):
/*
enum RideHistoryStatus { completed, cancelled, inProgress, unknown }

extension RideHistoryStatusExtension on RideHistoryStatus {
  static RideHistoryStatus fromString(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'completed': return RideHistoryStatus.completed;
      case 'cancelled': return RideHistoryStatus.cancelled;
      case 'inprogress': return RideHistoryStatus.inProgress;
      default: return RideHistoryStatus.unknown;
    }
  }
  String get asString { // Para salvar no Firestore
    return toString().split('.').last;
  }
}
*/

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Construtor: se 'instance' for para testes, pode manter. Caso contrário, pode remover o parâmetro.
  FirestoreService(FirebaseFirestore? instance);

  Future<void> updateUserProfileData(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      final userRef = _db.collection('users').doc(uid);
      await userRef.set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("FirestoreService: Dados do perfil atualizados para o UID: $uid");
    } catch (e, s) {
      print("Erro ao salvar dados do perfil no FirestoreService: $e");
      print("StackTrace ao salvar perfil: $s");
      rethrow;
    }
  }

  Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      final ref = _storage
          .ref()
          .child('users')
          .child(uid)
          .child('profile_images')
          .child('profile.jpg');
      print("FirestoreService: Iniciando upload da imagem para o UID: $uid");
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print("FirestoreService: Imagem enviada, URL de download: $downloadUrl");
      return downloadUrl;
    } catch (e, s) {
      print("Erro no upload da imagem de perfil no FirestoreService: $e");
      print("StackTrace do upload: $s");
      rethrow;
    }
  }

  Future<void> updateUserProfileImageUrl(String uid, String imageUrl) async {
    try {
      print(
        "FirestoreService: Atualizando URL da imagem de perfil para o UID: $uid",
      );
      await _db.collection('users').doc(uid).update({
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("FirestoreService: URL da imagem de perfil atualizada.");
    } catch (e, s) {
      print(
        "Erro ao atualizar URL da imagem de perfil no FirestoreService: $e",
      );
      print("StackTrace da atualização da URL: $s");
      rethrow;
    }
  }

  Future<AppUser?> getUserProfile(String uid) async {
    try {
      print("FirestoreService: Buscando perfil para o UID: $uid");
      final docSnap = await _db.collection('users').doc(uid).get();
      if (docSnap.exists) {
        print("FirestoreService: Perfil encontrado para o UID: $uid");
        return AppUser.fromFirestore(docSnap, null);
      }
      print("FirestoreService: Perfil NÃO encontrado para o UID: $uid");
      return null;
    } catch (e, s) {
      print("Erro ao buscar perfil do usuário no FirestoreService: $e");
      print("StackTrace ao buscar perfil: $s");
      rethrow;
    }
  }

  Future<List<RideDetailModel>> getRideHistory(String userId) async {
    print(
      "FirestoreService: Buscando histórico de corridas para o utilizador $userId (SIMULADO)",
    );
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      // Sua lógica de simulação atual para getRideHistory
      return [
        RideDetailModel(
          rideId: 'sim_ride1_fs',
          originName: 'Shopping Flamboyant',
          destinationName: 'Parque Vaca Brava',
          rideDate: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          ),
          price: 22.75,
          status: RideHistoryStatus.completed, // Use seu enum RideHistoryStatus
          driverName: 'Mariana L.',
          vehicleDetails: 'Moto Honda Biz - ABC1D23',
          originLocation: const LatLng(-16.7094, -49.2434),
          destinationLocation: const LatLng(-16.7030, -49.2635),
          confirmationCode: 'AB123', // Exemplo de código de confirmação
        ),
        RideDetailModel(
          rideId: 'sim_ride2_fs',
          originName: 'Aeroporto de Goiânia',
          // ... resto dos dados simulados
          destinationName: 'Hotel Central',
          rideDate: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 5, hours: 10)),
          ),
          price: 35.50,
          status: RideHistoryStatus.completed,
          originLocation: const LatLng(-16.6322, -49.2220),
          destinationLocation: const LatLng(-16.6799, -49.2550),
        ),
        RideDetailModel(
          rideId: 'sim_ride3_fs',
          originName: 'Praça Cívica',
          // ... resto dos dados simulados
          destinationName: 'Estádio Serra Dourada',
          rideDate: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 10)),
          ),
          price: 18.00,
          status: RideHistoryStatus.cancelled,
          driverName: 'Ricardo P.',
          originLocation: const LatLng(-16.6786, -49.2539),
          destinationLocation: const LatLng(-16.7109, -49.2319),
        ),
      ];
    } catch (e) {
      print(
        "FirestoreService: Exceção em getRideHistory: $e. Retornando lista vazia.",
      );
      return [];
    }
  }

  Future<void> saveRideToHistory(
    String userId,
    RideDetailModel rideDetail,
  ) async {
    print(
      "FirestoreService: Tentando 'salvar' corrida ID ${rideDetail.rideId} para o usuário $userId no histórico.",
    );
    print(
      "Detalhes da Corrida: Origem: ${rideDetail.originName}, Destino: ${rideDetail.destinationName}, Preço: ${rideDetail.price}, Status: ${rideDetail.status}",
    );

    // LÓGICA REAL DO FIRESTORE (DESCOMENTE E AJUSTE SE NECESSÁRIO):
    /*
    try {
      final historyCollectionRef = _db
          .collection('users')
          .doc(userId)
          .collection('ride_history'); // Confirme o nome da subcoleção

      // Supondo que RideDetailModel tem um método toFirestore()
      await historyCollectionRef
          .doc(rideDetail.rideId) 
          .set(rideDetail.toFirestore()); 

      print("FirestoreService: Corrida ${rideDetail.rideId} salva com sucesso no histórico do usuário $userId.");
    } catch (e) {
      print("FirestoreService: Erro ao salvar corrida ${rideDetail.rideId} no histórico: $e");
      throw Exception("Falha ao salvar corrida no histórico do Firestore.");
    }
    */

    // Simulação de sucesso para fins de desenvolvimento (se a lógica real estiver comentada)
    await Future.delayed(
      const Duration(milliseconds: 500),
    );
    print(
      "FirestoreService: Corrida ${rideDetail.rideId} 'processada' para o histórico (simulado).",
    );
  }

  // --- MÉTODO ATUALIZADO ---
  // Agora aceita userId para buscar na subcoleção correta.
  Future<RideDetailModel?> getRideDetailsById(String userId, String rideId) async {
    print("FirestoreService: Buscando detalhes da corrida para userId: $userId, rideId: $rideId");
    try {
      // Busca na subcoleção 'ride_history' do usuário específico
      final rideDoc = await _db
          .collection('users')
          .doc(userId)
          .collection('ride_history') // Certifique-se que este é o nome correto da sua subcoleção
          .doc(rideId)
          .get();

      if (rideDoc.exists) {
        print("FirestoreService: Documento da corrida $rideId encontrado para o usuário $userId.");
        // Certifique-se que RideDetailModel.fromFirestore está implementado corretamente
        return RideDetailModel.fromFirestore(rideDoc);
      } else {
        print("FirestoreService: Documento da corrida $rideId NÃO encontrado para o usuário $userId no Firestore.");
        // Fallback para dados simulados se o ID for 'sim_ride1_fs' (para fins de teste)
        if (rideId == 'sim_ride1_fs') {
          print("FirestoreService: Tentando carregar dados simulados para $rideId pois não foi encontrado no Firestore.");
          final simulatedHistory = await getRideHistory(userId); // Reutiliza a simulação
          for (var ride in simulatedHistory) {
            if (ride.rideId == rideId) {
              print("FirestoreService: Dados simulados encontrados para $rideId.");
              return ride;
            }
          }
        }
        return null; // Não encontrado no Firestore nem na simulação específica
      }
    } catch (e, s) {
      print("FirestoreService: Erro ao buscar detalhes da corrida $rideId para o usuário $userId: $e");
      print("StackTrace: $s");
      // Fallback para dados simulados em caso de erro também, se aplicável
      if (rideId == 'sim_ride1_fs') {
        print("FirestoreService: Tentando carregar dados simulados para $rideId (usuário $userId) devido a erro na busca.");
        final simulatedHistory = await getRideHistory(userId);
        for (var ride in simulatedHistory) {
          if (ride.rideId == rideId) {
            print("FirestoreService: Dados simulados encontrados para $rideId após erro.");
            return ride;
          }
        }
      }
      return null;
    }
  }
}