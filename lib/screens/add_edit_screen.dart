import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_fast_forms/flutter_fast_forms.dart';
import 'package:inventario_app/services/hive_service.dart';
import 'dart:collection'; // Importamos para usar LinkedHashSet y garantizar el orden

class AddEditScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AddEditScreen({super.key, this.product});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final HiveService _hiveService = HiveService();
  
  List<String> _formFields = [];
  Map<String, dynamic> _formValues = {};
  
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _initializeFormFields();
  }

  void _initializeFormFields() {
    final settingsBox = Hive.box('settings');
    final savedColumns = settingsBox.get('visibleColumns') as List<dynamic>?;
    
    // Usamos un LinkedHashSet para mantener el orden de inserción y evitar duplicados.
    final fieldsToShow = LinkedHashSet<String>();

    if (savedColumns != null) {
      // Añadimos las columnas en el orden en que fueron guardadas
      fieldsToShow.addAll(savedColumns.cast<String>());
    } else {
      // Si no hay nada guardado, usamos un orden por defecto
      fieldsToShow.addAll(['Modelo', 'Descripción']);
    }

    if (_isEditing) {
      // Si estamos editando, añadimos los campos del producto que no estén ya en la lista
      fieldsToShow.addAll(widget.product!.keys);
    }

    // Excluimos los campos que no deben ser editables por el usuario
    fieldsToShow.removeWhere((key) => key == 'id' || key == 'fechaRegistro');
    
    // --- CORRECCIÓN CLAVE ---
    // Convertimos el Set a una Lista SIN reordenarla alfabéticamente.
    // Esto respeta el orden que definiste en la tabla.
    _formFields = fieldsToShow.toList();
  }

  void _addNewField() {
    setState(() {
      _formFields.add(''); 
    });
  }

  void _removeField(int index) {
    setState(() {
      _formFields.removeAt(index);
    });
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> productData = {};

      for (int i = 0; i < _formFields.length; i++) {
        final fieldName = _formFields[i];

        if (fieldName.isEmpty) {
          final key = _formValues['new_field_name_$i']?.value as String?;
          final value = _formValues['new_field_value_$i']?.value;
          if (key != null && key.isNotEmpty) {
            productData[key] = value ?? '';
          }
        } else {
          if (_formValues.containsKey(fieldName)) {
            productData[fieldName] = _formValues[fieldName]?.value;
          }
        }
      }

      final fechaValue = _formValues['fechaRegistro']?.value;
      if (fechaValue is DateTime) {
        productData['fechaRegistro'] = fechaValue.toIso8601String();
      } else if (_isEditing) {
        productData['fechaRegistro'] = widget.product!['fechaRegistro'];
      } else {
        productData['fechaRegistro'] = DateTime.now().toIso8601String();
      }
      
      productData.removeWhere((key, value) => value == null);

      if (_isEditing) {
        productData['id'] = widget.product!['id'];
        await _hiveService.updateProducto(widget.product!['id'], productData);
      } else {
        await _hiveService.addProducto(productData);
      }
      
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Añadir Producto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
            tooltip: 'Guardar',
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: FastForm(
            formKey: _formKey,
            onChanged: (values) {
              setState(() {
                _formValues = values;
              });
            },
            children: [
              FastDatePicker(
                name: 'fechaRegistro',
                labelText: 'Fecha de Registro',
                initialValue: _isEditing ? DateTime.tryParse(widget.product!['fechaRegistro'] ?? '') ?? DateTime.now() : DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2040),
              ),
              const SizedBox(height: 16),
              const Divider(),
              
              ..._buildDynamicFormFields(),

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir Campo Personalizado'),
                  onPressed: _addNewField,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFormFields() {
    return List.generate(_formFields.length, (index) {
      final fieldName = _formFields[index];
      
      if (fieldName.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: FastTextField(
                  name: 'new_field_name_$index',
                  labelText: 'Nombre del Nuevo Campo',
                  validator: (value) {
                    final valueField = _formValues['new_field_value_$index']?.value;
                    if (valueField != null && valueField.toString().isNotEmpty) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: FastTextField(
                  name: 'new_field_value_$index',
                  labelText: 'Valor',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => _removeField(index),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: FastTextField(
          name: fieldName,
          labelText: fieldName,
          initialValue: _isEditing ? widget.product![fieldName] : '',
        ),
      );
    });
  }
}
