class RealEstateProperty {
  final String id;
  final String name;
  final String location;
  final String city;
  final String propertyType; // Residential, Commercial, Mixed-Use
  final String description;
  final double totalValue;
  final int totalTokens;
  final int availableTokens;
  final double pricePerToken;
  final double expectedROI; // Annual ROI percentage
  final double rentalYield; // Annual rental yield percentage
  final List<String> images;
  final List<String> amenities;
  final double size; // in square meters
  final String status; // Available, Fully Funded, Coming Soon
  final DateTime listingDate;
  final String legalDocuments;
  final Map<String, dynamic> performanceMetrics;

  RealEstateProperty({
    required this.id,
    required this.name,
    required this.location,
    required this.city,
    required this.propertyType,
    required this.description,
    required this.totalValue,
    required this.totalTokens,
    required this.availableTokens,
    required this.pricePerToken,
    required this.expectedROI,
    required this.rentalYield,
    required this.images,
    required this.amenities,
    required this.size,
    required this.status,
    required this.listingDate,
    required this.legalDocuments,
    required this.performanceMetrics,
  });

  factory RealEstateProperty.fromJson(Map<String, dynamic> json) {
    return RealEstateProperty(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      city: json['city'] as String,
      propertyType: json['propertyType'] as String,
      description: json['description'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      totalTokens: json['totalTokens'] as int,
      availableTokens: json['availableTokens'] as int,
      pricePerToken: (json['pricePerToken'] as num).toDouble(),
      expectedROI: (json['expectedROI'] as num).toDouble(),
      rentalYield: (json['rentalYield'] as num).toDouble(),
      images: List<String>.from(json['images'] as List),
      amenities: List<String>.from(json['amenities'] as List),
      size: (json['size'] as num).toDouble(),
      status: json['status'] as String,
      listingDate: DateTime.parse(json['listingDate'] as String),
      legalDocuments: json['legalDocuments'] as String,
      performanceMetrics: json['performanceMetrics'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'city': city,
      'propertyType': propertyType,
      'description': description,
      'totalValue': totalValue,
      'totalTokens': totalTokens,
      'availableTokens': availableTokens,
      'pricePerToken': pricePerToken,
      'expectedROI': expectedROI,
      'rentalYield': rentalYield,
      'images': images,
      'amenities': amenities,
      'size': size,
      'status': status,
      'listingDate': listingDate.toIso8601String(),
      'legalDocuments': legalDocuments,
      'performanceMetrics': performanceMetrics,
    };
  }

  double get fundingPercentage =>
      ((totalTokens - availableTokens) / totalTokens) * 100;
}

class PropertyToken {
  final String id;
  final String propertyId;
  final String propertyName;
  final int tokenCount;
  final double purchasePrice;
  final DateTime purchaseDate;
  final double currentValue;
  final String status; // Active, Listed for Sale, Sold

  PropertyToken({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.tokenCount,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.currentValue,
    required this.status,
  });

  factory PropertyToken.fromJson(Map<String, dynamic> json) {
    return PropertyToken(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      propertyName: json['propertyName'] as String,
      tokenCount: json['tokenCount'] as int,
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      currentValue: (json['currentValue'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'tokenCount': tokenCount,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'currentValue': currentValue,
      'status': status,
    };
  }

  double get profitLoss => currentValue - purchasePrice;
  double get profitLossPercentage => (profitLoss / purchasePrice) * 100;
}

class PropertyInvestment {
  final String id;
  final String propertyId;
  final String propertyName;
  final String propertyImage;
  final String location;
  final int tokensOwned;
  final int totalTokens;
  final double investmentAmount;
  final double currentValue;
  final double rentalIncomeEarned;
  final DateTime investmentDate;
  final double expectedROI;
  final String propertyType;

  PropertyInvestment({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.propertyImage,
    required this.location,
    required this.tokensOwned,
    required this.totalTokens,
    required this.investmentAmount,
    required this.currentValue,
    required this.rentalIncomeEarned,
    required this.investmentDate,
    required this.expectedROI,
    required this.propertyType,
  });

  factory PropertyInvestment.fromJson(Map<String, dynamic> json) {
    return PropertyInvestment(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      propertyName: json['propertyName'] as String,
      propertyImage: json['propertyImage'] as String,
      location: json['location'] as String,
      tokensOwned: json['tokensOwned'] as int,
      totalTokens: json['totalTokens'] as int,
      investmentAmount: (json['investmentAmount'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      rentalIncomeEarned: (json['rentalIncomeEarned'] as num).toDouble(),
      investmentDate: DateTime.parse(json['investmentDate'] as String),
      expectedROI: (json['expectedROI'] as num).toDouble(),
      propertyType: json['propertyType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'propertyImage': propertyImage,
      'location': location,
      'tokensOwned': tokensOwned,
      'totalTokens': totalTokens,
      'investmentAmount': investmentAmount,
      'currentValue': currentValue,
      'rentalIncomeEarned': rentalIncomeEarned,
      'investmentDate': investmentDate.toIso8601String(),
      'expectedROI': expectedROI,
      'propertyType': propertyType,
    };
  }

  double get ownershipPercentage => (tokensOwned / totalTokens) * 100;
  double get totalReturns => (currentValue - investmentAmount) + rentalIncomeEarned;
  double get totalROI => (totalReturns / investmentAmount) * 100;
}

class PropertyTransaction {
  final String id;
  final String propertyId;
  final String propertyName;
  final String transactionType; // Buy, Sell
  final int tokenCount;
  final double pricePerToken;
  final double totalAmount;
  final DateTime transactionDate;
  final String status; // Completed, Pending, Failed
  final String? transactionHash;

  PropertyTransaction({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.transactionType,
    required this.tokenCount,
    required this.pricePerToken,
    required this.totalAmount,
    required this.transactionDate,
    required this.status,
    this.transactionHash,
  });

  factory PropertyTransaction.fromJson(Map<String, dynamic> json) {
    return PropertyTransaction(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      propertyName: json['propertyName'] as String,
      transactionType: json['transactionType'] as String,
      tokenCount: json['tokenCount'] as int,
      pricePerToken: (json['pricePerToken'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      status: json['status'] as String,
      transactionHash: json['transactionHash'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'transactionType': transactionType,
      'tokenCount': tokenCount,
      'pricePerToken': pricePerToken,
      'totalAmount': totalAmount,
      'transactionDate': transactionDate.toIso8601String(),
      'status': status,
      if (transactionHash != null) 'transactionHash': transactionHash,
    };
  }
}

class MarketplaceListing {
  final String id;
  final String propertyId;
  final String propertyName;
  final String propertyImage;
  final String location;
  final String sellerId;
  final String sellerName;
  final int tokenCount;
  final double pricePerToken;
  final double originalPricePerToken;
  final DateTime listingDate;
  final String status; // Active, Sold, Cancelled

  MarketplaceListing({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.propertyImage,
    required this.location,
    required this.sellerId,
    required this.sellerName,
    required this.tokenCount,
    required this.pricePerToken,
    required this.originalPricePerToken,
    required this.listingDate,
    required this.status,
  });

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    return MarketplaceListing(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      propertyName: json['propertyName'] as String,
      propertyImage: json['propertyImage'] as String,
      location: json['location'] as String,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      tokenCount: json['tokenCount'] as int,
      pricePerToken: (json['pricePerToken'] as num).toDouble(),
      originalPricePerToken: (json['originalPricePerToken'] as num).toDouble(),
      listingDate: DateTime.parse(json['listingDate'] as String),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'propertyImage': propertyImage,
      'location': location,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'tokenCount': tokenCount,
      'pricePerToken': pricePerToken,
      'originalPricePerToken': originalPricePerToken,
      'listingDate': listingDate.toIso8601String(),
      'status': status,
    };
  }

  double get totalValue => tokenCount * pricePerToken;
  double get priceChangePercentage =>
      ((pricePerToken - originalPricePerToken) / originalPricePerToken) * 100;
  bool get isPriceIncreased => pricePerToken > originalPricePerToken;
}
