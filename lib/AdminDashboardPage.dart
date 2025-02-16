import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hotel/AddRoomPage.dart';
import 'package:hotel/editRoomPage.dart';
import 'package:hotel/ManageReservationsPage.dart';
import 'package:hotel/AllocateRoomPage.dart';
import 'FeedbackPage.dart';
import 'ServiceRequestPage.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String userEmail = "";

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }

  Future<void> _getUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 119, 117, 117), // Light background
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome, Admin!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Manage hotel operations efficiently",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              // Feedback Count Card with Gradient
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('feedback').snapshots(),
                builder: (context, snapshot) {
                  int feedbackCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return _buildStatCard("Feedback Received", feedbackCount, const Color.fromARGB(255, 0, 0, 0), Icons.feedback);
                },
              ),

              const SizedBox(height: 30),
              const Text(
                "Admin Features",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _buildFeatureCard(Icons.event, "Manage Reservations", "Approve or reject customer bookings"),
              _buildFeatureCard(Icons.feedback, "Manage Feedback", "View and respond to customer feedback"),
              _buildFeatureCard(Icons.room, "Add Rooms", "Add new rooms "),
              _buildFeatureCard(Icons.room, "Edit Rooms", " update existing ones"),
              _buildFeatureCard(Icons.assignment, "Allocate Rooms", "Assign rooms to customers"),
              _buildFeatureCard(Icons.local_hotel, "Service Requests", "Handle special customer requests"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text("Admin"),
            accountEmail: Text(userEmail),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings, size: 40, color: Color.fromARGB(255, 112, 112, 112)),
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 0, 0, 0), Color.fromARGB(255, 0, 0, 0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          _buildDrawerItem(Icons.event, "Manage Reservations", const ManageReservationsPage()),
          _buildDrawerItem(Icons.feedback, "Manage Feedback", const FeedbackPage()),
          _buildDrawerItem(Icons.room, "Add Room", AddRoom()),
          _buildDrawerItem(Icons.edit, "Edit Rooms", const EditRoomPage()),
          _buildDrawerItem(Icons.assignment, "Allocate Room", const AllocateRoomPage()),
          _buildDrawerItem(Icons.local_hotel, "Manage Service Requests", const ServiceRequestPage()),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("© 2025 Hotel Management", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 0, 0, 0)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color.withOpacity(1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("$count", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color.fromARGB(255, 142, 142, 142),
          child: Icon(icon, color: const Color.fromARGB(255, 0, 0, 0)),
        ),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(description, style: const TextStyle(fontSize: 14, color: Colors.black54)),
      ),
    );
  }
}
