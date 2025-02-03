import 'dart:async';
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

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late InventoryBloc _inventoryBloc;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _inventoryBloc = InventoryBloc(apiService: GetIt.I<ApiService>());
    _inventoryBloc.add(LoadInventory());

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _inventoryBloc.close();
    _animationController.dispose();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text(
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
          title: const Text('Inventory'),
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
          actions: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          BlocProvider.value(
                        value: _inventoryBloc,
                        child: const InventoryManagementScreen(),
                      ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search inventory...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          BorderSide(color: Colors.blue.shade400, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<InventoryBloc, InventoryState>(
                builder: (context, state) {
                  if (state is InventoryLoading) {
                    return Center(
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: const CircularProgressIndicator(),
                          );
                        },
                      ),
                    );
                  } else if (state is InventoryLoaded) {
                    if (state.items.isEmpty) {
                      return const Center(
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
                          return TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration:
                                Duration(milliseconds: 300 + (index * 50)),
                            builder: (context, double value, child) {
                              return Transform.translate(
                                offset: Offset(0, 50 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Dismissible(
                              key: Key(item.id.toString()),
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) =>
                                  _confirmDelete(context, item.id),
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Price: Rs.${item.price} - Quantity: ${item.quantity}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        color: Colors.blue.shade400,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation,
                                                      secondaryAnimation) =>
                                                  BlocProvider.value(
                                                value: _inventoryBloc,
                                                child:
                                                    InventoryManagementScreen(
                                                  item: item,
                                                ),
                                              ),
                                              transitionsBuilder: (context,
                                                  animation,
                                                  secondaryAnimation,
                                                  child) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else if (state is InventoryError) {
                    return Center(child: Text(state.message));
                  }
                  return const Center(child: Text('Something went wrong'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
