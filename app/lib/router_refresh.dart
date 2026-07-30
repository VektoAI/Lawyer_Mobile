library;

import 'package:flutter/foundation.dart';

class RouterRefresh extends ChangeNotifier {
  RouterRefresh._();
  static final instance = RouterRefresh._();

  void ping() => notifyListeners();
}

void notifyRouterVaultChanged() => RouterRefresh.instance.ping();
