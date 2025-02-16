import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddRoom extends StatefulWidget {
  @override
  _AddRoomState createState() => _AddRoomState();
}

class _AddRoomState extends State<AddRoom> {
  File? _selectedImage;
  Uint8List? _webSelectedImage;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _selectedRoomType;

  /// Cloudinary Upload Function
  Future<String> _uploadToCloudinary(File? imageFile, Uint8List? webImageBytes) async {
    const cloudName = "dgrrwwrbk"; // Replace with your Cloudinary cloud name
    const uploadPreset = "hotels"; // Replace with your Cloudinary upload preset
    const cloudinaryUrl = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
      request.fields['upload_preset'] = uploadPreset;

      if (kIsWeb && webImageBytes != null) {
        // If on web, use Uint8List (in-memory data)
        request.files.add(
          http.MultipartFile.fromBytes(
            'file', 
            webImageBytes, 
            filename: 'room_image.jpg', // Specify filename
          ),
        );
      } else if (!kIsWeb && imageFile != null) {
        // If on mobile, use File (local storage)
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

  Future<void> _pickImage() async {
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

  // Store Room Data in Firestore
  Future<void> _addRoom() async {
    if (_formKey.currentState!.validate() && (_selectedImage != null || _webSelectedImage != null)) {
      try {
        // Determine which type of image to pass
        String? imageUrl;
        
        if (kIsWeb) {
          // If it's web, use Uint8List for image data
          imageUrl = await _uploadToCloudinary(null, _webSelectedImage);
        } else {
          // If it's mobile, use the File object
          imageUrl = await _uploadToCloudinary(_selectedImage, null);
        }

        // Store room details in Firestore
        await FirebaseFirestore.instance.collection('rooms').add({
          'description': _descriptionController.text,
          'image': imageUrl,
          'price': _priceController.text,
          'type': _selectedRoomType,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room added successfully!')),
        );

        // Clear the form fields
        _descriptionController.clear();
        _priceController.clear();
        setState(() {
          _selectedRoomType = null;
          _selectedImage = null;
          _webSelectedImage = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding room: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields and select an image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Room'),
        backgroundColor: const Color.fromARGB(255, 92, 92, 92),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Room Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Room description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Price is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRoomType,
                  decoration: const InputDecoration(
                    labelText: 'Room Type',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedRoomType = value;
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'Deluxe', child: Text('Deluxe')),
                    DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                    DropdownMenuItem(value: 'Economy', child: Text('Economy')),
                  ],
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a room type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Room Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                  ),
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addRoom,
                  child: const Text('Add Room'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
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
