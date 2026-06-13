import 'package:equatable/equatable.dart';

class SettlementRequest extends Equatable {
  final String id;
  final String technicianId;
  final double amount;
  final String method;
  final String proofImageUrl;
  final String? adminProofUrl;
  final String status;
  final String? adminNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String requestType;

  const SettlementRequest({
    required this.id,
    required this.technicianId,
    required this.amount,
    required this.method,
    required this.proofImageUrl,
    this.adminProofUrl,
    required this.status,
    this.adminNotes,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.requestType,
  });

  @override
  List<Object?> get props => [
        id,
        technicianId,
        amount,
        method,
        proofImageUrl,
        adminProofUrl,
        status,
        adminNotes,
        reviewedBy,
        reviewedAt,
        createdAt,
        updatedAt,
        requestType,
      ];
}
