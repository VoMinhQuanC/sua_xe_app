import 'package:flutter/material.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dịch vụ'),
        backgroundColor: Colors.redAccent,
      ),
      body: const Center(
        child: Text('Màn hình Dịch vụ'),
      ),
    );
  }
}
