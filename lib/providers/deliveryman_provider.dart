// TODO Implement this library.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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
      id: json['id'].toString(),
      name: json['name'] ?? 'Sem nome',
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      online: json['online'] == true || json['online'] == 1,
    );
  }
}

class DeliverymanProvider with ChangeNotifier {
  List<Deliveryman> _deliverymen = [];
  bool _loading = false;

  List<Deliveryman> get deliverymenOnline =>
      _deliverymen.where((d) => d.online).toList();

  bool get loading => _loading;

  Future<void> fetchDeliverymen() async {
    _loading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('https://SEU_BACKEND_URL/api/entregadores'), // troque para sua URL real
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _deliverymen = data.map((e) => Deliveryman.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar entregadores: $e');
    }
    _loading = false;
    notifyListeners();
  }
}