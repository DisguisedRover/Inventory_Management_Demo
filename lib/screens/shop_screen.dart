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

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  final Map<int, CartItem> _cart = {};
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
    _inventoryBloc.close();
    _animationController.dispose();
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
        const SnackBar(content: Text('Please add items to cart first')),
      );
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CheckoutScreen(
          cartItems: _cart.values.toList(),
          onSuccess: () {
            setState(() {
              _cart.clear();
            });
            _inventoryBloc.add(LoadInventory());
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _inventoryBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shop'),
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
                icon: Hero(
                  tag: 'cart',
                  child: const Icon(Icons.shopping_cart),
                ),
                onPressed: _proceedToCheckout,
              ),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              if (_cart.isNotEmpty)
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, -20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cart Total: Rs.${_cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _proceedToCheckout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Checkout'),
                        ),
                      ],
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
                        return Center(
                          child: TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: const Text('No items available'),
                              );
                            },
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          final cartItem = _cart[item.id];
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
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rs.${item.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.bold,
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
                                        icon: const Icon(Icons.remove),
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
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: cartItem?.quantity ==
                                                item.quantity
                                            ? null
                                            : () => _updateCart(item,
                                                (cartItem?.quantity ?? 0) + 1),
                                      ),
                                    ] else
                                      const Padding(
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
                            ),
                          );
                        },
                      );
                    } else if (state is InventoryError) {
                      return Center(
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: Text(state.message),
                            );
                          },
                        ),
                      );
                    }
                    return const Center(child: Text('Something went wrong'));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
