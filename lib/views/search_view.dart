import 'package:flutter/material.dart';
import 'package:inventario_app/services/data_change_notifier.dart';
import 'package:inventario_app/services/hive_service.dart';
import 'package:inventario_app/screens/add_edit_screen.dart';
import 'package:intl/intl.dart';

class SearchView extends StatefulWidget {
  // 1. Añadimos un ScrollController opcional
  final ScrollController? scrollController;

  const SearchView({super.key, this.scrollController});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final HiveService _hiveService = HiveService();
  List<Map<String, dynamic>> _foundProducts = [];
  
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    dataChangeNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    dataChangeNotifier.removeListener(_onDataChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (_searchController.text.isNotEmpty || _selectedDateRange != null) {
      _performSearch();
    }
  }

  DateTime _parseRobustDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime(1970);
    }
  }

  void _performSearch() {
    final allProducts = _hiveService.getProductos();
    List<Map<String, dynamic>> results = [];

    if (_searchController.text.isEmpty && _selectedDateRange == null) {
      results = [];
    } else {
      results = allProducts.where((product) {
        final text = _searchController.text.toLowerCase();
        final matchesText = text.isEmpty || product.values.any((value) => 
          value.toString().toLowerCase().contains(text)
        );

        final productDate = _parseRobustDate(product['fechaRegistro']);
        final matchesDate = _selectedDateRange == null || 
          (productDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
           productDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
        
        if (_selectedDateRange != null && productDate.year == 1970) return false;

        return matchesText && matchesDate;
      }).toList();
    }

    if (mounted) {
      setState(() {
        _foundProducts = results;
      });
    }
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text);
    }

    final textLower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    
    final spans = <TextSpan>[];
    int start = 0;

    while (start < text.length) {
      final startIndex = textLower.indexOf(queryLower, start);
      if (startIndex == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (startIndex > start) {
        spans.add(TextSpan(text: text.substring(start, startIndex)));
      }

      final endIndex = startIndex + query.length;
      spans.add(TextSpan(
        text: text.substring(startIndex, endIndex),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.yellow,
          color: Colors.black,
        ),
      ));
      start = endIndex;
    }

    return RichText(text: TextSpan(style: DefaultTextStyle.of(context).style, children: spans));
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _performSearch();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedDateRange = null;
      _foundProducts = [];
    });
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
        title: const Text('Búsqueda y Filtros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearFilters,
            tooltip: 'Limpiar filtros',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar por texto...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDateRange,
                  tooltip: 'Filtrar por fecha',
                ),
              ],
            ),
            if (_selectedDateRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Fecha: ${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            const SizedBox(height: 20),
            
            Expanded(
              child: _foundProducts.isEmpty
                  ? Center(child: Text(_searchController.text.isEmpty && _selectedDateRange == null ? 'Ingresa un filtro para buscar' : 'No se encontraron resultados'))
                  : ListView.builder(
                      // 2. Usamos el controller aquí
                      controller: widget.scrollController,
                      itemCount: _foundProducts.length,
                      itemBuilder: (context, index) {
                        final product = _foundProducts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: ListTile(
                            title: _buildHighlightedText(
                              product['Modelo']?.toString() ?? 'Sin Modelo', 
                              _searchController.text
                            ),
                            subtitle: _buildHighlightedText(
                              product['Descripción']?.toString() ?? '', 
                              _searchController.text
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.visibility, color: Colors.green), onPressed: () => _showProductDetailsDialog(product)),
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _navigateToAddEditScreen(product: product)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteConfirmationDialog(product['id'])),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
