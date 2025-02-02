import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../orderBloc/bloc/order_bloc.dart';
import '../orderBloc/events/order_event.dart';
import '../orderBloc/states/order_state.dart';
import '../services/api_service.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderBloc(
        apiService: GetIt.I<ApiService>(),
      )..add(LoadOrders()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            if (state is OrderLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is OrdersLoaded) {
              return ListView.builder(
                itemCount: state.orders.length,
                itemBuilder: (context, index) {
                  final order = state.orders[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text('Order #${order.id.toString()}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Item: ${order.title}'),
                          Text('Customer: ${order.name}'),
                          Text('Contact: ${order.contact}'),
                          Text('Address: ${order.address}'),
                          Text('Price: Rs.${order.price.toString()}'),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else if (state is OrderError) {
              return Center(child: Text(state.message));
            }
            return const Center(child: Text('Something went wrong'));
          },
        ),
      ),
    );
  }
}
