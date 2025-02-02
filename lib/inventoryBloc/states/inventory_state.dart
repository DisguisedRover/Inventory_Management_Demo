import 'package:equatable/equatable.dart';

import '../../models/inventory_item.dart';

abstract class InventoryState extends Equatable {
  @override
  List<Object> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<InventoryItem> items;
  InventoryLoaded(this.items);

  @override
  List<Object> get props => [items];
}

class InventoryError extends InventoryState {
  final String message;
  InventoryError(this.message);

  @override
  List<Object> get props => [message];
}
