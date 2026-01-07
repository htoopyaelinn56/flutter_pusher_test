import 'package:flutter/material.dart';
import 'package:flutter_pusher_test/room_selection_page.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

final pusher = PusherChannelsFlutter.getInstance();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const apiKey = String.fromEnvironment('PUSHER_API_KEY', defaultValue: '');
  const cluster = String.fromEnvironment('PUSHER_CLUSTER', defaultValue: '');
  await pusher.init(apiKey: apiKey, cluster: cluster);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: RoomSelectionPage());
  }
}
