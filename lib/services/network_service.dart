import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps `connectivity_plus` behind a small stream/future API so the
/// providers layer doesn't depend on the plugin's enum shape directly.
class NetworkService {
  NetworkService([Connectivity? connectivity]) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> get isConnected async {
    final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none) && result.isNotEmpty;
  }

  Stream<bool> get onStatusChange {
    return _connectivity.onConnectivityChanged.map(
      (List<ConnectivityResult> results) =>
          results.isNotEmpty && !results.contains(ConnectivityResult.none),
    );
  }
}
