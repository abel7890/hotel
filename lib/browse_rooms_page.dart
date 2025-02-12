import 'package:flutter/material.dart';

class BrowseRoomsPage extends StatelessWidget {
  const BrowseRoomsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Browse Rooms")),
      body: const Center(
        child: Text("Here you can browse available rooms."),
      ),
    );
  }
}
