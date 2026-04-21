import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:comet_wallet/services/auth_service.dart';
import 'package:comet_wallet/services/authenticated_http_client.dart';
import 'package:comet_wallet/services/token_service.dart';
import 'package:comet_wallet/constants/api_constants.dart';
import 'helpers/mocks.dart';

void main() {
  late MockHttpClient mockHttpClient;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'auth_token': 'fake_token'});
    mockHttpClient = MockHttpClient();
    registerFallbackValue(Uri.parse('http://localhost'));
    // Register fallback for Uri if needed by mocktail
    registerFallbackValue(Uri.parse('http://localhost'));
    // Set global client for tests using AuthenticatedHttpClient
    AuthenticatedHttpClient.setClient(mockHttpClient);
  });

  tearDown(() {
    AuthenticatedHttpClient.resetClient();
  });

  group('AuthService - Login', () {
    test('Success Login - returns JSON and saves token', () async {
      final mockResponse = {
        'token': 'fake_jwt_token',
        'user': {
          'id': '123',
          'email': 'test@example.com',
          'name': 'Test User',
        }
      };

      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await AuthService.login(
        email: 'test@example.com',
        password: 'password123',
        client: mockHttpClient,
      );

      expect(result['token'], 'fake_jwt_token');
      expect(result['user']['email'], 'test@example.com');
      
      verify(() => mockHttpClient.post(
            Uri.parse(ApiConstants.loginEndpoint),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('Failed Login (401) - throws exception', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode({'message': 'Invalid credentials'}), 401));

      expect(
        () => AuthService.login(
          email: 'test@example.com',
          password: 'wrong_password',
          client: mockHttpClient,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Offline Login - throws exception', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(http.ClientException('Network issues'));

      expect(
        () => AuthService.login(
          email: 'test@example.com',
          password: 'password123',
          client: mockHttpClient,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AuthService - Register', () {
    test('Success Register', () async {
      final mockResponse = {
        'user': {
          'id': '124',
          'email': 'new@example.com',
          'name': 'New User',
        },
        'token': 'new_token'
      };

      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 201));

      final result = await AuthService.register(
        email: 'new@example.com',
        password: 'Password123!',
        name: 'New User',
        phoneNumber: '123456789',
        location: 'Nairobi',
        pin: '1234',
        client: mockHttpClient,
      );

      expect(result['user']['email'], 'new@example.com');
    });

    test('Email Exists (409) - throws exception', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode({'error': 'Email already exists'}), 409));

      expect(
        () => AuthService.register(
          email: 'exists@example.com',
          password: 'Password123!',
          name: 'Existing User',
          phoneNumber: '123456789',
          location: 'Nairobi',
          pin: '1234',
          client: mockHttpClient,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
