import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:zapp/features/detail/apiclient.dart';

class DeleteRoomPage extends StatefulWidget {
  final String roomId;
  final String roomName;

  const DeleteRoomPage({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<DeleteRoomPage> createState() => _DeleteRoomPageState();
}

class _DeleteRoomPageState extends State<DeleteRoomPage> {
  bool isLoading = false;

  Future<void> _deleteRoom() async {
    setState(() => isLoading = true);

    try {
      await ApiClient.dio.delete(
        '/rooms/${widget.roomId}',
      );

      if (!mounted) return;

      Navigator.pop(context, true); // balik ke homepage dan refresh

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Room deleted successfully"),
        ),
      );
    } on DioError catch (e) {
      debugPrint("STATUS: ${e.response?.statusCode}");
      debugPrint("DATA: ${e.response?.data}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data.toString() ?? "Failed to delete room",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Delete Room",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete \"${widget.roomName}\"?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRoom();
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Color(0xFFFF0000)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Delete Room"),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _confirmDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Delete Room",
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }
}