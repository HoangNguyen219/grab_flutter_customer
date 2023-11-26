import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:grab_customer_app/models/driver.dart';
import 'package:grab_customer_app/models/ride.dart';
import 'package:grab_customer_app/utils/constants/ride_constants.dart';
import 'package:grab_customer_app/utils/constants/socket_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  final String baseUrl;
  late io.Socket socket;

  SocketService(this.baseUrl);

  void connect(
      {Function(Driver driver)? onOnlineDriver,
      Function(int)? onOfflineDriver,
      Function(Driver driver)? onAccept,
      Function()? onPick,
      Function()? onComplete,
      Function(Driver driver)? onChangeLocationDriver}) {
    socket = io.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) {
      print('Socket connected');
    });

    socket.onDisconnect((_) {
      print('Socket disconnected');
    });

    socket.on(SocketConstants.onlineDriver, (data) {
      var dataDecode = json.decode(data);
      onOnlineDriver?.call(Driver.fromJson(dataDecode));
    });

    socket.on(SocketConstants.offlineDriver, (data) {
      var dataDecode = json.decode(data);
      int driverId = dataDecode[RideConstants.driverId];
      onOfflineDriver?.call(driverId);
    });

    socket.on(SocketConstants.accept, (data) {
      var dataDecode = json.decode(data);
      onAccept?.call(Driver.fromJson(dataDecode));
    });

    socket.on(SocketConstants.pick, (data) {
      onPick?.call();
    });

    socket.on(SocketConstants.complete, (data) {
      onComplete?.call();
    });

    socket.on(SocketConstants.changeLocationDriver, (data) {
      var dataDecode = json.decode(data);
      onChangeLocationDriver?.call(Driver.fromJson(dataDecode));
    });

    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
  }

  void _sendMessage(String event, dynamic data) {
    socket.emit(event, json.encode(data));
  }

  void book(Ride ride) {
    _sendMessage(SocketConstants.book, ride.toJson());
  }

  void cancel(int driverId, int customerId) {
    _sendMessage(SocketConstants.cancel, {RideConstants.driverId: driverId, RideConstants.customerId: customerId});
  }

  void addCustomer(int customerId, Position location) {
    _sendMessage(SocketConstants.addCustomer, {
      RideConstants.customerId: customerId,
      RideConstants.location: {RideConstants.lat: location.latitude, RideConstants.long: location.longitude}
    });
  }

  void removeCustomer(int customerId) {
    _sendMessage(SocketConstants.removerCustomer, {RideConstants.customerId: customerId});
  }
}
