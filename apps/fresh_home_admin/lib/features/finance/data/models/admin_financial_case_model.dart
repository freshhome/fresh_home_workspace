import '../../domain/entities/admin_financial_case.dart';

class AdminFinancialCaseModel extends AdminFinancialCase {
  const AdminFinancialCaseModel({
    required super.id,
    required super.bookingId,
    required super.reportedBy,
    required super.reportedByName,
    required super.discrepancyType,
    required super.expectedAmount,
    required super.collectedAmount,
    required super.description,
    required super.status,
    super.resolutionNotes,
    super.resolvedBy,
    super.resolvedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdminFinancialCaseModel.fromJson(Map<String, dynamic> json) {
    final profileMap = json['reported_by_profile'] as Map<String, dynamic>?;
    final firstName = profileMap?['first_name'] as String? ?? '';
    final lastName = profileMap?['last_name'] as String? ?? '';
    final techName = '$firstName $lastName'.trim();

    return AdminFinancialCaseModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      reportedBy: json['reported_by'] as String,
      reportedByName: techName.isNotEmpty ? techName : 'فني مجهول',
      discrepancyType: json['discrepancy_type'] as String,
      expectedAmount: (json['expected_amount'] as num).toDouble(),
      collectedAmount: (json['collected_amount'] as num).toDouble(),
      description: json['description'] as String,
      status: json['status'] as String,
      resolutionNotes: json['resolution_notes'] as String?,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'reported_by': reportedBy,
      'discrepancy_type': discrepancyType,
      'expected_amount': expectedAmount,
      'collected_amount': collectedAmount,
      'description': description,
      'status': status,
      'resolution_notes': resolutionNotes,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
