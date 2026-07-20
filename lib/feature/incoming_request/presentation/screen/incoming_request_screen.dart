import 'package:flutter/material.dart';

class IncomingRequestScreen extends StatefulWidget {
  const IncomingRequestScreen({super.key});

  @override
  State<IncomingRequestScreen> createState() => _IncomingRequestScreenState();
}

class _IncomingRequestScreenState extends State<IncomingRequestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text("Incoming Request Page..")));
  }
}
