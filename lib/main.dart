import 'package:flutter/material.dart';

void main() {
  runApp(const IotGardenApp());
}

class IotGardenApp extends StatelessWidget {
  const IotGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Garden',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje środowisko roślin'),
      ),
      body: const Center(
        child: Text('Tu później zbudujemy widok pokoi 🌿'),
      ),
    );
  }
}