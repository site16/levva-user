import 'dart:convert'; // Para json.decode
import 'package:flutter/foundation.dart'; // Para kDebugMode (opcional)
// CORREÇÃO DA IMPORTAÇÃO:
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Caminho correto do pacote
import 'package:http/http.dart' as http; // Pacote HTTP
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; // Para decodificar polilinhas

class GoogleMapsService {
  // -----------------------------------------------------------------------------
  // A SUA CHAVE DE API DO GOOGLE MAPS PLATFORM
  // -----------------------------------------------------------------------------
  // Substitua esta pela chave correta da sua lista no Google Cloud Console,
  // garantindo que ela tem as APIs necessárias (Places, Directions, etc.) habilitadas
  // e as restrições de aplicativo (SHA-1, nome do pacote) corretas.
  // -----------------------------------------------------------------------------
  final String _apiKey =
      "AIzaSyB-ndmzkK76iAyXF0hFccBu4w5P27SD_uU"; // <<< A SUA CHAVE DE API AQUI

  final String _placesBaseUrl = "https://maps.googleapis.com/maps/api/place";
  final String _directionsBaseUrl =
      "https://maps.googleapis.com/maps/api/directions/json";

  GoogleMapsService() {
    if (_apiKey == "SUA_CHAVE_DE_API_AQUI" && kDebugMode) {
      // Verificação genérica de placeholder
      print(
        "ALERTA CRÍTICO: GoogleMapsService está a usar uma API Key placeholder. Verifique se a chave foi substituída.",
      );
    }
    print("GoogleMapsService Inicializado.");
  }

  // --- Busca de Endereços (Autocompletar) ---
  Future<List<Map<String, String>>> searchPlaceAutoComplete(
    String query, {
    String? sessionToken,
  }) async {
    if (_apiKey.startsWith("SUA_CHAVE")) {
      // Uma verificação simples
      print(
        "GoogleMapsService: API Key não configurada para searchPlaceAutoComplete.",
      );
      throw Exception("API Key não configurada.");
    }
    if (query.length < 3) return [];

    String url =
        "$_placesBaseUrl/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$_apiKey&language=pt-BR&components=country:BR";
    if (sessionToken != null) {
      url += "&sessiontoken=$sessionToken";
    }
    print("GoogleMapsService: Buscando Autocomplete URL: $url");

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List predictions = data['predictions'];
          return predictions.map((p) {
            return {
              'description': p['description'] as String? ?? '',
              'place_id': p['place_id'] as String? ?? '',
            };
          }).toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          print(
            "Erro na API Places Autocomplete: ${data['status']} - ${data['error_message'] ?? ''}",
          );
          throw Exception(
            "Erro na busca de endereços (${data['status']}): ${data['error_message'] ?? 'Verifique as configurações da sua API Key e da Places API.'}",
          );
        }
      } else {
        print(
          "Erro HTTP na busca de Places: ${response.statusCode} - ${response.body}",
        );
        throw Exception(
          "Erro HTTP ${response.statusCode} na busca de endereços.",
        );
      }
    } catch (e) {
      print("Exceção na busca de Places: $e");
      throw Exception("Exceção na busca de endereços: $e");
    }
  }

  // --- Obter Detalhes de um Local (incluindo LatLng) a partir do Place ID ---
  Future<LatLng?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    if (_apiKey.startsWith("SUA_CHAVE")) {
      print("GoogleMapsService: API Key não configurada para getPlaceDetails.");
      throw Exception("API Key não configurada.");
    }
    if (placeId.isEmpty) return null;

    String url =
        "$_placesBaseUrl/details/json?place_id=$placeId&key=$_apiKey&language=pt-BR&fields=geometry/location,formatted_address";
    if (sessionToken != null) {
      url += "&sessiontoken=$sessionToken";
    }
    print("GoogleMapsService: Buscando Detalhes do Local URL: $url");

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' &&
            data['result']?['geometry']?['location'] != null) {
          final location = data['result']['geometry']['location'];
          // String? formattedAddress = data['result']?['formatted_address']; // Você pode querer retornar este também
          return LatLng(location['lat'], location['lng']);
        } else {
          print(
            "Erro na API Places Details: ${data['status']} - ${data['error_message'] ?? ''}",
          );
          throw Exception(
            "Erro ao obter detalhes do local (${data['status']}): ${data['error_message'] ?? 'Verifique as configurações da sua API Key e da Places API.'}",
          );
        }
      } else {
        print(
          "Erro HTTP ao obter detalhes do Place: ${response.statusCode} - ${response.body}",
        );
        throw Exception(
          "Erro HTTP ${response.statusCode} ao obter detalhes do local.",
        );
      }
    } catch (e) {
      print("Exceção ao obter detalhes do Place: $e");
      throw Exception("Exceção ao obter detalhes do local: $e");
    }
  }

  // --- Obter Rota e Detalhes da Direção ---
  Future<Map<String, dynamic>?> getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    if (_apiKey.startsWith("SUA_CHAVE")) {
      print("GoogleMapsService: API Key não configurada para getDirections.");
      throw Exception("API Key não configurada.");
    }

    String url =
        "$_directionsBaseUrl?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey&language=pt-BR";
    print("GoogleMapsService: Buscando Direções URL: $url");

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          if (route['legs'] != null && (route['legs'] as List).isNotEmpty) {
            final leg = route['legs'][0];
            List<LatLng> decodedPolylinePoints = [];
            if (route['overview_polyline']?['points'] != null) {
              List<PointLatLng> result = PolylinePoints().decodePolyline(
                route['overview_polyline']['points'],
              );
              decodedPolylinePoints =
                  result
                      .map((point) => LatLng(point.latitude, point.longitude))
                      .toList();
            }

            return {
              'polyline_points': decodedPolylinePoints,
              'distance_text': leg['distance']?['text'] as String?,
              'distance_value': leg['distance']?['value'] as int?,
              'duration_text': leg['duration']?['text'] as String?,
              'duration_value': leg['duration']?['value'] as int?,
              'bounds': LatLngBounds(
                southwest: LatLng(
                  route['bounds']['southwest']['lat'],
                  route['bounds']['southwest']['lng'],
                ),
                northeast: LatLng(
                  route['bounds']['northeast']['lat'],
                  route['bounds']['northeast']['lng'],
                ),
              ),
            };
          }
        }
        print(
          "Erro na API Directions: ${data['status']} - ${data['error_message'] ?? 'Rota não encontrada'}",
        );
        throw Exception(
          "Erro ao obter direções (${data['status']}): ${data['error_message'] ?? 'Verifique as configurações da sua API Key e da Directions API.'}",
        );
      } else {
        print(
          "Erro HTTP ao obter direções: ${response.statusCode} - ${response.body}",
        );
        throw Exception("Erro HTTP ${response.statusCode} ao obter direções.");
      }
    } catch (e) {
      print("Exceção ao obter direções: $e");
      throw Exception("Exceção ao obter direções: $e");
    }
  }
}
