library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vault_store.dart';
import '../models/case_models.dart';
import '../services/auth_service.dart';
import '../services/court_lookup_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final apiClientProvider = Provider((ref) => ApiClient(auth: ref.read(authServiceProvider)));

final vaultStoreProvider = ChangeNotifierProvider<VaultStore>((ref) {
  final store = VaultStore();
  store.loadFromDisk();
  return store;
});

final activeCasesProvider = Provider<List<MunshiCase>>((ref) {
  ref.watch(vaultStoreProvider);
  return ref.read(vaultStoreProvider).listCases();
});

final disposedCasesProvider = Provider<List<MunshiCase>>((ref) {
  ref.watch(vaultStoreProvider);
  return ref.read(vaultStoreProvider).disposedCases();
});
