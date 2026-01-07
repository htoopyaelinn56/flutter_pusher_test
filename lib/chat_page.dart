import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.room});

  final String room;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<_ChatItem> _items = <_ChatItem>[];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Pusher setup
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  StreamSubscription<dynamic>? _connectionSub;

  String get _channelName => 'room-${widget.room}';

  @override
  void initState() {
    super.initState();
    unawaited(_connectAndSubscribe());
  }

  Future<void> _connectAndSubscribe() async {
    // IMPORTANT: Replace these with your Pusher Channels credentials.
    // Keeping placeholders so the app still runs without crashing.
    const apiKey = String.fromEnvironment('PUSHER_API_KEY', defaultValue: '');
    const cluster = String.fromEnvironment('PUSHER_CLUSTER', defaultValue: '');

    if (apiKey.isEmpty || cluster.isEmpty) {
      _addSystemMessage(
        'Pusher not configured. Provide --dart-define=PUSHER_API_KEY=... '
        'and --dart-define=PUSHER_CLUSTER=... to enable live updates.',
      );
      return;
    }

    try {
      await _pusher.init(
        apiKey: apiKey,
        cluster: cluster,
        onConnectionStateChange: (currentState, previousState) {
          _addSystemMessage('Connection: $previousState → $currentState');
        },
        onError: (message, code, error) {
          _addSystemMessage('Pusher error ($code): $message');
        },
        onSubscriptionSucceeded: (channelName, data) {
          _addSystemMessage('Subscribed to $channelName');
        },
        onEvent: (event) {
          // You can standardize on event.eventName == 'message' and JSON payload.
          // For now we just append the raw payload/event name.
          _items.add(
            _ChatItem(
              sender: event.channelName,
              text: '[${event.eventName}] ${event.data}',
              timestamp: DateTime.now(),
            ),
          );
          if (mounted) setState(() {});
          _scrollToBottom();
        },
      );

      await _pusher.connect();
      await _pusher.subscribe(channelName: _channelName);
    } catch (e) {
      _addSystemMessage('Failed to init/subscribe Pusher: $e');
    }
  }

  void _addSystemMessage(String text) {
    _items.add(
      _ChatItem(sender: 'system', text: text, timestamp: DateTime.now()),
    );
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    const url = 'http://localhost:3000/send';
    final payload = {
      "message": text,
      "data": "text",
      "event": "send-message",
      "channel": _channelName,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      _messageController.clear();
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _connectionSub?.cancel();

    // Best-effort cleanup.
    unawaited(_pusher.unsubscribe(channelName: _channelName));
    unawaited(_pusher.disconnect());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room: ${widget.room}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _items[index];
                final isMe = item.sender == 'me';

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isMe
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.sender,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(item.text),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatItem {
  _ChatItem({
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  final String sender;
  final String text;
  final DateTime timestamp;
}
