import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../models/inventory_item.dart';
import '../orderBloc/bloc/order_bloc.dart';
import '../orderBloc/events/order_event.dart';
import '../orderBloc/states/order_state.dart';
import '../services/api_service.dart';

class OrderFormScreen extends StatefulWidget {
  final InventoryItem item;
  const OrderFormScreen({super.key, required this.item});

  @override
  _OrderFormScreenState createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderBloc(apiService: GetIt.I<ApiService>()),
      child: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order created successfully')),
            );
            Navigator.pop(context);
          } else if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: Text('Create Order')),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Text(
                    'Item: ${widget.item.title}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('Price: Rs.${widget.item.price}'),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter your name'
                        : null,
                  ),
                  TextFormField(
                    controller: _contactController,
                    decoration: InputDecoration(labelText: 'Contact'),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter your contact'
                        : null,
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: 'Address'),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter your address'
                        : null,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: state is OrderLoading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              context.read<OrderBloc>().add(
                                    CreateOrder(
                                      itemId: widget.item.id,
                                      name: _nameController.text,
                                      contact: _contactController.text,
                                      address: _addressController.text,
                                    ),
                                  );
                            }
                          },
                    child: state is OrderLoading
                        ? CircularProgressIndicator()
                        : Text('Submit Order'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
