import '../../services/api_service.dart';
import '../events/inventory_event.dart';
import '../states/inventory_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc({required this.apiService}) : super(InventoryInitial()) {
    on<AddInventoryItem>((event, emit) async {
      emit(InventoryLoading());
      try {
        await apiService.addInventoryItem(
          event.title,
          event.price,
          event.quantity,
        );
        final items = await apiService.getInventory();
        emit(InventoryLoaded(items));
      } catch (e) {
        emit(InventoryError(e.toString()));
      }
    });

    on<UpdateInventoryItem>((event, emit) async {
      emit(InventoryLoading());
      try {
        await apiService.updateInventoryItem(
          event.id,
          event.title,
          event.price,
          event.quantity,
        );
        final items = await apiService.getInventory();
        emit(InventoryLoaded(items));
      } catch (e) {
        emit(InventoryError(e.toString()));
      }
    });

    on<LoadInventory>((event, emit) async {
      emit(InventoryLoading());
      try {
        final items = await apiService.getInventory();
        emit(InventoryLoaded(items));
      } catch (e) {
        emit(InventoryError(e.toString()));
      }
    });

    on<DeleteInventoryItem>((event, emit) async {
      emit(InventoryLoading());
      try {
        await apiService.deleteInventoryItem(event.id);
        final items = await apiService.getInventory();
        emit(InventoryLoaded(items));
      } catch (e) {
        emit(InventoryError(e.toString()));
      }
    });

    on<SearchInventory>((event, emit) async {
      try {
        if (state is InventoryLoaded) {
          final currentItems = (state as InventoryLoaded).items;
          final query = event.query.toLowerCase();

          if (query.isEmpty) {
            emit(InventoryLoaded(currentItems));
            return;
          }

          final filteredItems = currentItems
              .where((item) => item.title.toLowerCase().contains(query))
              .toList();

          emit(InventoryLoaded(filteredItems));
        }
      } catch (e) {
        emit(InventoryError(e.toString()));
      }
    });
  }

  final ApiService apiService;
}
