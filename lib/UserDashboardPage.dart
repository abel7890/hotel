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
          "Luxury Hotel",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 2,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              icon: const Icon(Icons.book_online, color: Colors.white),
              label: const Text(
                'Reservations',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReservationStatusPage()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              icon: const Icon(Icons.feedback, color: Colors.white),
              label: const Text(
                'Feedback',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeedbackPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Welcome to Luxury Hotel",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Experience unparalleled luxury and comfort with our premium services:",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 16),
                    ServicesList(),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Available Rooms",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Room Type Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedRoomType,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Rooms')),
                          DropdownMenuItem(value: 'Deluxe', child: Text('Deluxe')),
                          DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                          DropdownMenuItem(value: 'Economy', child: Text('Economy')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedRoomType = value!;
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Room List
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(
                            color: Colors.black,
                          ));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "No rooms available",
                              style: TextStyle(color: Colors.black),
                            ),
                          );
                        }

                        final filteredRooms = selectedRoomType == 'All'
                            ? snapshot.data!.docs
                            : snapshot.data!.docs.where((doc) =>
                                (doc.data() as Map<String, dynamic>)['type'] == selectedRoomType).toList();

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServicesList extends StatelessWidget {
  const ServicesList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        ServiceItem(icon: Icons.room_service, text: "24/7 Room Service"),
        ServiceItem(icon: Icons.wifi, text: "High-Speed WiFi"),
        ServiceItem(icon: Icons.local_parking, text: "Complimentary Parking"),
        ServiceItem(icon: Icons.fitness_center, text: "Fitness Center"),
        ServiceItem(icon: Icons.pool, text: "Swimming Pool"),
      ],
    );
  }
}

class ServiceItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const ServiceItem({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
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
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.black12, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image with rounded corners
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Stack(
              children: [
                Image.network(
                  roomData['image'],
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Optional: Add a subtle gradient overlay
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Type
                Text(
                  roomData['type'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Room Description
                Text(
                  roomData['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Room Price
                Text(
                  '₹${roomData['price']} / night',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Book Now Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBookNow,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
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
  final TextEditingController checkInDateController = TextEditingController();

  double totalPrice = 0.0;
  File? _idProofImage;
  Uint8List? _webIdProofImage;
  bool isUploading = false;

  // Theme constants
  final mainTextStyle = const TextStyle(color: Colors.black87);
  final headingStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  final inputDecorationTheme = const InputDecorationTheme(
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black, width: 2),
    ),
    labelStyle: TextStyle(color: Colors.black54),
    floatingLabelStyle: TextStyle(color: Colors.black),
  );

  void _calculateTotalPrice() {
    final duration = int.tryParse(durationController.text) ?? 0;
    final roomPrice = double.tryParse(widget.roomData['price'].toString()) ?? 0.0;

    setState(() {
      totalPrice = duration > 0 ? roomPrice * duration : 0.0;
    });
  }

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

  Future<void> _confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must be logged in to book a room."),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    if (fullNameController.text.isNotEmpty &&
        ageController.text.isNotEmpty &&
        addressController.text.isNotEmpty &&
        durationController.text.isNotEmpty &&
        checkInDateController.text.isNotEmpty) {
      final idProofUrl = await _uploadIdProofImage();

      // Create the booking data
      final bookingData = {
        'userId': user.uid,
        'userName': fullNameController.text,
        'userAge': ageController.text,
        'userAddress': addressController.text,
        'roomType': widget.roomData['type'],
        'description': widget.roomData['description'],
        'price': widget.roomData['price'],
        'duration': durationController.text,
        'totalPrice': totalPrice,
        'checkInDate': checkInDateController.text,  // Verify this is not empty
        'idProofUrl': idProofUrl ?? '',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Print the data to verify
      print('Attempting to store booking data: $bookingData');

      try {
        final docRef = await FirebaseFirestore.instance.collection('bookings').add(bookingData);
        print('Document written with ID: ${docRef.id}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Booking Successful!"),
            backgroundColor: Colors.black87,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error storing booking: $e');  // Detailed error logging
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Booking failed: $e"),
            backgroundColor: Colors.black87,
          ),
        );
      } finally {
        setState(() {
          isUploading = false;
        });
      }
    } else {
      // Print values to see what's missing
      print('Form validation failed:');
      print('Name: ${fullNameController.text}');
      print('Age: ${ageController.text}');
      print('Address: ${addressController.text}');
      print('Duration: ${durationController.text}');
      print('Check-in Date: ${checkInDateController.text}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields, including check-in date"),
          backgroundColor: Colors.black87,
        ),
      );
    }
}

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: inputDecorationTheme,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Room Booking"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Room: ${widget.roomData['type']}",
                  style: headingStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  "Description: ${widget.roomData['description']}",
                  style: mainTextStyle,
                ),
                Text(
                  "Price per night: ₹${widget.roomData['price']}",
                  style: mainTextStyle,
                ),
                const SizedBox(height: 24),
                Text(
                  "Enter Check-in Date (DD/MM/YYYY):",
                  style: mainTextStyle,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: checkInDateController,
                  decoration: const InputDecoration(
                    hintText: "DD/MM/YYYY",
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Enter Duration (in nights):",
                  style: mainTextStyle,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateTotalPrice(),
                  decoration: const InputDecoration(
                    hintText: "Number of nights",
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Total Price: ₹$totalPrice",
                  style: headingStyle,
                ),
                const SizedBox(height: 24),
                Text(
                  "Personal Details",
                  style: headingStyle,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(labelText: "Age"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Address"),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isUploading = true;
                      });
                      await _confirmBooking();
                    },
                    child: isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Confirm Booking"),
                  ),
                ),
              ],
            ),
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
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Reservation Status"),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        ),
        body: const Center(
          child: Text(
            "Please log in to view reservations.",
            style: TextStyle(color: Colors.black87),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservation Status"),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No reservations found.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.black12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.black87, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            data['userName'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.home, "Address: ${data['userAddress'] ?? 'N/A'}"),
                      _buildInfoRow(Icons.room, "Room No: ${data['roomNo'] ?? 'N/A'}"),
                      _buildInfoRow(Icons.hotel, "Room Type: ${data['roomType'] ?? 'N/A'}"),
                      _buildInfoRow(Icons.calendar_today, "Duration: ${data['duration'] ?? 0} days"),
                      _buildInfoRow(Icons.attach_money, "Price per Day: ₹${data['price'] ?? 'N/A'}"),
                      _buildInfoRow(
                        Icons.money,
                        "Total Price: ₹${data['totalPrice'] ?? 'N/A'}",
                        isBold: true,
                      ),
                      const Divider(height: 24, color: Colors.black26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Status:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          _buildStatusChip(data['status']),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
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
                                builder: (context) => ServicesPage(selectedRoomNumber: roomNo),
                              ),
                            );
                          },
                          child: const Text(
                            "Request a Service",
                            style: TextStyle(fontSize: 16),
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

  Widget _buildInfoRow(IconData icon, String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 24),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color chipColor;
    String statusText = status ?? "Pending";

    switch (statusText.toLowerCase()) {
      case "confirmed":
        chipColor = Colors.black87;
        break;
      case "pending":
        chipColor = Colors.black54;
        break;
      case "cancelled":
        chipColor = Colors.black38;
        break;
      default:
        chipColor = Colors.black26;
    }

    return Chip(
      label: Text(
        statusText.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
    );
  }
}
// ServicesPage
       


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
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
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
                    colors: [const Color.fromARGB(255, 0, 0, 0), Colors.indigo.shade700],
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
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
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
