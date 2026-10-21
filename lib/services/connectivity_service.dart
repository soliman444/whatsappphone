import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService({
    this.overrideOnline,
    this.changes,
    this.connectivity,
  });

  final bool? overrideOnline;
  final Stream<bool>? changes;
  final Connectivity? connectivity;

  Future<bool> get isOnline async {
    if (overrideOnline != null) return overrideOnline!;
    final results = await (connectivity ?? Connectivity()).checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Stream<bool> watch() {
    if (changes != null) return changes!;
    return (connectivity ?? Connectivity()).onConnectivityChanged.map((
      results,
    ) {
      return results.any((result) => result != ConnectivityResult.none);
    });
  }
}
