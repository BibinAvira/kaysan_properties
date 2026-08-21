import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/network_service.dart';
import 'di_providers.dart';

/// Streams live connectivity status. Views (e.g. the shell) watch this to
/// show the "No Internet" screen/banner without polling manually.
final StreamProvider<bool> networkStatusProvider = StreamProvider<bool>((Ref ref) {
  final NetworkService network = ref.watch(networkServiceProvider);
  return network.onStatusChange;
});

final FutureProvider<bool> initialNetworkStatusProvider = FutureProvider<bool>((Ref ref) {
  return ref.watch(networkServiceProvider).isConnected;
});
