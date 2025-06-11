import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/user_model.dart';
import '../models/ride_detail_model.dart'; // Certifique-se que este modelo tem deliveryCode/confirmationCode

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

  /// --- NOVO: Criação de corrida com código de confirmação ---
  Future<void> createRideRequest({
    required String userId,
    required RideDetailModel rideDetail,
    String? deliveryCode, // <-- novo campo
  }) async {
    try {
      final historyCollectionRef = _db
          .collection('users')
          .doc(userId)
          .collection('ride_history');

      // Supondo que RideDetailModel tem um método toFirestore()
      final data = rideDetail.toFirestore();

      // Inclui o código de confirmação na criação do documento
      if (deliveryCode != null && deliveryCode.isNotEmpty) {
        data['confirmationCode'] = deliveryCode;
      }

      await historyCollectionRef.doc(rideDetail.rideId).set(data);

      print("FirestoreService: Nova corrida criada com confirmaçãoCode=$deliveryCode para usuário $userId.");
    } catch (e, s) {
      print("FirestoreService: Erro ao criar corrida: $e");
      print("StackTrace: $s");
      throw Exception("Falha ao criar corrida no Firestore.");
    }
  }

  Future<List<RideDetailModel>> getRideHistory(String userId) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('ride_history')
          .orderBy('rideDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RideDetailModel.fromFirestore(doc))
          .toList();
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
    try {
      final historyCollectionRef = _db
          .collection('users')
          .doc(userId)
          .collection('ride_history');

      await historyCollectionRef
          .doc(rideDetail.rideId)
          .set(rideDetail.toFirestore());

      print("FirestoreService: Corrida ${rideDetail.rideId} salva com sucesso no histórico do usuário $userId.");
    } catch (e) {
      print("FirestoreService: Erro ao salvar corrida ${rideDetail.rideId} no histórico: $e");
      throw Exception("Falha ao salvar corrida no histórico do Firestore.");
    }
  }

  Future<RideDetailModel?> getRideDetailsById(String userId, String rideId) async {
    try {
      final rideDoc = await _db
          .collection('users')
          .doc(userId)
          .collection('ride_history')
          .doc(rideId)
          .get();

      if (rideDoc.exists) {
        print("FirestoreService: Documento da corrida $rideId encontrado para o usuário $userId.");
        return RideDetailModel.fromFirestore(rideDoc);
      } else {
        print("FirestoreService: Documento da corrida $rideId NÃO encontrado para o usuário $userId no Firestore.");
        return null;
      }
    } catch (e, s) {
      print("FirestoreService: Erro ao buscar detalhes da corrida $rideId para o usuário $userId: $e");
      print("StackTrace: $s");
      return null;
    }
  }
}