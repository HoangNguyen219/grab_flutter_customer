import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:grab_customer_app/models/ride.dart';
import 'package:grab_customer_app/utils/constants/ride_constants.dart';
import 'package:grab_customer_app/utils/constants/socket_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  final String baseUrl;
  late io.Socket socket;

  SocketService(this.baseUrl);

  void connect({Function(Ride ride)? onOnlineCustomer, Function(int)? onCancel, Function(int)? onOfflineCustomer}) {
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

    socket.on(SocketConstants.onlineCustomer, (data) {
      var dataDecode = json.decode(data);
      if (dataDecode != null && dataDecode is Map<String, dynamic>) {
        int? rideId = dataDecode[RideConstants.rideId] as int?;
        int? customerId = dataDecode[RideConstants.customerId] as int?;
        Map<String, dynamic>? startLocation = dataDecode[RideConstants.startLocation];
        Map<String, dynamic>? endLocation = dataDecode[RideConstants.endLocation];
        String? startAddress = dataDecode[RideConstants.startAddress] as String?;
        String? endAddress = dataDecode[RideConstants.endAddress] as String?;
        double? distance = dataDecode[RideConstants.distance] as double?;
        int? price = dataDecode[RideConstants.price] as int?;

        if (rideId != null &&
            customerId != null &&
            startLocation != null &&
            endLocation != null &&
            startAddress != null &&
            endAddress != null &&
            distance != null &&
            price != null) {
          onOnlineCustomer?.call(Ride(
              id: rideId,
              customerId: customerId,
              startLocation: startLocation,
              endLocation: endLocation,
              startAddress: startAddress,
              endAddress: endAddress,
              distance: distance,
              price: price));
        }
      }
    });

    socket.on(SocketConstants.cancel, (data) {
      var dataDecode = json.decode(data);
      int customerId = dataDecode[RideConstants.customerId];
      onCancel?.call(customerId);
    });

    socket.on(SocketConstants.offlineCustomer, (data) {
      var dataDecode = json.decode(data);
      int customerId = dataDecode[RideConstants.customerId];
      onOfflineCustomer?.call(customerId);
    });

    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
  }

  void _sendMessage(String event, dynamic data) {
    socket.emit(event, json.encode(data));
  }

  void addDriver(int driverId, Position location) {
    _sendMessage(SocketConstants.addDriver, {
      RideConstants.customerId: driverId,
      RideConstants.location: {RideConstants.lat: location.latitude, RideConstants.long: location.longitude}
    });
  }

  void removeDriver(int driverId) {
    _sendMessage(SocketConstants.removerDriver, {RideConstants.customerId: driverId});
  }

  void acceptRide(int driverId, int customerId) {
    _sendMessage(SocketConstants.accept, {RideConstants.customerId: driverId, RideConstants.customerId: customerId});
  }

  void pickRide(int driverId, int customerId) {
    _sendMessage(SocketConstants.pick, {RideConstants.customerId: driverId, RideConstants.customerId: customerId});
  }

  void completeRide(int driverId, int customerId) {
    _sendMessage(SocketConstants.complete, {RideConstants.customerId: driverId, RideConstants.customerId: customerId});
  }
}
