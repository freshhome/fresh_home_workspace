class AuditLogRemoteModel {
  final String id;
  final String bookingId;
  final String changedBy;
  final String? oldStatus;
  final String? newStatus;
  final String? technicianId;
  final String? notes;
  final DateTime createdAt;

  const AuditLogRemoteModel({
    required this.id,
    required this.bookingId,
    required this.changedBy,
    this.oldStatus,
    this.newStatus,
    this.technicianId,
    this.notes,
    required this.createdAt,
  });

  factory AuditLogRemoteModel.fromJson(Map<String, dynamic> json) {
    return AuditLogRemoteModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      changedBy: json['changed_by'] as String,
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String?,
      technicianId: json['technician_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'changed_by': changedBy,
      'old_status': oldStatus,
      'new_status': newStatus,
      'technician_id': technicianId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
