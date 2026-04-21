import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:comet_wallet/services/auth_service.dart';
import 'package:comet_wallet/services/wallet_service.dart';
import 'package:comet_wallet/services/kyc_service.dart';
import 'package:comet_wallet/services/token_service.dart';

class MockHttpClient extends Mock implements http.Client {}
class MockAuthService extends Mock implements AuthService {}
class MockWalletService extends Mock implements WalletService {}
class MockKYCService extends Mock implements KYCService {}

// Since AuthService and others have static methods, we might need a wrapper if we want to mock them in BLoCs.
// But for unit testing the services themselves, we will mock the http.Client.
