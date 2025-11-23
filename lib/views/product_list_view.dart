import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:inventario_app/services/data_change_notifier.dart';
import 'package:inventario_app/services/hive_service.dart';
import 'package:inventario_app/screens/add_edit_screen.dart';
import 'package:intl/intl.dart';

class ProductListView extends StatefulWidget {
  final ScrollController? scrollController;
  const ProductListView({super.key, this.scrollController});

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  final HiveService _hiveService = HiveService();
  List<Map<String, dynamic>> _products = [];
  
  List<String> _visibleColumns = ['Modelo', 'Descripción', 'fechaRegistro'];
  List<String> _allAvailableColumns = [];
  List<String> _columnOrder = []; // Guarda el orden completo de todas las columnas
  
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadVisibleColumns();
    _loadProducts();
    dataChangeNotifier.addListener(_loadProducts);
  }

  @override
  void dispose() {
    dataChangeNotifier.removeListener(_loadProducts);
    super.dispose();
  }

  void _loadVisibleColumns() {
    final settingsBox = Hive.box('settings');
    final savedColumns = settingsBox.get('visibleColumns') as List<dynamic>?;
    final savedColumnOrder = settingsBox.get('columnOrder') as List<dynamic>?;
    
    if (savedColumns != null) {
      final loadedVisible = savedColumns.cast<String>().toList();
      _visibleColumns = loadedVisible;
    }
    
    if (savedColumnOrder != null) {
      _columnOrder = savedColumnOrder.cast<String>().toList();
    } else {
      // Si no hay orden guardado, establecer un orden inicial estándar
      _columnOrder = ['Modelo', 'Descripción', 'fechaRegistro', 'Precio'];
      settingsBox.put('columnOrder', _columnOrder);
    }

    // Alinear el orden de visibles con el orden global
    if (_visibleColumns.isNotEmpty && _columnOrder.isNotEmpty) {
      _visibleColumns = _columnOrder.where((k) => _visibleColumns.contains(k)).toList();
    }
  }

  void _loadProducts() {
    if (mounted) {
      setState(() {
        _products = _hiveService.getProductos(); 
        _updateAvailableColumns();
        _sortProducts();
      });
    }
  }

  void _updateAvailableColumns() {
    final allKeys = <String>{};
    for (var product in _products) {
      allKeys.addAll(product.keys);
    }
    allKeys.removeWhere((key) => key == 'id');
    
    // Si no hay orden guardado, usar el orden actual como base
    if (_columnOrder.isEmpty) {
      _columnOrder = allKeys.toList();
      final settingsBox = Hive.box('settings');
      settingsBox.put('columnOrder', _columnOrder);
    }
    
    // Agregar nuevas columnas que no estén en el orden guardado
    final newColumns = allKeys.where((key) => !_columnOrder.contains(key)).toList();
    if (newColumns.isNotEmpty) {
      _columnOrder.addAll(newColumns);
      final settingsBox = Hive.box('settings');
      settingsBox.put('columnOrder', _columnOrder);
    }
    
    // Actualizar la lista disponible manteniendo el orden
    _allAvailableColumns = List.from(_columnOrder);
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _loadProducts();
  }

  DateTime _parseRobustDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime(1970); 
    }
  }

  void _sortProducts() {
    if (_sortColumnIndex >= _visibleColumns.length) return;
    final sortKey = _visibleColumns[_sortColumnIndex];

    _products.sort((a, b) {
      dynamic aValue = a[sortKey];
      dynamic bValue = b[sortKey];

      if (aValue == null || bValue == null) return 0;

      if (sortKey == 'fechaRegistro') {
        aValue = _parseRobustDate(aValue.toString());
        bValue = _parseRobustDate(bValue.toString());
      } else {
        aValue = aValue.toString().toLowerCase();
        bValue = bValue.toString().toLowerCase();
      }
      
      final comparison = aValue.compareTo(bValue);
      return _isAscending ? comparison : -comparison;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      _sortProducts();
    });
  }
  
  Future<void> _showColumnSelectionDialog() async {
    List<String> tempVisibleColumns = List.from(_visibleColumns);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Configurar Columnas'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selecciona y reordena las columnas:'),
                    const Divider(),
                    Expanded(
                      child: ReorderableListView(
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            elevation: 4.0,
                            child: child,
                          );
                        },
                        children: _allAvailableColumns.map((key) {
                          return CheckboxListTile(
                            key: ValueKey(key),
                            title: Text(key),
                            value: tempVisibleColumns.contains(key),
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  tempVisibleColumns.add(key);
                                } else {
                                  if (tempVisibleColumns.length > 1) {
                                    tempVisibleColumns.remove(key);
                                  }
                                }
                              });
                            },
                          );
                        }).toList(),
                        onReorder: (int oldIndex, int newIndex) {
                          setDialogState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final String item = _allAvailableColumns.removeAt(oldIndex);
                            _allAvailableColumns.insert(newIndex, item);

                            // Actualizar el orden global
                            setState(() {
                              _columnOrder = List.from(_allAvailableColumns);
                            });
                            
                            // Guardar el nuevo orden
                            final settingsBox = Hive.box('settings');
                            settingsBox.put('columnOrder', _columnOrder);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Aplicar'),
                  onPressed: () {
                    final settingsBox = Hive.box('settings');
                    final orderedVisible = _columnOrder.where((k) => tempVisibleColumns.contains(k)).toList();
                    settingsBox.put('visibleColumns', orderedVisible);
                    settingsBox.put('columnOrder', _columnOrder);
                    
                    if (_sortColumnIndex >= orderedVisible.length) {
                      _sortColumnIndex = 0;
                    }

                    setState(() {
                      _visibleColumns = orderedVisible;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showProductDetailsDialog(Map<String, dynamic> product) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final detailItems = <Widget>[];
        product.forEach((key, value) {
          if (key != 'id') {
            String displayValue;
            if (key == 'fechaRegistro') {
              final date = _parseRobustDate(value.toString());
              displayValue = date.year == 1970 
                  ? 'Fecha Inválida' 
                  : DateFormat('dd/MM/yyyy HH:mm').format(date);
            } else {
              displayValue = value.toString();
            }

            detailItems.add(
              ListTile(
                title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(displayValue),
              ),
            );
          }
        });
        return AlertDialog(
          title: const Text('Detalles del Producto'),
          content: SingleChildScrollView(child: ListBody(children: detailItems)),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(String id) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que quieres eliminar este producto?'),
          actions: <Widget>[
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () {
                _hiveService.deleteProducto(id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddEditScreen({Map<String, dynamic>? product}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario Completo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_column),
            onPressed: _showColumnSelectionDialog,
            tooltip: 'Configurar Columnas',
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _products.isEmpty
            ? Stack(
                children: <Widget>[
                  ListView(controller: widget.scrollController),
                  const Center(child: Text('No hay productos registrados.\nDesliza hacia abajo para recargar.', textAlign: TextAlign.center)),
                ],
              )
            // --- ESTRUCTURA DE SCROLL CORREGIDA ---
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    // 1. Este es el controlador principal VERTICAL. Se lo pasamos a la librería.
                    controller: widget.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SingleChildScrollView(
                      // 2. Este es el scroll HORIZONTAL, no tiene controlador para no interferir.
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        // 3. Aseguramos que la tabla tenga al menos el ancho de la pantalla.
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _isAscending,
                          columns: [
                            ..._visibleColumns.map((columnName) {
                              return DataColumn(
                                label: Text(columnName),
                                onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
                              );
                            }).toList(),
                            const DataColumn(label: Text('Acciones')),
                          ],
                          rows: _products.map((product) {
                            return DataRow(cells: [
                              ..._visibleColumns.map((columnName) {
                                dynamic value = product[columnName];
                                String displayValue;
                                if (columnName == 'fechaRegistro') {
                                  final date = _parseRobustDate(value.toString());
                                  displayValue = date.year == 1970 ? 'N/A' : DateFormat('dd/MM/yyyy').format(date);
                                } else {
                                  displayValue = value?.toString() ?? 'N/A';
                                }
                                return DataCell(Text(displayValue));
                              }).toList(),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.green),
                                    onPressed: () => _showProductDetailsDialog(product),
                                    tooltip: 'Ver Detalles',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _navigateToAddEditScreen(product: product),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _showDeleteConfirmationDialog(product['id']),
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
