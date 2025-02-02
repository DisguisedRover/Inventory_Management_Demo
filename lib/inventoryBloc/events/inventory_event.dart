import 'package:equatable/equatable.dart';

class AddInventoryItem extends InventoryEvent {
  final String title;
  final double price;
  final int quantity;

  AddInventoryItem({
    required this.title,
    required this.price,
    required this.quantity,
  });

  @override
  List<Object> get props => [title, price, quantity];
}

class UpdateInventoryItem extends InventoryEvent {
  final int id;
  final String title;
  final double price;
  final int quantity;

  UpdateInventoryItem({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
  });

  @override
  List<Object> get props => [id, title, price, quantity];
}

class SearchInventory extends InventoryEvent {
  final String query;
  SearchInventory(this.query);
}

class DeleteInventoryItem extends InventoryEvent {
  final int id;
  DeleteInventoryItem(this.id);
}

abstract class InventoryEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadInventory extends InventoryEvent {}
