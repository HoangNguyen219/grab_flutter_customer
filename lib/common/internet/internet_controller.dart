import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectionType { WiFi, Mobile, None }

enum InternetState {
  InternetLoading,
  InternetConnected,
  InternetDisconnected,
}

class InternetController extends GetxController {
  Rx<InternetState> internetState = InternetState.InternetLoading.obs;
  final Connectivity? connectivity = Connectivity();
  final Rx<ConnectionType> _connectionType = Rx<ConnectionType>(ConnectionType.None);

  ConnectionType get connectionType => _connectionType.value;

  @override
  void onInit() {
    super.onInit();
    monitorInternetConnection();
  }

  Future<void> monitorInternetConnection() async {
    connectivity!.onConnectivityChanged.listen((connectivityResult) async {
      try {
        final result = await InternetAddress.lookup("example.com");
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          if (connectivityResult == ConnectivityResult.wifi) {
            _changeInternetState(InternetState.InternetConnected, ConnectionType.WiFi);
          } else if (connectivityResult == ConnectivityResult.mobile) {
            _changeInternetState(InternetState.InternetConnected, ConnectionType.Mobile);
          } else if (connectivityResult == ConnectivityResult.none) {
            _changeInternetState(InternetState.InternetDisconnected, ConnectionType.None);
          }
        }
      } on SocketException catch (_) {
        _changeInternetState(InternetState.InternetDisconnected, ConnectionType.None);
      }
    });
  }

  void _changeInternetState(InternetState state, ConnectionType connectionType) {
    internetState.value = state;
    _connectionType.value = connectionType;
  }

  @override
  void onClose() {
    super.onClose();
    // Ensure to cancel the subscription when the controller is closed
    connectivity!.onConnectivityChanged.drain<dynamic>();
  }
}
