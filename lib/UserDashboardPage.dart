import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hotel/FeedbackPage.dart';
import 'package:hotel/ServicesPage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Main App Code
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UserDashboardPage(),
    );
  }
}

// User Dashboard Page
class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({Key? key}) : super(key: key);

  @override
  _UserDashboardPageState createState() => _UserDashboardPageState();
}


class _UserDashboardPageState extends State<UserDashboardPage> {
  String selectedRoomType = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "User Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.book_online, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReservationStatusPage()),
              );
            },
          ),
        
          IconButton(
            icon: const Icon(Icons.feedback, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Available Rooms",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              // Dropdown with new styling
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: selectedRoomType,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Deluxe', child: Text('Deluxe')),
                    DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                    DropdownMenuItem(value: 'Economy', child: Text('Economy')),
                 
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRoomType = value!;
                    });
                  },
                  hint: const Text('Select Room Type'),
                ),
              ),
              const SizedBox(height: 10),

              // Room List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No rooms available",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      );
                    }

                    final filteredRooms = selectedRoomType == 'All'
                        ? snapshot.data!.docs
                        : snapshot.data!.docs.where((doc) =>
                            (doc.data() as Map<String, dynamic>)['type'] == selectedRoomType).toList();

                    return ListView.builder(
                      itemCount: filteredRooms.length,
                      itemBuilder: (context, index) {
                        final room = filteredRooms[index].data() as Map<String, dynamic>;

                        return RoomCard(
                          roomData: room,
                          onBookNow: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingFormPage(roomData: room),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Room Card with enhanced UI
class RoomCard extends StatelessWidget {
  final Map<String, dynamic> roomData;
  final VoidCallback onBookNow;

  const RoomCard({
    Key? key,
    required this.roomData,
    required this.onBookNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image with rounded corners
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              roomData['image'],
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Type
                Text(
                  roomData['type'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 4),

                // Room Description
                Text(
                  roomData['description'],
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Room Price
                Text(
                  '₹${roomData['price']} / night',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),

                // Book Now Button with stylish gradient
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBookNow,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.blueAccent,
                      elevation: 5,
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class BookingFormPage extends StatefulWidget {
  final Map<String, dynamic> roomData;

  const BookingFormPage({Key? key, required this.roomData}) : super(key: key);

  @override
  _BookingFormPageState createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final TextEditingController durationController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  double totalPrice = 0.0;
  File? _idProofImage;
  Uint8List? _webIdProofImage;
  bool isUploading = false;

  // Calculate the total price
  void _calculateTotalPrice() {
    final duration = int.tryParse(durationController.text) ?? 0;
    final roomPrice = double.tryParse(widget.roomData['price'].toString()) ?? 0.0;

    setState(() {
      totalPrice = duration > 0 ? roomPrice * duration : 0.0;
    });
  }

  // Pick an image using ImagePicker
  Future<void> _pickIdProofImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webIdProofImage = bytes;
        });
      } else {
        setState(() {
          _idProofImage = File(pickedFile.path);
        });
      }
    }
  }

  // Upload the ID proof image to Firebase Storage
  Future<String?> _uploadIdProofImage() async {
    if (_idProofImage == null && _webIdProofImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('id_proofs/${DateTime.now().millisecondsSinceEpoch}.jpg');
      TaskSnapshot snapshot;

      if (kIsWeb) {
        snapshot = await storageRef.putData(_webIdProofImage!);
      } else {
        snapshot = await storageRef.putFile(_idProofImage!);
      }

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error during image upload: $e");
      return null;
    }
  }

  // Confirm Booking method
  Future<void> _confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to book a room.")),
      );
      return;
    }

    if (fullNameController.text.isNotEmpty &&
        ageController.text.isNotEmpty &&
        addressController.text.isNotEmpty &&
        durationController.text.isNotEmpty) {
      final idProofUrl = await _uploadIdProofImage();

      try {
        await FirebaseFirestore.instance.collection('bookings').add({
          'userId': user.uid,
          'userName': fullNameController.text,
          'userAge': ageController.text,
          'userAddress': addressController.text,
          'roomType': widget.roomData['type'],
          'description': widget.roomData['description'],
          'price': widget.roomData['price'],
          'duration': durationController.text,
          'totalPrice': totalPrice,
          'idProofUrl': idProofUrl ?? '',
          'status': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking Successful!")),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking failed: $e")),
        );
      } finally {
        setState(() {
          isUploading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Booking"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Room: ${widget.roomData['type']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Description: ${widget.roomData['description']}"),
              Text("Price per night: ₹${widget.roomData['price']}"),
              const SizedBox(height: 20),
              const Text("Enter Duration (in nights):"),
              TextField(controller: durationController, keyboardType: TextInputType.number, onChanged: (_) => _calculateTotalPrice()),
              Text("Total Price: ₹$totalPrice", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text("Personal Details", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: fullNameController, decoration: const InputDecoration(labelText: "Full Name")),
              TextField(controller: ageController, decoration: const InputDecoration(labelText: "Age")),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () async {
                  setState(() { isUploading = true; });
                  await _confirmBooking();
                },
                child: isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text("Confirm Booking"),
              )),
            ],
          ),
        ),
      ),
    );
  }
}











class ReservationStatusPage extends StatelessWidget {
  const ReservationStatusPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid; // Get logged-in user ID

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Reservation Status"),
          backgroundColor: Color(0xFF0059FF),
        ),
        body: const Center(
          child: Text("Please log in to view reservations."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservation Status"),
        backgroundColor: Color(0xFF0059FF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: userId) // Filter reservations by logged-in user
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No reservations found.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          final reservations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              final data = reservation.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF0084FF), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            data['userName'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.home, color: Color(0xFF0084FF), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Address: ${data['userAddress'] ?? 'N/A'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.room, color: Color(0xFF0084FF), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Room No: ${data['roomNo'] ?? 'N/A'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.hotel, color: Color(0xFF0084FF), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Room Type: ${data['roomType'] ?? 'N/A'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF0084FF), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Duration: ${data['duration'] ?? 0} days",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Color(0xFF0084FF), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Price per Day: ₹${data['price'] ?? 'N/A'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.money, color: Color(0xFF0084FF), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Total Price: ₹${data['totalPrice'] ?? 'N/A'}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Colors.grey),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Status:",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          _buildStatusChip(data['status']),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0084FF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        onPressed: () {
  final String roomNo = data['roomNo'] ?? 'N/A';
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ServicesPage(selectedRoomNumber: roomNo), // Pass room number correctly
    ),
  );
},

                          child: const Text(
                            "Request a Service",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color chipColor = Colors.grey;
    String statusText = status ?? "Pending";

    switch (statusText.toLowerCase()) {
      case "confirmed":
        chipColor = Colors.green;
        break;
      case "pending":
        chipColor = Colors.orange;
        break;
      case "cancelled":
        chipColor = Colors.red;
        break;
    }

    return Chip(
      label: Text(
        statusText.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: chipColor,
    );
  }
}

// ServicesPage



class ServiceRequestPage extends StatefulWidget {
  const ServiceRequestPage({Key? key}) : super(key: key);

  @override
  _ServiceRequestPageState createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Service Requests"),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.indigo.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Manage Service Requests",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Monitor and update service requests efficiently.",
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Requests List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('service_requests')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No service requests found.",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  final requests = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final data = request.data() as Map<String, dynamic>;

                      String roomNumber = data['roomNumber'] ?? 'Unknown Room';
                      String serviceType = data['serviceType'] ?? 'Unknown Service';
                      String details = data['details'] ?? 'No details provided';
                      String status = data['status'] ?? 'Pending';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Icon(
                            Icons.room_service,
                            color: Colors.blue.shade700,
                            size: 30,
                          ),
                          title: Text(
                            'Room $roomNumber - $serviceType',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text('Details: $details'),
                              const SizedBox(height: 5),
                              _buildStatusBadge(status),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              await _updateStatusDialog(context, request.id, status);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Status Badge Widget
  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status) {
      case 'In Progress':
        badgeColor = Colors.orange;
        break;
      case 'Completed':
        badgeColor = Colors.green;
        break;
      default:
        badgeColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Dialog to update the status of a service request
  Future<void> _updateStatusDialog(BuildContext context, String requestId, String currentStatus) async {
    String newStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Update Service Request Status'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButtonFormField<String>(
                value: currentStatus,
                decoration: InputDecoration(
                  labelText: 'Select Status',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                ],
                onChanged: (value) {
                  setState(() {
                    newStatus = value ?? currentStatus;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newStatus.isNotEmpty) {
                  await _updateStatus(requestId, newStatus);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a valid status.')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Function to update the status in Firestore
  Future<void> _updateStatus(String requestId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('service_requests').doc(requestId).update({
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
       


class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController feedbackController = TextEditingController();
  bool isSubmitting = false;

  // Submit Feedback
  Future<void> _submitFeedback() async {
    if (feedbackController.text.isNotEmpty) {
      setState(() {
        isSubmitting = true;
      });

      try {
        User? user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please log in to submit feedback")),
          );
          return;
        }

        await FirebaseFirestore.instance.collection('feedback').add({
          'feedback': feedbackController.text,
          'username': user.displayName ?? user.email ?? 'Anonymous',
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Feedback Submitted!")),
        );

        feedbackController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      } finally {
        setState(() {
          isSubmitting = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide your feedback")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background
      appBar: AppBar(
        title: const Text("Feedback"),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.indigo.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.feedback, color: Colors.white, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "We value your feedback!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Tell us about your experience. Your suggestions help us improve!",
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Feedback Text Field
              TextField(
                controller: feedbackController,
                maxLines: 5,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Enter your feedback here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.edit, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Submit Feedback",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Animated Illustration
              
            ],
          ),
        ),
      ),
    );
  }
}
