import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const _favoritesKey = 'favorite_eats_stores';

  // Retorna a lista de IDs das lojas favoritas
  static Future<List<String>> getFavoriteStoreIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  // Verifica se uma loja é favorita
  static Future<bool> isFavorite(String storeId) async {
    final favorites = await getFavoriteStoreIds();
    return favorites.contains(storeId);
  }

  // Adiciona uma loja aos favoritos
  static Future<void> addFavorite(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = await getFavoriteStoreIds();
    if (!favorites.contains(storeId)) {
      favorites.add(storeId);
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  // Remove uma loja dos favoritos
  static Future<void> removeFavorite(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = await getFavoriteStoreIds();
    if (favorites.contains(storeId)) {
      favorites.remove(storeId);
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  // Alterna o estado de favorito de uma loja
  static Future<bool> toggleFavoriteStatus(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = await getFavoriteStoreIds();
    bool isCurrentlyFavorite;
    if (favorites.contains(storeId)) {
      favorites.remove(storeId);
      isCurrentlyFavorite = false; // Estava favorito, agora não está mais
    } else {
      favorites.add(storeId);
      isCurrentlyFavorite = true; // Não estava, agora está
    }
    await prefs.setStringList(_favoritesKey, favorites);
    return isCurrentlyFavorite; // Retorna o novo estado de favorito
  }
}