import 'package:flutter/material.dart';
import 'package:flutter_pusher_test/chat_page.dart';

class RoomSelectionPage extends StatefulWidget {
  const RoomSelectionPage({super.key});

  @override
  State<RoomSelectionPage> createState() => _RoomSelectionPageState();
}

class _RoomSelectionPageState extends State<RoomSelectionPage> {
  final TextEditingController _roomController =
      TextEditingController(text: 'general');

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  void _joinRoom() {
    final room = _roomController.text.trim();
    if (room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room name.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(room: room),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Room',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(
                hintText: 'Enter room name',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.join,
              onSubmitted: (_) => _joinRoom(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _joinRoom,
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}
