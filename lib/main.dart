import '../screens/shop_screen.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../screens/inventory_screen.dart';
import 'screens/order_screen.dart';

void main() {
  GetIt.I.registerSingleton<ApiService>(ApiService());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventory & Orders',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Inventory & Orders'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Inventory'),
              Tab(text: 'Orders'),
              Tab(
                text: 'Shop Now',
              )
            ],
          ),
        ),
        body: TabBarView(
          children: [
            InventoryScreen(),
            OrdersScreen(),
            ShopScreen(),
          ],
        ),
      ),
    );
  }
}
