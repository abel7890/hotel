import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditRoomPage extends StatefulWidget {
  const EditRoomPage({Key? key}) : super(key: key);

  @override
  _EditRoomPageState createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  File? _selectedImage;
  Uint8List? _webSelectedImage;
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Rooms"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No rooms found"));
          }

          final rooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final roomId = room.id;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(room['type'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description: ${room['description'] ?? 'Unknown'}'),
                      Text('Price: ₹${room['price'] ?? 'Unknown'}'),
                      // Show image preview
                      room['image'] != null && room['image'].isNotEmpty
                          ? Image.network(room['image'], height: 150, fit: BoxFit.cover)
                          : const Text('No image available'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _editRoomDialog(
                            context,
                            roomId,
                            room['type'] ?? '',
                            room['description'] ?? '',
                            room['price'] ?? '',
                            room['image'] ?? '',
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteRoomDialog(context, roomId);
                        },
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

  // Function to handle image upload to Cloudinary (or your preferred image hosting service)
  Future<String> _uploadImage(File? imageFile, Uint8List? webImageBytes) async {
    const cloudName = "dgrrwwrbk"; // Replace with your Cloudinary cloud name
    const uploadPreset = "hotels"; // Replace with your Cloudinary upload preset
    const cloudinaryUrl = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
      request.fields['upload_preset'] = uploadPreset;

      if (kIsWeb && webImageBytes != null) {
        // For web, use Uint8List (in-memory data)
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            webImageBytes,
            filename: 'room_image.jpg', // Specify filename
          ),
        );
      } else if (!kIsWeb && imageFile != null) {
        // For mobile, use File (local storage)
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );
      } else {
        throw Exception("No image selected.");
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);
        return jsonData['secure_url'];
      } else {
        throw Exception("Failed to upload image to Cloudinary");
      }
    } catch (e) {
      throw Exception("Error uploading image: $e");
    }
  }

  void _editRoomDialog(
    BuildContext context,
    String roomId,
    String currentType,
    String currentDescription,
    String currentPrice,
    String currentImageUrl,
  ) {
    final typeController = TextEditingController(text: currentType);
    final descriptionController = TextEditingController(text: currentDescription);
    final priceController = TextEditingController(text: currentPrice);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Room"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: "Room Type"),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Price"),
                ),
                const SizedBox(height: 8),
                // Show image preview or prompt for new image
                currentImageUrl.isNotEmpty
                    ? Image.network(currentImageUrl, height: 150, fit: BoxFit.cover)
                    : const Text("No image available."),
                const SizedBox(height: 8),
                // Image selection widget
                ElevatedButton.icon(
                  onPressed: () => _pickImage(roomId),
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload New Image'),
                ),
                if (_webSelectedImage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Image.memory(_webSelectedImage!, height: 150, fit: BoxFit.cover),
                  )
                else if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Image.file(_selectedImage!, height: 150, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newType = typeController.text.trim();
                final newDescription = descriptionController.text.trim();
                final newPrice = priceController.text.trim();

                String? updatedImageUrl = currentImageUrl; // Default to the existing image URL

                // If a new image was selected, upload it
                if (_selectedImage != null || _webSelectedImage != null) {
                  updatedImageUrl = await _uploadImage(_selectedImage, _webSelectedImage);
                }

                if (newType.isNotEmpty &&
                    newDescription.isNotEmpty &&
                    newPrice.isNotEmpty &&
                    updatedImageUrl.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(roomId)
                      .update({
                    'type': newType,
                    'description': newDescription,
                    'price': newPrice,
                    'image': updatedImageUrl,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Pick image based on platform
  Future<void> _pickImage(String roomId) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        // For web, convert picked file to Uint8List
        final webImageBytes = await pickedFile.readAsBytes();
        setState(() {
          _webSelectedImage = webImageBytes;
          _selectedImage = null; // Clear mobile image if any
        });
      } else {
        // For mobile, set the picked file
        setState(() {
          _selectedImage = File(pickedFile.path);
          _webSelectedImage = null; // Clear web image if any
        });
      }
    }
  }

  void _deleteRoomDialog(BuildContext context, String roomId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Room"),
          content: const Text("Are you sure you want to delete this room?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(roomId)
                    .delete();
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
