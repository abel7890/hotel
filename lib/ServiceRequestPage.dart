import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequestPage extends StatefulWidget {
  const ServiceRequestPage({Key? key}) : super(key: key);

  @override
  _ServiceRequestPageState createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Service Requests"),
        backgroundColor: Colors.teal, // Custom background color for the AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('service_requests')
              .orderBy('timestamp', descending: true) // Order by timestamp to show the latest requests first
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No service requests available"));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final serviceRequest = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                String roomNumber = serviceRequest['roomNumber'] ?? 'Unknown Room';
                String serviceType = serviceRequest['serviceType'] ?? 'Unknown Service';
                String details = serviceRequest['details'] ?? 'No details provided';
                String status = serviceRequest['status'] ?? 'pending';
                String requestId = snapshot.data!.docs[index].id;  // Get the requestId here

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 8,
                  color: Colors.teal.shade50, // Light background color for the card
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: Icon(
                      Icons.room_service,
                      color: Colors.teal,
                      size: 40,
                    ),
                    title: Text(
                      'Room $roomNumber - $serviceType',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details: $details',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: status == 'completed' ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.teal),
                      onPressed: () async {
                        // Pass the requestId to the dialog
                        await _updateStatusDialog(context, requestId, status);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Dialog to update the status of a service request
  Future<void> _updateStatusDialog(BuildContext context, String requestId, String currentStatus) async {
    final statusController = TextEditingController(text: currentStatus);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Service Request Status'),
          content: TextField(
            controller: statusController,
            decoration: const InputDecoration(
              labelText: 'Service Status',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                String newStatus = statusController.text.trim();
                if (newStatus.isNotEmpty) {
                  await _updateStatus(requestId, newStatus);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid status')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // Button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Update Status'),
            ),
          ],
        );
      },
    );
  }

  // Function to update the status in Firestore
  Future<void> _updateStatus(String requestId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('service_requests')
          .doc(requestId) // Use the requestId to find the correct document
          .update({
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to: $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }
}
