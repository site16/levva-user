import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo do entregador
class Deliveryman {
  final String id;
  final LatLng location;
  final String name;
  final bool online;

  Deliveryman({
    required this.id,
    required this.location,
    required this.name,
    required this.online,
  });

  factory Deliveryman.fromJson(Map<String, dynamic> json) {
    return Deliveryman(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Sem nome',
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      online: json['online'] == true || json['online'] == 1,
    );
  }

  factory Deliveryman.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Deliveryman(
      id: doc.id,
      name: data['name'] ?? 'Sem nome',
      location: LatLng(
        (data['latitude'] as num).toDouble(),
        (data['longitude'] as num).toDouble(),
      ),
      online: data['online'] == true || data['online'] == 1,
    );
  }
}

class DeliverymanProvider with ChangeNotifier {
  final List<Deliveryman> _deliverymen = [];
  bool _loading = false;
  StreamSubscription<QuerySnapshot>? _firestoreSub;

  List<Deliveryman> get deliverymenOnline =>
      _deliverymen.where((d) => d.online).toList();

  bool get loading => _loading;

  /// Busca os entregadores online em tempo real do Firestore (coleção 'deliverymen')
  void fetchDeliverymen() {
    _firestoreSub?.cancel();
    _loading = true;
    notifyListeners();

    _firestoreSub = FirebaseFirestore.instance
        .collection('deliverymen')
        .where('online', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _deliverymen
        ..clear()
        ..addAll(snapshot.docs
            .where((doc) =>
                doc.data().containsKey('latitude') &&
                doc.data().containsKey('longitude'))
            .map((doc) => Deliveryman.fromFirestore(doc)));
      _loading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Erro ao buscar entregadores: $e');
      _loading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    super.dispose();
  }
}