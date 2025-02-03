import 'package:equatable/equatable.dart';

class CreateOrder extends OrderEvent {
  final int itemId;
  final String name;
  final String contact;
  final String address;

  CreateOrder({
    required this.itemId,
    required this.name,
    required this.contact,
    required this.address,
  });

  @override
  List<Object> get props => [itemId, name, contact, address];
}

class DeleteOrder extends OrderEvent {
  final int id;
  DeleteOrder(this.id);
}

abstract class OrderEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadOrders extends OrderEvent {}
