/// Represents the full response from GET /kyc/sumsub/kyc-status.
///
/// The endpoint returns two shapes:
/// - `{ "exists": false, "kycStatus": "NOT_STARTED" }`
/// - `{ "exists": true,  "kycStatus": { ...KYCStatusDetail... } }`
class KYCStatusResponse {
  final bool exists;
  final String status; // normalised lowercase: not_started, created, pending, approved, rejected, on_hold
  final KYCStatusDetail? detail;

  const KYCStatusResponse({
    required this.exists,
    required this.status,
    this.detail,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending' || status == 'created';
  bool get isRejected => status == 'rejected';
  bool get isOnHold => status == 'on_hold';
  bool get isNotStarted => status == 'not_started';

  factory KYCStatusResponse.fromJson(Map<String, dynamic> json) {
    final exists = json['exists'] as bool? ?? false;
    final rawKycStatus = json['kycStatus'];

    if (!exists || rawKycStatus is String) {
      // Shape: { "exists": false, "kycStatus": "NOT_STARTED" }
      final statusStr = (rawKycStatus as String?)?.toLowerCase() ?? 'not_started';
      return KYCStatusResponse(exists: false, status: statusStr);
    }

    // Shape: { "exists": true, "kycStatus": { ... } }
    final detail = KYCStatusDetail.fromJson(rawKycStatus as Map<String, dynamic>);
    return KYCStatusResponse(
      exists: true,
      status: detail.status,
      detail: detail,
    );
  }

  factory KYCStatusResponse.notStarted() {
    return const KYCStatusResponse(exists: false, status: 'not_started');
  }
}

/// Detailed KYC status object when `exists == true`.
class KYCStatusDetail {
  final int id;
  final String externalUserId;
  final String applicantId;
  final String status; // normalised lowercase
  final String reviewAnswer; // GREEN / RED / empty
  final String rejectLabels;
  final String levelName;
  final String lastWebhookType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const KYCStatusDetail({
    required this.id,
    required this.externalUserId,
    required this.applicantId,
    required this.status,
    required this.reviewAnswer,
    required this.rejectLabels,
    required this.levelName,
    required this.lastWebhookType,
    this.createdAt,
    this.updatedAt,
  });

  factory KYCStatusDetail.fromJson(Map<String, dynamic> json) {
    return KYCStatusDetail(
      id: json['ID'] as int? ?? 0,
      externalUserId: json['externalUserId'] as String? ?? '',
      applicantId: json['applicantId'] as String? ?? '',
      status: (json['status'] as String? ?? '').toLowerCase(),
      reviewAnswer: json['reviewAnswer'] as String? ?? '',
      rejectLabels: json['rejectLabels'] as String? ?? '',
      levelName: json['levelName'] as String? ?? '',
      lastWebhookType: json['lastWebhookType'] as String? ?? '',
      createdAt: json['CreatedAt'] != null ? DateTime.tryParse(json['CreatedAt']) : null,
      updatedAt: json['UpdatedAt'] != null ? DateTime.tryParse(json['UpdatedAt']) : null,
    );
  }
}
