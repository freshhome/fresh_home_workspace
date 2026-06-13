import '../../domain/entities/settlement_request.dart';

class SettlementRequestModel extends SettlementRequest {
  const SettlementRequestModel({
    required super.id,
    required super.technicianId,
    required super.amount,
    required super.method,
    required super.proofImageUrl,
    super.adminProofUrl,
    required super.status,
    super.adminNotes,
    super.reviewedBy,
    super.reviewedAt,
    required super.createdAt,
    required super.updatedAt,
    required super.requestType,
  });

  factory SettlementRequestModel.fromJson(Map<String, dynamic> json) {
    return SettlementRequestModel(
      id: json['id'] as String,
      technicianId: json['technician_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String,
      proofImageUrl: json['proof_image_url'] as String? ?? '',
      adminProofUrl: json['admin_proof_url'] as String?,
      status: json['status'] as String,
      adminNotes: json['admin_notes'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      requestType: json['request_type'] as String? ?? 'withdrawal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technician_id': technicianId,
      'amount': amount,
      'method': method,
      'proof_image_url': proofImageUrl,
      'admin_proof_url': adminProofUrl,
      'status': status,
      'admin_notes': adminNotes,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'request_type': requestType,
    };
  }
}
