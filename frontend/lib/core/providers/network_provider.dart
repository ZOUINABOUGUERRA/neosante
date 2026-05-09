import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity service provider
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Network connectivity status stream provider
/// ✅ إصلاح: استخدام Stream<List<ConnectivityResult>> بدلاً من Stream<ConnectivityResult>
final networkStatusStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.onConnectivityChanged;
});

/// Current network status provider (returns true if connected)
final isConnectedProvider = FutureProvider<bool>((ref) async {
  final connectivity = ref.watch(connectivityProvider);
  final result = await connectivity.checkConnectivity();
  return result != ConnectivityResult.none;
});

/// Network status notifier for reactive connectivity state
final networkStatusProvider = StateNotifierProvider<NetworkStatusNotifier, bool>((ref) {
  return NetworkStatusNotifier(ref);
});

class NetworkStatusNotifier extends StateNotifier<bool> {
  final Ref ref;
  late final Stream<List<ConnectivityResult>> _connectivityStream;

  NetworkStatusNotifier(this.ref) : super(true) {
    _connectivityStream = ref.read(connectivityProvider).onConnectivityChanged;
    _connectivityStream.listen((List<ConnectivityResult> results) {
      // ✅ التحقق من وجود اتصال في أي من النتائج
      final isConnected = results.any((result) => result != ConnectivityResult.none);
      state = isConnected;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}