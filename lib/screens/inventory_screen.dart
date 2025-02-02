import 'dart:async';

import 'package:demo/screens/order_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../inventoryBloc/bloc/inventory_bloc.dart';
import '../inventoryBloc/events/inventory_event.dart';
import '../inventoryBloc/states/inventory_state.dart';
import '../services/api_service.dart';
import 'inventory_management_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late InventoryBloc _inventoryBloc;

  @override
  void initState() {
    super.initState();
    _inventoryBloc = InventoryBloc(apiService: GetIt.I<ApiService>());
    _inventoryBloc.add(LoadInventory());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _inventoryBloc.close();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _inventoryBloc.add(SearchInventory(query));
    });
  }

  Future<bool?> _confirmDelete(BuildContext context, int itemId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
                _inventoryBloc.add(DeleteInventoryItem(itemId));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _inventoryBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Inventory'),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: _inventoryBloc,
                      child: InventoryManagementScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search inventory...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: BlocBuilder<InventoryBloc, InventoryState>(
                builder: (context, state) {
                  if (state is InventoryLoading) {
                    return Center(child: CircularProgressIndicator());
                  } else if (state is InventoryLoaded) {
                    if (state.items.isEmpty) {
                      return Center(
                        child: Text('No items found'),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        _inventoryBloc.add(LoadInventory());
                      },
                      child: ListView.builder(
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return Dismissible(
                            key: Key(item.id.toString()),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 16),
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) =>
                                _confirmDelete(context, item.id),
                            child: ListTile(
                              title: Text(item.title),
                              subtitle: Text(
                                  'Price: Rs.${item.price} - Quantity: ${item.quantity}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BlocProvider.value(
                                            value: _inventoryBloc,
                                            child: InventoryManagementScreen(
                                              item: item,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  ElevatedButton(
                                    onPressed: item.quantity > 0
                                        ? () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => OrderFormScreen(
                                                  item: item,
                                                ),
                                              ),
                                            )
                                        : null,
                                    child: Text('Order'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else if (state is InventoryError) {
                    return Center(child: Text(state.message));
                  }
                  return Center(child: Text('Something went wrong'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
