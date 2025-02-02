// shop_screen.dart

import 'package:demo/screens/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../models/inventory_item.dart';
import '../inventoryBloc/bloc/inventory_bloc.dart';
import '../inventoryBloc/events/inventory_event.dart';
import '../inventoryBloc/states/inventory_state.dart';
import '../services/api_service.dart';

class CartItem {
  final InventoryItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 0});

  double get total => item.price * quantity;
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final Map<int, CartItem> _cart = {};
  late InventoryBloc _inventoryBloc;

  @override
  void initState() {
    super.initState();
    _inventoryBloc = InventoryBloc(apiService: GetIt.I<ApiService>());
    _inventoryBloc.add(LoadInventory());
  }

  @override
  void dispose() {
    _inventoryBloc.close();
    super.dispose();
  }

  void _updateCart(InventoryItem item, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(item.id);
      } else {
        _cart[item.id] = CartItem(item: item, quantity: quantity);
      }
    });
  }

  double get _cartTotal =>
      _cart.values.fold(0, (sum, item) => sum + item.total);

  void _proceedToCheckout() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add items to cart first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: _cart.values.toList(),
          onSuccess: () {
            setState(() {
              _cart.clear();
            });
            _inventoryBloc.add(LoadInventory());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _inventoryBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Shop'),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart),
                  onPressed: _proceedToCheckout,
                ),
                if (_cart.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_cart.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            if (_cart.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cart Total: Rs.${_cartTotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ElevatedButton(
                      onPressed: _proceedToCheckout,
                      child: Text('Checkout'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: BlocBuilder<InventoryBloc, InventoryState>(
                builder: (context, state) {
                  if (state is InventoryLoading) {
                    return Center(child: CircularProgressIndicator());
                  } else if (state is InventoryLoaded) {
                    if (state.items.isEmpty) {
                      return Center(child: Text('No items available'));
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        _inventoryBloc.add(LoadInventory());
                      },
                      child: ListView.builder(
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          final cartItem = _cart[item.id];
                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Rs.${item.price.toStringAsFixed(2)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall!
                                              .copyWith(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                        ),
                                        Text(
                                          'In Stock: ${item.quantity}',
                                          style: TextStyle(
                                            color: item.quantity > 0
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (item.quantity > 0) ...[
                                    IconButton(
                                      icon: Icon(Icons.remove),
                                      onPressed: cartItem?.quantity == null ||
                                              cartItem!.quantity <= 0
                                          ? null
                                          : () => _updateCart(
                                              item, (cartItem.quantity - 1)),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '${cartItem?.quantity ?? 0}',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add),
                                      onPressed: cartItem?.quantity ==
                                              item.quantity
                                          ? null
                                          : () => _updateCart(item,
                                              (cartItem?.quantity ?? 0) + 1),
                                    ),
                                  ] else
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'Out of Stock',
                                        style: TextStyle(color: Colors.red),
                                      ),
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
