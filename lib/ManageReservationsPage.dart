import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageReservationsPage extends StatefulWidget {
  const ManageReservationsPage({Key? key}) : super(key: key);

  @override
  _ManageReservationsPageState createState() => _ManageReservationsPageState();
}

class _ManageReservationsPageState extends State<ManageReservationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light background
      appBar: AppBar(
        title: const Text("Manage Reservations"),
        backgroundColor: Colors.brown[700], // Dark Brown Theme
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildReservationSection("Pending", Colors.orange, Icons.hourglass_empty),
            _buildReservationSection("Approved", Colors.green, Icons.check_circle),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationSection(String status, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 8),
              Text(
                "$status Reservations",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('status', isEqualTo: status)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "No $status reservations found.",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }

              final reservations = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reservations.length,
                itemBuilder: (context, index) {
                  final reservation = reservations[index];
                  final data = reservation.data() as Map<String, dynamic>;
                  final idProofUrl = data['idProofImageUrl'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ListTile(
                        title: Text(
                          "Reservation ID: ${reservation.id}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("User Name: ${data['userName'] ?? 'Unknown'}"),
                            if (status == "Approved" && data.containsKey('roomNo'))
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Room No: ${data['roomNo'] ?? 'Not Assigned'}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () {
                            _showDetailsDialog(context, reservation, idProofUrl);
                          },
                          icon: const Icon(Icons.info, size: 18),
                          label: const Text("Review"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, DocumentSnapshot reservation, String idProofUrl) {
    final data = reservation.data() as Map<String, dynamic>;

    final userName = data['userName'] ?? 'N/A';
    final userAddress = data['userAddress'] ?? 'N/A';
    final userAge = data['userAge'] ?? 'N/A';
    final roomType = data['roomType'] ?? 'N/A';
    final duration = data['duration']?.toString() ?? 'N/A';
    final price = data['price']?.toString() ?? 'N/A';
    final totalPrice = data['totalPrice']?.toString() ?? 'N/A';
    final roomNo = data['roomNo'] ?? '';

    TextEditingController roomNoController = TextEditingController(text: roomNo);
    bool isApproved = data['status'] == 'Approved';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Reservation Details",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("User Name: $userName"),
                const SizedBox(height: 8),
                Text("Address: $userAddress"),
                const SizedBox(height: 8),
                Text("Age: $userAge"),
                const SizedBox(height: 8),
                Text("Room Type: $roomType"),
                const SizedBox(height: 8),
                Text("Duration: $duration days"),
                const SizedBox(height: 8),
                Text("Price per Day: ₹$price"),
                const SizedBox(height: 8),
                Text("Total Price: ₹$totalPrice"),
                const SizedBox(height: 12),
              
                if (isApproved)
                  TextField(
                    controller: roomNoController,
                    decoration: const InputDecoration(
                      labelText: 'Assign Room Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
              ],
            ),
          ),
          actions: [
            if (!isApproved)
              ElevatedButton.icon(
                onPressed: () {
                  _updateReservationStatus(reservation.id, 'Approved');
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check),
                label: const Text("Approve"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            if (!isApproved)
              ElevatedButton.icon(
                onPressed: () {
                  _updateReservationStatus(reservation.id, 'Rejected');
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close),
                label: const Text("Reject"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            if (isApproved)
              ElevatedButton.icon(
                onPressed: () {
                  if (roomNoController.text.isNotEmpty) {
                    _updateReservationStatus(reservation.id, 'Approved', roomNoController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a room number")),
                    );
                  }
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.save),
                label: const Text("Save Room No."),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
          ],
        );
      },
    );
  }

  Future<void> _updateReservationStatus(String reservationId, String status, [String? roomNo]) async {
    try {
      final collection = FirebaseFirestore.instance.collection('bookings');
      if (status == 'Rejected') {
        await collection.doc(reservationId).delete();
      } else {
        final updateData = {'status': status};
        if (roomNo != null && roomNo.isNotEmpty) {
          updateData['roomNo'] = roomNo;
        }
        await collection.doc(reservationId).update(updateData);
      }
    } catch (e) {}
  }
}
