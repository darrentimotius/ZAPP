import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../components/layout.dart';

class AddRoom extends StatefulWidget {
  const AddRoom({super.key});

  @override
  State<AddRoom> createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoom> {
  final TextEditingController _roomNameController = TextEditingController();
  File? _imageFile;

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked =
    await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _saveRoom() {
    final roomName = _roomNameController.text.trim();

    if (roomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Room name cannot be empty")),
      );
      return;
    }

    Navigator.pop(context, {
      "name": roomName,
      "image": _imageFile?.path, // bisa null
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                "Add Room",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ROOM NAME
          const Text("Enter Room Name", style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _roomNameController,
            decoration: InputDecoration(
              hintText: "Room name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // IMAGE (OPTIONAL)
          const Text("Background Image (optional)",
              style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),

          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                image: _imageFile != null
                    ? DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: _imageFile == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 32, color: Colors.grey),
                  SizedBox(height: 6),
                  Text(
                    "Tap to select image",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              )
                  : null,
            ),
          ),
        ],
      ),

      buttonText: "Save",
      onButtonPressed: _saveRoom,
    );
  }
}
