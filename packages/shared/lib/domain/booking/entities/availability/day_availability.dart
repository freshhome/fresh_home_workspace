import 'package:equatable/equatable.dart';

class DayAvailability extends Equatable {
  final DateTime date;
  final bool isAvailable;

  const DayAvailability({
    required this.date,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [date, isAvailable];
}
