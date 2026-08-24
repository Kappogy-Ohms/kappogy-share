import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_info_service.g.dart';

@riverpod
class NetworkInfoService extends _$NetworkInfoService {
  final Connectivity _connectivity = Connectivity();

  @override
  Stream<bool> build() {
    return _connectivity.onConnectivityChanged.map((List<ConnectivityResult> results) {
      // Check if any of the results indicate a local network connection
      return results.contains(ConnectivityResult.wifi) || 
             results.contains(ConnectivityResult.ethernet);
    });
  }

  Future<bool> checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi) || 
           results.contains(ConnectivityResult.ethernet);
  }
}
