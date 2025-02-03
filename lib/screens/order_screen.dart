import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../orderBloc/bloc/order_bloc.dart';
import '../orderBloc/events/order_event.dart';
import '../orderBloc/states/order_state.dart';
import '../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late OrderBloc _orderBloc;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _orderBloc = OrderBloc(apiService: GetIt.I<ApiService>());
    _orderBloc.add(LoadOrders());

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
    _orderBloc.close();
    _animationController.dispose();
    super.dispose();
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
          content: const Text('Are you sure you want to delete this order?'),
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
                _orderBloc.add(DeleteOrder(itemId));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderBloc(
        apiService: GetIt.I<ApiService>(),
      )..add(LoadOrders()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
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
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: BlocBuilder<OrderBloc, OrderState>(
            builder: (context, state) {
              if (state is OrderLoading) {
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
              } else if (state is OrdersLoaded) {
                if (state.orders.isEmpty) {
                  return Center(
                    child: TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value,
                          child: const Text('No orders found'),
                        );
                      },
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<OrderBloc>().add(LoadOrders());
                  },
                  child: ListView.builder(
                    itemCount: state.orders.length,
                    itemBuilder: (context, index) {
                      final order = state.orders[index];
                      return TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + (index * 50)),
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
                          key: Key(order.id.toString()),
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
                              _confirmDelete(context, order.id),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                'Order #${order.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Item: ${order.title}'),
                                  Text('Customer: ${order.name}'),
                                  Text('Contact: ${order.contact}'),
                                  Text('Address: ${order.address}'),
                                  Text(
                                    'Price: Rs.${order.price}',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
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
              } else if (state is OrderError) {
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
      ),
    );
  }
}
