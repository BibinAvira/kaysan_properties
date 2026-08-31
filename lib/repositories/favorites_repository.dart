import 'package:shared_preferences/shared_preferences.dart';

/// Persists favorited project IDs locally. No backend involvement — this is
/// a device-local preference, so SharedPreferences is the right tool rather
/// than routing it through the API layer.
class FavoritesRepository {
  static const String _key = 'favorite_project_ids';

  Future<Set<int>> getFavoriteIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList(_key) ?? <String>[];
    return stored.map(int.parse).toSet();
  }

  Future<Set<int>> toggle(int projectId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Set<int> current = await getFavoriteIds();
    if (current.contains(projectId)) {
      current.remove(projectId);
    } else {
      current.add(projectId);
    }
    await prefs.setStringList(_key, current.map((int e) => e.toString()).toList());
    return current;
  }

  /// Unions [ids] into the local set without touching entries already
  /// there — used to fold in a logged-in user's server-side saved
  /// properties on login without clobbering anything favorited locally.
  Future<Set<int>> addAll(Set<int> ids) async {
    if (ids.isEmpty) return getFavoriteIds();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Set<int> merged = <int>{...await getFavoriteIds(), ...ids};
    await prefs.setStringList(_key, merged.map((int e) => e.toString()).toList());
    return merged;
  }
}
