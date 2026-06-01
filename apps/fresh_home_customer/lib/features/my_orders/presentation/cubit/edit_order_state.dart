part of 'edit_order_cubit.dart';

abstract class EditOrderState extends Equatable {
  const EditOrderState();

  @override
  List<Object> get props => [];
}

class EditOrderInitial extends EditOrderState {}

class EditOrderLoading extends EditOrderState {}

class EditOrderSuccess extends EditOrderState {}

class EditOrderFailure extends EditOrderState {
  final String message;

  const EditOrderFailure({required this.message});

  @override
  List<Object> get props => [message];
}
