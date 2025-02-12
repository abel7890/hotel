import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllocateRoomPage extends StatefulWidget {
  const AllocateRoomPage({Key? key}) : super(key: key);

  @override
  _AllocateRoomPageState createState() => _AllocateRoomPageState();
}

class _AllocateRoomPageState extends State<AllocateRoomPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Allocate Room Numbers"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('status', isEqualTo: 'Approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No approved reservations found."),
            );
          }

          final reservations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              final data = reservation.data() as Map<String, dynamic>;
              final roomNo = data['roomNo'] ?? '';
              final roomNoController = TextEditingController(text: roomNo);

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text("Reservation ID: ${reservation.id}"),
                  subtitle: Text("User Name: ${data['userName'] ?? 'Unknown'}"),
                  trailing: roomNo.isEmpty
                      ? ElevatedButton(
                          onPressed: () {
                            _showAllocateRoomDialog(context, reservation.id, roomNoController);
                          },
                          child: const Text("Allocate Room"),
                        )
                      : Text("Room No: $roomNo"),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAllocateRoomDialog(BuildContext context, String reservationId, TextEditingController roomNoController) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Allocate Room Number",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: roomNoController,
            decoration: const InputDecoration(
              labelText: 'Enter Room Number',
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (roomNoController.text.isNotEmpty) {
                  _updateRoomNumber(reservationId, roomNoController.text);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a room number")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: const Text("Save Room Number"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateRoomNumber(String reservationId, String roomNo) async {
    try {
      final collection = FirebaseFirestore.instance.collection('bookings');
      await collection.doc(reservationId).update({
        'roomNo': roomNo,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Room number allocated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating room number: $e")),
      );
    }
  }
}
