import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _sessionIdKey = 'guest_session_id';
const String _recentlyViewedKey = 'guest_recently_viewed';
const String _lastSearchKey = 'guest_last_search_query';
const int _recentlyViewedLimit = 20;

/// A lightweight, on-device identity for someone browsing without an
/// account — lets the rest of the app (analytics, "recently viewed",
/// future personalization) refer to "this browsing session" even though
/// there's no server-side account behind it yet.
///
/// There is currently no backend endpoint to sync guest activity to an
/// account, so "merging guest data into the new account" on login is a
/// no-op by construction: everything below is already stored locally on
/// the device (not namespaced by session ID), so it simply keeps existing
/// as the signed-in user's local data — nothing to copy or reconcile.
/// [GuestSessionController.clearSessionId] just retires the guest
/// identifier itself once someone has an account.
class GuestSessionController extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? existing = prefs.getString(_sessionIdKey);
    if (existing != null) return existing;

    final String id = _generateId();
    await prefs.setString(_sessionIdKey, id);
    return id;
  }

  /// Retires the guest identifier — call once someone has successfully
  /// logged in or registered, since they're no longer browsing as a guest.
  /// Recently-viewed/search history is left in place (see class doc): it's
  /// plain local storage, not tied to the guest ID, so it just carries
  /// over as this device's data.
  Future<void> clearSessionId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionIdKey);
  }

  static String _generateId() {
    final Random random = Random();
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int suffix = random.nextInt(0xFFFFFF);
    return 'guest_${timestamp}_${suffix.toRadixString(16)}';
  }
}

final AsyncNotifierProvider<GuestSessionController, String>
    guestSessionProvider =
    AsyncNotifierProvider<GuestSessionController, String>(
        GuestSessionController.new);

/// Recently-viewed properties and the last search query — the "Store:
/// viewed properties, search preferences, recently viewed items" guest
/// data the app keeps locally regardless of login state.
class GuestActivityController extends AsyncNotifier<List<int>> {
  @override
  Future<List<int>> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentlyViewedKey)?.map(int.parse).toList() ??
        <int>[];
  }

  Future<void> recordViewed(int projectId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<int> current = await future;
    final List<int> updated = <int>[
      projectId,
      ...current.where((int id) => id != projectId),
    ].take(_recentlyViewedLimit).toList();
    await prefs.setStringList(
        _recentlyViewedKey, updated.map((int id) => id.toString()).toList());
    state = AsyncValue<List<int>>.data(updated);
  }

  Future<void> recordSearchQuery(String query) async {
    if (query.trim().isEmpty) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSearchKey, query.trim());
  }

  static Future<String?> lastSearchQuery() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSearchKey);
  }
}

final AsyncNotifierProvider<GuestActivityController, List<int>>
    guestActivityProvider =
    AsyncNotifierProvider<GuestActivityController, List<int>>(
        GuestActivityController.new);
