import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:comet_wallet/services/kyc_service.dart';
import 'package:comet_wallet/services/authenticated_http_client.dart';
import 'package:comet_wallet/services/sumsub_kyc_service.dart';
import 'package:comet_wallet/services/authenticated_http_client.dart';
import 'package:comet_wallet/models/kyc_status_response.dart';
import 'helpers/mocks.dart';

class MockFile extends Mock implements File {}

void main() {
  late MockHttpClient mockHttpClient;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'auth_token': 'fake_token',
      'user_id': '123',
    });
    mockHttpClient = MockHttpClient();
    registerFallbackValue(Uri.parse('http://localhost'));
    // Register fallback for BaseRequest if needed by mocktail
    registerFallbackValue(FakeBaseRequest());
    
    // Set global client for tests using AuthenticatedHttpClient
    AuthenticatedHttpClient.setClient(mockHttpClient);
  });

  tearDown(() {
    AuthenticatedHttpClient.resetClient();
  });

  group('KYCService - uploadImage', () {
    test('Success upload - returns URL', () async {
      final tempDir = Directory.systemTemp.createTempSync('kyc_success_');
      final file = File('${tempDir.path}/test_image.png');
      await file.writeAsBytes([1, 2, 3]);

      when(() => mockHttpClient.send(any())).thenAnswer((_) async {
        final stream = Stream.fromIterable([utf8.encode(jsonEncode({'url': 'https://example.com/image.png'}))]);
        return http.StreamedResponse(stream, 200);
      });

      final result = await KYCService.uploadImage(
        file,
        client: mockHttpClient,
      );

      expect(result, 'https://example.com/image.png');
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('Failed upload - throws exception', () async {
      final tempDir = Directory.systemTemp.createTempSync('kyc_fail_');
      final file = File('${tempDir.path}/test_image.png');
      await file.writeAsBytes([1, 2, 3]);

      when(() => mockHttpClient.send(any())).thenAnswer((_) async {
        return http.StreamedResponse(Stream.fromIterable([utf8.encode('Error')]), 400);
      });

      expect(
        () => KYCService.uploadImage(
          file,
          client: mockHttpClient,
        ),
        throwsException,
      );
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });
  });

  group('SumsubKycService - getKycStatus', () {
    test('Status NOT_STARTED - returns normalized status', () async {
      final mockResponse = {
        'exists': false,
        'kycStatus': 'NOT_STARTED'
      };

      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await SumsubKycService.getKycStatus();

      expect(result.exists, false);
      expect(result.status, 'not_started');
      expect(result.isNotStarted, true);
    });

    test('Status APPROVED - returns detail object (PascalCase keys)', () async {
      final mockResponse = {
        'exists': true,
        'kycStatus': {
          'ID': 92,
          'ExternalUserId': '22',
          'ApplicantId': '69e7447eb983df68808f570b',
          'Status': 'approved',
          'ReviewAnswer': 'GREEN',
          'RejectLabels': '',
          'LevelName': 'FusionFi_Wallet',
          'LastWebhookType': 'applicantReviewed',
        }
      };

      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await SumsubKycService.getKycStatus();

      expect(result.exists, true);
      expect(result.status, 'approved');
      expect(result.isApproved, true);
      expect(result.detail?.reviewAnswer, 'GREEN');
      expect(result.detail?.externalUserId, '22');
      expect(result.detail?.applicantId, '69e7447eb983df68808f570b');
      expect(result.detail?.levelName, 'FusionFi_Wallet');
      expect(result.detail?.lastWebhookType, 'applicantReviewed');
    });

    test('Status APPROVED - backwards compat with camelCase keys', () async {
      final mockResponse = {
        'exists': true,
        'kycStatus': {
          'ID': 1,
          'status': 'approved',
          'reviewAnswer': 'GREEN',
          'externalUserId': 'user_123'
        }
      };

      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await SumsubKycService.getKycStatus();

      expect(result.exists, true);
      expect(result.status, 'approved');
      expect(result.isApproved, true);
      expect(result.detail?.reviewAnswer, 'GREEN');
    });
  });
}

class FakeBaseRequest extends Fake implements http.BaseRequest {}
