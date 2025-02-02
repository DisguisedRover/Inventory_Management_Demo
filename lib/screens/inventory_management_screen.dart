import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../inventoryBloc/bloc/inventory_bloc.dart';
import '../inventoryBloc/events/inventory_event.dart';
import '../inventoryBloc/states/inventory_state.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';

class InventoryManagementScreen extends StatefulWidget {
  final InventoryItem? item;

  const InventoryManagementScreen({super.key, this.item});

  @override
  _InventoryManagementScreenState createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;

  String _formatPrice(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'[^\d.]'), '');
    int decimalCount = '.'.allMatches(digitsOnly).length;
    if (decimalCount > 1) {
      int firstDecimalIndex = digitsOnly.indexOf('.');
      digitsOnly = digitsOnly.substring(0, firstDecimalIndex + 1) +
          digitsOnly.substring(firstDecimalIndex + 1).replaceAll('.', '');
    }
    return digitsOnly;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _priceController =
        TextEditingController(text: widget.item?.price.toString() ?? '');
    _quantityController =
        TextEditingController(text: widget.item?.quantity.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InventoryBloc(apiService: GetIt.I<ApiService>()),
      child: BlocConsumer<InventoryBloc, InventoryState>(
        listener: (context, state) {
          if (state is InventoryLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Item saved successfully')),
            );
            Navigator.pop(context);
          } else if (state is InventoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(Icons.title),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: 'Price',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(Icons.attach_money),
                                prefixText: 'Rs.',
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              onChanged: (value) {
                                String formatted = _formatPrice(value);
                                if (formatted != value) {
                                  _priceController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                        offset: formatted.length),
                                  );
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a price';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price < 0) {
                                  return 'Please enter a valid price';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _quantityController,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(Icons.inventory),
                                helperText:
                                    '1 unit = 1 ltr for liquid, 1 kg for solid',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a quantity';
                                }
                                final quantity = int.tryParse(value);
                                if (quantity == null || quantity < 0) {
                                  return 'Please enter a valid quantity';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: state is InventoryLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState?.validate() ??
                                          false) {
                                        final price =
                                            double.parse(_priceController.text);
                                        final quantity =
                                            int.parse(_quantityController.text);
                                        if (widget.item == null) {
                                          context.read<InventoryBloc>().add(
                                                AddInventoryItem(
                                                  title: _titleController.text,
                                                  price: price,
                                                  quantity: quantity,
                                                ),
                                              );
                                        } else {
                                          context.read<InventoryBloc>().add(
                                                UpdateInventoryItem(
                                                  id: widget.item!.id,
                                                  title: _titleController.text,
                                                  price: price,
                                                  quantity: quantity,
                                                ),
                                              );
                                        }
                                      }
                                    },
                              child: state is InventoryLoading
                                  ? CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white)
                                  : Text(widget.item == null
                                      ? 'Add Item'
                                      : 'Update Item'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
