class Tender {
  final String id;
  final String title;
  final String ministry;
  final String category;
  final String budget;
  final String deadline;
  final String status;
  final String description;
  final List<String> requirements;
  final List<String> documents;
  final String publishedDate;
  final String bidBond;
  final String contactPerson;
  final String contactEmail;
  final String contactPhone;

  Tender({
    required this.id,
    required this.title,
    required this.ministry,
    required this.category,
    required this.budget,
    required this.deadline,
    required this.status,
    required this.description,
    required this.requirements,
    required this.documents,
    required this.publishedDate,
    required this.bidBond,
    required this.contactPerson,
    required this.contactEmail,
    required this.contactPhone,
  });

  factory Tender.fromJson(Map<String, dynamic> json) {
    return Tender(
      id: json['id'] as String,
      title: json['title'] as String,
      ministry: json['ministry'] as String,
      category: json['category'] as String,
      budget: json['budget'] as String,
      deadline: json['deadline'] as String,
      status: json['status'] as String,
      description: json['description'] as String,
      requirements: List<String>.from(json['requirements'] as List),
      documents: List<String>.from(json['documents'] as List),
      publishedDate: json['publishedDate'] as String,
      bidBond: json['bidBond'] as String,
      contactPerson: json['contactPerson'] as String,
      contactEmail: json['contactEmail'] as String,
      contactPhone: json['contactPhone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'ministry': ministry,
      'category': category,
      'budget': budget,
      'deadline': deadline,
      'status': status,
      'description': description,
      'requirements': requirements,
      'documents': documents,
      'publishedDate': publishedDate,
      'bidBond': bidBond,
      'contactPerson': contactPerson,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
    };
  }
}

class Bid {
  final String id;
  final String tenderId;
  final String tenderTitle;
  final String submittedDate;
  final String status;
  final String bidAmount;
  final List<String> documents;
  final String lastUpdated;
  final String evaluationStage;
  final String notes;

  Bid({
    required this.id,
    required this.tenderId,
    required this.tenderTitle,
    required this.submittedDate,
    required this.status,
    required this.bidAmount,
    required this.documents,
    required this.lastUpdated,
    required this.evaluationStage,
    required this.notes,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id'] as String,
      tenderId: json['tenderId'] as String,
      tenderTitle: json['tenderTitle'] as String,
      submittedDate: json['submittedDate'] as String,
      status: json['status'] as String,
      bidAmount: json['bidAmount'] as String,
      documents: List<String>.from(json['documents'] as List),
      lastUpdated: json['lastUpdated'] as String,
      evaluationStage: json['evaluationStage'] as String,
      notes: json['notes'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenderId': tenderId,
      'tenderTitle': tenderTitle,
      'submittedDate': submittedDate,
      'status': status,
      'bidAmount': bidAmount,
      'documents': documents,
      'lastUpdated': lastUpdated,
      'evaluationStage': evaluationStage,
      'notes': notes,
    };
  }
}

class ProcurementFee {
  final String id;
  final String type;
  final String description;
  final String amount;
  final String status;
  final String? paidDate;
  final String? receiptNumber;
  final String? dueDate;

  ProcurementFee({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.status,
    this.paidDate,
    this.receiptNumber,
    this.dueDate,
  });

  factory ProcurementFee.fromJson(Map<String, dynamic> json) {
    return ProcurementFee(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      amount: json['amount'] as String,
      status: json['status'] as String,
      paidDate: json['paidDate'] as String?,
      receiptNumber: json['receiptNumber'] as String?,
      dueDate: json['dueDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'amount': amount,
      'status': status,
      if (paidDate != null) 'paidDate': paidDate,
      if (receiptNumber != null) 'receiptNumber': receiptNumber,
      if (dueDate != null) 'dueDate': dueDate,
    };
  }
}
