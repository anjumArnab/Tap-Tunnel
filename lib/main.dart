import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../views/settings.dart';
import '../views/traffic_monitor.dart';
import '../views/webhook_inspector.dart';
import '../views/homepage.dart';

void main() {
  runApp(const TapTunnel());
}

class TapTunnel extends StatelessWidget {
  const TapTunnel({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap Tunnel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(textTheme: GoogleFonts.poppinsTextTheme()),
      routes: {
        '/home': (context) => const Homepage(),
        '/monitor': (context) => const TrafficMonitorScreen(),
        '/webhooks': (context) => const WebhookInspectorPage(),
        '/settings': (context) => const Settings(),
      },
      home: Homepage(),
    );
  }
}
