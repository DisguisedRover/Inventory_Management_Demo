// ignore_for_file: public_member_api_docs, sort_constructors_first
// checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../screens/shop_screen.dart';

//import '../orderBloc/bloc/order_bloc.dart';
import '../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final VoidCallback onSuccess;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.onSuccess,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get _orderTotal => widget.cartItems.fold(
        0,
        (sum, item) => sum + (item.item.price * item.quantity),
      );

  Future<void> _processOrder(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // Process each cart item
      for (final cartItem in widget.cartItems) {
        // Create order for each quantity of the item
        for (var i = 0; i < cartItem.quantity; i++) {
          try {
            await GetIt.I<ApiService>().createOrder(
              cartItem.item.id,
              _nameController.text,
              _contactController.text,
              _addressController.text,
            );
          } catch (e) {
            // Show detailed error and stop processing
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error processing order for ${cartItem.item.title}: ${e.toString()}',
                ),
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Dismiss',
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
            setState(() => _isProcessing = false);
            return;
          }
        }
      }

      // If we get here, all orders were successful
      widget.onSuccess();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Orders processed successfully!')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        // Column Headers
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Item',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                'Qty',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                'Price',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        // Items
                        ...widget.cartItems.map((cartItem) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(cartItem.item.title),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      'x${cartItem.quantity}',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'Rs.${(cartItem.item.price * cartItem.quantity).toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rs.${_orderTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Delivery Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
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
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Please enter your name'
                              : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _contactController,
                          decoration: InputDecoration(
                            labelText: 'Contact Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Please enter your contact'
                              : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Delivery Address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          maxLines: 3,
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Please enter your address'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      _isProcessing ? null : () => _processOrder(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue.shade700,
                  ),
                  child: _isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Processing Order...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_checkout),
                            SizedBox(width: 8),
                            Text(
                              'Place Order (Rs.${_orderTotal.toStringAsFixed(2)})',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                ),
                if (_isProcessing) ...[
                  SizedBox(height: 16),
                  Text(
                    'Please wait while we process your order...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
