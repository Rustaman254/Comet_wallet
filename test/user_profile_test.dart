import 'package:flutter_test/flutter_test.dart';
import 'package:comet_wallet/models/user_profile.dart';
import 'dart:convert';

void main() {
  group('UserProfile Model Tests', () {
    test('Correctly parses provided backend response', () {
      final jsonResponse = {
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFud2FybWFnYXJhMjU0QGdtYWlsLmNvbSIsImV4cCI6MTc3NjMzMTgwNSwicm9sZUlEIjoyLCJ1c2VySUQiOjh9.TatwnjrWz17kRun2Y_XOZQpRqxwiXCc1Z1I87OwlNG8",
        "user": {
          "RoleID": 2,
          "activation_fee_paid": false,
          "balance_ada": 0,
          "balance_usda": 0,
          "cardano_address": "addr1v8qgacu83nkh7f0zzay3sgz3qk20pcetyamu0t4xn6tfttcfktux9",
          "email": "anwarmagara254@gmail.com",
          "id": 8,
          "is_account_activated": false,
          "kyc_verified": false,
          "location": "kilimani",
          "name": "Anwar magara",
          "password": "\$2a\$10\$mpaFpqU5xGU105DGF2B0iuV7LUZJLA.ii7GMsTQzzU4Ss1B6HBJcC",
          "phone": "0710865696",
          "pin": "\$2a\$10\$7zSRBOTC9o/4DbwdoYYEL.jDI18Gu3GEQV4Jqs66a6YEQ3ZPF2xt2",
          "public_key": "",
          "role": {
            "createdBy": 1,
            "description": "Regular User",
            "id": 2,
            "name": "user",
            "permissions": "",
            "status": "active"
          },
          "status": "active",
          "token": ""
        }
      };

      final userObj = jsonResponse['user'] as Map<String, dynamic>;
      final profile = UserProfile.fromJson(userObj);

      expect(profile.id, 8);
      expect(profile.name, 'Anwar magara');
      expect(profile.email, 'anwarmagara254@gmail.com');
      expect(profile.phone, '0710865696');
      expect(profile.kycVerified, false);
      expect(profile.isAccountActivated, false);
      expect(profile.activationFeePaid, false);
      expect(profile.balanceAda, 0.0);
      expect(profile.balanceUsda, 0.0);
      expect(profile.publicKey, '');
      expect(profile.role?.id, 2);
      expect(profile.role?.name, 'user');
    });

    test('Handles missing wallets key gracefully', () {
      final userObj = {
        "id": 8,
        "name": "Anwar magara",
        // no wallets key
      };
      
      final profile = UserProfile.fromJson(userObj);
      expect(profile.walletBalances, isEmpty);
    });
  });
}
