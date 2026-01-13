import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/procurement_models.dart';

class ProcurementService {
  static Future<List<Tender>> getTenders() async {
    try {
      final String response = await rootBundle.loadString('lib/data/procurement_data.json');
      final data = json.decode(response) as Map<String, dynamic>;
      final List<dynamic> tendersJson = data['tenders'] as List<dynamic>;
      return tendersJson.map((json) => Tender.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading tenders: $e');
      return [];
    }
  }

  static Future<List<Bid>> getMyBids() async {
    try {
      final String response = await rootBundle.loadString('lib/data/procurement_data.json');
      final data = json.decode(response) as Map<String, dynamic>;
      final List<dynamic> bidsJson = data['myBids'] as List<dynamic>;
      return bidsJson.map((json) => Bid.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading bids: $e');
      return [];
    }
  }

  static Future<List<ProcurementFee>> getProcurementFees() async {
    try {
      final String response = await rootBundle.loadString('lib/data/procurement_data.json');
      final data = json.decode(response) as Map<String, dynamic>;
      final List<dynamic> feesJson = data['procurementFees'] as List<dynamic>;
      return feesJson.map((json) => ProcurementFee.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading fees: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getSupplierProfile() async {
    try {
      final String response = await rootBundle.loadString('lib/data/procurement_data.json');
      final data = json.decode(response) as Map<String, dynamic>;
      return data['supplierProfile'] as Map<String, dynamic>?;
    } catch (e) {
      print('Error loading supplier profile: $e');
      return null;
    }
  }

  static Future<Tender?> getTenderById(String id) async {
    final tenders = await getTenders();
    try {
      return tenders.firstWhere((tender) => tender.id == id);
    } catch (e) {
      return null;
    }
  }
}
