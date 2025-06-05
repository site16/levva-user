import 'package:cloud_firestore/cloud_firestore.dart';
// CORREÇÃO AQUI: O nome do pacote é 'google_maps_flutter'
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RideHistoryStatus { completed, cancelled, inProgress }

class RideDetailModel {
  final String rideId;
  final String originName;
  final String destinationName;
  final LatLng? originLocation;
  final LatLng? destinationLocation;
  final Timestamp rideDate;
  final double price;
  final RideHistoryStatus status;
  final String? driverName;
  final String? vehicleDetails;

  RideDetailModel({
    required this.rideId,
    required this.originName,
    required this.destinationName,
    this.originLocation,
    this.destinationLocation,
    required this.rideDate,
    required this.price,
    required this.status,
    this.driverName,
    this.vehicleDetails,
    String? confirmationCode,
  });

  factory RideDetailModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception(
        "Dados nulos recebidos do Firestore para rideId: ${snapshot.id}",
      );
    }

    LatLng? parseLatLng(dynamic latLngData) {
      if (latLngData is Map) {
        if (latLngData.containsKey('latitude') &&
            latLngData.containsKey('longitude')) {
          return LatLng(
            latLngData['latitude'] as double,
            latLngData['longitude'] as double,
          );
        }
      } else if (latLngData is GeoPoint) {
        return LatLng(latLngData.latitude, latLngData.longitude);
      }
      return null;
    }

    return RideDetailModel(
      rideId: snapshot.id,
      originName: data['originName'] as String? ?? 'Origem Desconhecida',
      destinationName:
          data['destinationName'] as String? ?? 'Destino Desconhecido',
      originLocation: parseLatLng(data['originLocation']),
      destinationLocation: parseLatLng(data['destinationLocation']),
      rideDate: data['rideDate'] as Timestamp? ?? Timestamp.now(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      status: RideHistoryStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => RideHistoryStatus.completed,
      ),
      driverName: data['driverName'] as String?,
      vehicleDetails: data['vehicleDetails'] as String?,
    );
  }

  String? get confirmationCode => null;

  Map<String, dynamic> toFirestore() {
    Map<String, double>? latLngToMap(LatLng? latLng) {
      if (latLng == null) return null;
      return {'latitude': latLng.latitude, 'longitude': latLng.longitude};
    }

    return {
      'originName': originName,
      'destinationName': destinationName,
      if (originLocation != null) 'originLocation': latLngToMap(originLocation),
      if (destinationLocation != null)
        'destinationLocation': latLngToMap(destinationLocation),
      'rideDate': rideDate,
      'price': price,
      'status': status.toString(),
      if (driverName != null) 'driverName': driverName,
      if (vehicleDetails != null) 'vehicleDetails': vehicleDetails,
    };
  }
}
