import 'package:flutter/foundation.dart';

// Creamos una instancia única (singleton) de nuestro notificador.
// Esto asegura que toda la app hable con el mismo notificador.
final dataChangeNotifier = DataChangeNotifier();

class DataChangeNotifier extends ValueNotifier<int> {
  // Empezamos con un valor de 0.
  DataChangeNotifier() : super(0);

  // Un método simple para notificar un cambio.
  // Incrementamos el valor, lo que activará a todos los que estén escuchando.
  void notify() {
    value++;
  }
}
