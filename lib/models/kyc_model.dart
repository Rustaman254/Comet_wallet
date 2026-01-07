class KYCData {
  final int userID;
  final String idDocumentFront;
  final String idDocumentBack;
  final String kraDocument;
  final String profilePhoto;
  final String proofOfAddress;

  KYCData({
    required this.userID,
    required this.idDocumentFront,
    required this.idDocumentBack,
    required this.kraDocument,
    required this.profilePhoto,
    required this.proofOfAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'KYC': {
        'userID': userID,
        'ID_document': idDocumentFront,
        'ID_document_back': idDocumentBack,
        'KRA_document': kraDocument,
        'profile_photo': profilePhoto,
        'proof_of_address': proofOfAddress,
      },
    };
  }

  factory KYCData.fromJson(Map<String, dynamic> json) {
    final kycData = json['KYC'] ?? {};
    return KYCData(
      userID: kycData['userID'] ?? 0,
      idDocumentFront: kycData['ID_document'] ?? '',
      idDocumentBack: kycData['ID_document_back'] ?? '',
      kraDocument: kycData['KRA_document'] ?? '',
      profilePhoto: kycData['profile_photo'] ?? '',
      proofOfAddress: kycData['proof_of_address'] ?? '',
    );
  }
}
