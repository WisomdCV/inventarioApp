import 'package:hive/hive.dart';
import 'package:inventario_app/services/data_change_notifier.dart'; // 1. Importamos el notificador
import 'package:uuid/uuid.dart';

class HiveService {
  final Box<Map> _productosBox = Hive.box<Map>('productos');
  final _uuid = const Uuid();

  List<Map<String, dynamic>> getProductos() {
    final data = _productosBox.values.toList();
    data.sort((a, b) {
      // La ordenación inicial no es tan crítica aquí, pero la mantenemos
      final dateA = DateTime.tryParse(a['fechaRegistro'] ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['fechaRegistro'] ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> addProducto(Map<String, dynamic> producto) async {
    final String id = _uuid.v4();
    final nuevoProducto = Map<String, dynamic>.from(producto);
    nuevoProducto['id'] = id;
    // La fecha ya viene formateada desde el formulario
    await _productosBox.put(id, nuevoProducto);
    
    // 2. Notificamos que los datos han cambiado
    dataChangeNotifier.notify();
  }

  Future<void> updateProducto(String id, Map<String, dynamic> producto) async {
    final productoActualizado = Map<String, dynamic>.from(producto);
    productoActualizado['id'] = id;
    await _productosBox.put(id, productoActualizado);

    // 2. Notificamos que los datos han cambiado
    dataChangeNotifier.notify();
  }

  Future<void> deleteProducto(String id) async {
    await _productosBox.delete(id);

    // 2. Notificamos que los datos han cambiado
    dataChangeNotifier.notify();
  }
}
