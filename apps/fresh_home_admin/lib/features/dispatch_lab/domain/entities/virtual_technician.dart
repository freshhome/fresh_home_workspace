import 'package:equatable/equatable.dart';

class VirtualTechnician extends Equatable {
  final String id;
  final String name;
  final int dailyCapacity;
  final int currentOrders;
  final double rating;
  final bool isActive;
  final int? lastAssignedOrderIndex; // Index of the last assigned booking

  const VirtualTechnician({
    required this.id,
    required this.name,
    required this.dailyCapacity,
    required this.currentOrders,
    required this.rating,
    required this.isActive,
    this.lastAssignedOrderIndex,
  });

  double get utilization => dailyCapacity == 0 ? 0.0 : currentOrders / dailyCapacity;
  int get remainingCapacity => dailyCapacity - currentOrders;

  VirtualTechnician copyWith({
    String? id,
    String? name,
    int? dailyCapacity,
    int? currentOrders,
    double? rating,
    bool? isActive,
    int? lastAssignedOrderIndex,
  }) {
    return VirtualTechnician(
      id: id ?? this.id,
      name: name ?? this.name,
      dailyCapacity: dailyCapacity ?? this.dailyCapacity,
      currentOrders: currentOrders ?? this.currentOrders,
      rating: rating ?? this.rating,
      isActive: isActive ?? this.isActive,
      lastAssignedOrderIndex: lastAssignedOrderIndex ?? this.lastAssignedOrderIndex,
    );
  }

  factory VirtualTechnician.fromJson(Map<String, dynamic> json) {
    return VirtualTechnician(
      id: json['id'] as String,
      name: json['name'] as String,
      dailyCapacity: json['dailyCapacity'] as int,
      currentOrders: json['currentOrders'] as int,
      rating: (json['rating'] as num).toDouble(),
      isActive: json['isActive'] as bool,
      lastAssignedOrderIndex: json['lastAssignedOrderIndex'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dailyCapacity': dailyCapacity,
      'currentOrders': currentOrders,
      'rating': rating,
      'isActive': isActive,
      'lastAssignedOrderIndex': lastAssignedOrderIndex,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        dailyCapacity,
        currentOrders,
        rating,
        isActive,
        lastAssignedOrderIndex,
      ];
}
