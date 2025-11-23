import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventario_app/screens/main_screen_host.dart';

void main() async {
  // Asegura que Flutter esté listo
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa Hive
  await Hive.initFlutter();
  
  // Abrimos la caja existente para los productos
  await Hive.openBox<Map>('productos');
  
  // --- LÍNEA CLAVE QUE SOLUCIONA EL ERROR ---
  // Abrimos la nueva caja para guardar las configuraciones del usuario
  await Hive.openBox('settings');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(                                                               
      title: 'Gestor de Inventario',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreenHost(),
    );
  }
}
