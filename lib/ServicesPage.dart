import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServicesPage extends StatefulWidget {
  final String selectedRoomNumber;

  const ServicesPage({Key? key, required this.selectedRoomNumber}) : super(key: key);

  @override
  _ServicesPageState createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late String allocatedRoomNumber;

  @override
  void initState() {
    super.initState();
    allocatedRoomNumber = widget.selectedRoomNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Services"),

        backgroundColor: const Color.fromARGB(255, 255, 255, 255)
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room $allocatedRoomNumber Allocated',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Service Status Section
            const Text(
              'Active Service Requests:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              // Modified query to remove ordering by timestamp
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('service_requests')
                    .where('roomNumber', isEqualTo: allocatedRoomNumber)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No active service requests'),
                    );
                  }

                  // Sort the documents in memory instead of in the query
                  final sortedDocs = snapshot.data!.docs.toList()
                    ..sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aTimestamp = aData['timestamp'] as Timestamp?;
                      final bTimestamp = bData['timestamp'] as Timestamp?;
                      if (aTimestamp == null || bTimestamp == null) return 0;
                      return bTimestamp.compareTo(aTimestamp); // Descending order
                    });

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: sortedDocs.length,
                    itemBuilder: (context, index) {
                      final request = sortedDocs[index];
                      final data = request.data() as Map<String, dynamic>;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(data['serviceType']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['details']),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(data['status']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      data['status'].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (data['timestamp'] != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTimestamp(data['timestamp'] as Timestamp),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: data['status'] == 'pending'
                              ? IconButton(
                                  icon: const Icon(Icons.cancel),
                                  onPressed: () => _cancelRequest(request.id),
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            const Divider(),
            const SizedBox(height: 10),
            
            // Service Request Buttons
            const Text(
              'Request New Service:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ServiceButton(
              service: 'Room Cleaning',
              onPressed: () => _showServiceForm(context, 'Cleaning'),
            ),
            const SizedBox(height: 10),
            ServiceButton(
              service: 'Laundry',
              onPressed: () => _showServiceForm(context, 'Laundry'),
            ),
            const SizedBox(height: 10),
            ServiceButton(
              service: 'Taxi Service',
              onPressed: () => _showServiceForm(context, 'Taxi'),
            ),
            const SizedBox(height: 10),
            ServiceButton(
              service: 'Help Request',
              onPressed: () => _showServiceForm(context, 'Help'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('service_requests')
          .doc(requestId)
          .update({'status': 'cancelled'});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service request cancelled')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling request: $e')),
      );
    }
  }

  void _showServiceForm(BuildContext context, String serviceType) {
    final serviceDetailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Request $serviceType'),
          content: TextField(
            controller: serviceDetailsController,
            decoration: InputDecoration(
              labelText: '$serviceType Details',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (serviceDetailsController.text.isNotEmpty) {
                  await _storeServiceRequest(
                    allocatedRoomNumber,
                    serviceType,
                    serviceDetailsController.text,
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide details')),
                  );
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _storeServiceRequest(
      String roomNumber, String serviceType, String details) async {
    try {
      await FirebaseFirestore.instance.collection('service_requests').add({
        'roomNumber': roomNumber,
        'serviceType': serviceType,
        'details': details,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$serviceType request submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class ServiceButton extends StatelessWidget {
  final String service;
  final VoidCallback onPressed;

  const ServiceButton({required this.service, required this.onPressed, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        textStyle: const TextStyle(fontSize: 16),
      ),
      child: Text(service),
    );
  }
}