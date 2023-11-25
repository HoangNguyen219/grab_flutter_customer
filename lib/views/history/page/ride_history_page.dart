import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grab_customer_app/common/widget/loading_widget.dart';
import 'package:grab_customer_app/controllers/ride_controller.dart';
import 'package:grab_customer_app/models/ride.dart';
import 'package:grab_customer_app/views/history/widget/ride_history_tile_widget.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  _RideHistoryPageState createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  final RideController rideController = Get.find();

  @override
  void initState() {
    rideController.getRides();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Your Rides"),
      ),
      body: RefreshIndicator(
        onRefresh: rideController.getRides,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Obx(() {
            if (rideController.isLoading.value) {
              return const LoadingWidget();
            } else if (rideController.rideHistoryList.isEmpty) {
              return const Center(child: Text("No Ride History Found."));
            } else {
              return _buildListWidget(rideController.rideHistoryList);
            }
          }),
        ),
      ),
    );
  }

  Widget _buildListWidget(List<Ride> rideHistoryList) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        itemCount: rideHistoryList.length,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          return RideHistoryTile(ride: rideHistoryList[index]);
        },
      ),
    );
  }
}
