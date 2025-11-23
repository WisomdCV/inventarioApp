import 'package:flutter/material.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador de Reportes'),
      ),
      body: const Center(
        child: Text(
          'Aquí irá la interfaz para generar reportes.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
