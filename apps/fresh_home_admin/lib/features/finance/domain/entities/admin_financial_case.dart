import 'package:equatable/equatable.dart';

class AdminFinancialCase extends Equatable {
  final String id;
  final String bookingId;
  final String reportedBy;
  final String reportedByName;
  final String discrepancyType;
  final double expectedAmount;
  final double collectedAmount;
  final String description;
  final String status;
  final String? resolutionNotes;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminFinancialCase({
    required this.id,
    required this.bookingId,
    required this.reportedBy,
    required this.reportedByName,
    required this.discrepancyType,
    required this.expectedAmount,
    required this.collectedAmount,
    required this.description,
    required this.status,
    this.resolutionNotes,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        bookingId,
        reportedBy,
        reportedByName,
        discrepancyType,
        expectedAmount,
        collectedAmount,
        description,
        status,
        resolutionNotes,
        resolvedBy,
        resolvedAt,
        createdAt,
        updatedAt,
      ];
}
