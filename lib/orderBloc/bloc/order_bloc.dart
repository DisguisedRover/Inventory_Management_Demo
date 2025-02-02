import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/api_service.dart';
import '../events/order_event.dart';
import '../states/order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final ApiService apiService;

  OrderBloc({required this.apiService}) : super(OrderInitial()) {
    on<LoadOrders>((event, emit) async {
      emit(OrderLoading());
      try {
        final orders = await apiService.getOrders();
        emit(OrdersLoaded(orders));
      } catch (e) {
        emit(OrderError(e.toString()));
      }
    });

    on<CreateOrder>((event, emit) async {
      emit(OrderLoading());
      try {
        await apiService.createOrder(
          event.itemId,
          event.name,
          event.contact,
          event.address,
        );
        emit(OrderCreated());
        add(LoadOrders());
      } catch (e) {
        emit(OrderError(e.toString()));
      }
    });
  }
}
