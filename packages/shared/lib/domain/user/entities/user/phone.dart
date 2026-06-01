import 'package:equatable/equatable.dart';

class Phone extends Equatable {
  final String? id;
  final String userId;
  final String phoneNumber;
  final bool isPrimary;
  final bool isVerified;
  final DateTime createdAt;

  const Phone({
    this.id,
    required this.userId,
    required this.phoneNumber,
    required this.isPrimary,
    required this.isVerified,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, userId, phoneNumber, isPrimary, isVerified, createdAt];

  Phone copyWith({
    String? id,
    String? userId,
    String? phoneNumber,
    bool? isPrimary,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return Phone(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPrimary: isPrimary ?? this.isPrimary,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
