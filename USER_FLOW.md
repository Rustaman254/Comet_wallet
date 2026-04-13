# Comet Wallet - User Flow & Journey Documentation

## Overview
Comet Wallet (Fusionfi) is a Flutter-based mobile wallet application with features for money management, transactions, orders, and various financial services.

---

## 1. App Entry Flow

### 1.1 Splash Screen → Authentication Check
```
[SplashScreen] 
    ↓ (2s delay)
[Check: isFirstTime? & isAuthenticated?]
    ↓
    ├─→ [OnboardingWrapper] → [OnboardingPageView] (first time)
    ├─→ [VerifyPinScreen] (returning user, authenticated)
    └─→ [SignInScreen] (not authenticated)
```

### 1.2 Onboarding Flow (First-time Users)
```
[OnboardingScreen1] - Welcome to Fusionfi
    ↓ (Next button)
[OnboardingScreen2] - Features overview
    ↓ (Next button)
[OnboardingScreen3] - Security features  
    ↓ (Next button)
[OnboardingScreen4] - Get Started
    ↓ (Get Started → Save isFirstTime=false)
[SignInScreen]
```

---

## 2. Authentication Flow

### 2.1 Sign In
```
[SignInScreen]
    ├─→ Email/Phone + Password input
    ├─→ [Forgot Password] → [ForgotPasswordScreen]
    └─→ Submit → [VerifyPinScreen]
```

### 2.2 PIN Verification (Required after auth)
```
[VerifyPinScreen]
    ├─→ 4-digit PIN input
    ├─→ [Forgot PIN] → [ResetPinScreen]
    └─→ Success → [MainWrapper]
```

### 2.3 Forgot Password Flow
```
[ForgotPasswordScreen]
    ├─→ Email input
    └─→ [VerifyTokenScreen] → [ResetPasswordScreen]
```

---

## 3. Main App Structure

### 3.1 Bottom Navigation Tabs
```
[MainWrapper] - Contains 3 main tabs:
    ├─→ Tab 0: [HomeScreen]
    ├─→ Tab 1: [TransactionsScreen]
    ├─→ Tab 2: [OrdersPage]
    └─→ Tab 3: [MoreOptionsScreen] (Modal Bottom Sheet)
```

---

## 4. Screen Flows by Category

### 4.1 HOME TAB - [HomeScreen]
Central dashboard with wallet balance, quick actions, and services.

```
[HomeScreen]
    │
    ├─► QUICK ACTIONS (Top)
    │   ├── [Send Money] → [SendMoneyScreen]
    │   ├── [Receive Money] → [ReceiveMoneyScreen]
    │   ├── [Bank Withdraw] → [BankWithdrawScreen]
    │   └── [Mobile Withdraw] → [MobileWithdrawScreen]
    │
    ├─► SERVICES (Middle grid)
    │   ├── [Buy Airtime] → [BuyAirtimeScreen]
    │   ├── [Buy Tokens] → [BuyTokensScreen]
    │   ├── [Pay Bills] → [PayBillsScreen]
    │   ├── [Swap] → [SwapScreen]
    │   ├── [eCitizen] → [EcitizenServicesScreen]
    │   └── [Government Procurement] → [GovernmentProcurementScreen]
    │
    ├─► PROPERTIES (Bottom)
    │   ├── [My Properties] → [MyPropertiesScreen]
    │   │       └── [PropertyDetailsScreen]
    │   ├── [Property Marketplace] → [PropertyMarketplaceScreen]
    │   │       └── [PropertyDetailsScreen]
    │   └── [Real Estate] → [RealEstateScreen]
    │
    └─► NAVIGATION
        ├── [Scan QR] → [QrScanScreen]
        ├── [My Cards] → [MyCardsScreen]
        │       └── [AddCardScreen]
        └── [Profile] → [ProfileScreen]
                └── [EditProfileScreen]
```

### 4.2 TRANSACTIONS TAB - [TransactionsScreen]
History of all wallet transactions.

```
[TransactionsScreen]
    │
    ├─► Transaction List (by date)
    │   └── [TransactionDetailsScreen]
    │
    ├─► Search/Filter
    │   └── [SearchScreen]
    │
    └─► Pull to refresh
```

### 4.3 ORDERS TAB - [OrdersPage]
Track applications, tenders, and orders.

```
[OrdersPage]
    │
    ├─► Active Orders
    │   └── [TrackApplicationScreen]
    │
    ├─► Government Tenders
    │   ├── [ViewTendersScreen]
    │   │       └── [TenderDetailsScreen]
    │   └── [GovernmentProcurementScreen]
    │           └── [TenderDetailsScreen]
    │
    └─► Applications
            └── [TrackApplicationScreen]
```

### 4.4 MORE OPTIONS - [MoreOptionsScreen]
Additional services and settings (Modal).

```
[MoreOptionsScreen] (Bottom Sheet Modal)
    │
    ├─► Wallet
    │   ├── [WalletTopupScreen]
    │   ├── [WithdrawMoneyScreen]
    │   └── [Add Contact] → [AddContactScreen]
    │
    ├─► Settings
    │   ├── [SettingsScreen]
    │   │       ├── Theme Toggle (Dark/Light)
    │   │       ├── Security settings
    │   │       └── Notifications
    │   └── [ProfileScreen]
    │       └── [EditProfileScreen]
    │
    └─► Support
        └── [WebviewScreen] (Help/Support URL)
```

---

## 5. Detailed Screen Flows

### 5.1 Send Money Flow
```
[SendMoneyScreen]
    ├─► Select contact or enter number
    ├─► Enter amount
    ├─► Select source (Wallet/Card)
    ├─► [Confirm] → [ConfirmPaymentScreen]
    └─► PIN verification → Success/Failure
```

### 5.2 Receive Money Flow
```
[ReceiveMoneyScreen]
    │
    ├─► Show wallet address/phone
    ├─► [Payment QR] → [PaymentQrDisplayScreen]
    └─► [Share] - Share payment link
```

### 5.3 Bank Withdraw Flow
```
[BankWithdrawScreen]
    ├─► Select bank
    ├─► Enter account number (validates bank)
    ├─► Enter amount
    ├─► [Confirm] → [MobilePaymentConfirmScreen]
    └─► PIN verification → Success/Failure
```

### 5.4 Mobile Withdraw Flow
```
[MobileWithdrawScreen]
    ├─► Select mobile money provider
    ├─► Enter phone number
    ├─► Enter amount
    ├─► [Confirm]
    └─► PIN verification → Success/Failure
```

### 5.5 Buy Airtime Flow
```
[BuyAirtimeScreen]
    ├─► Enter phone number
    ├─► Select amount (preset or custom)
    ├─► Select source (Wallet/Card)
    └─► PIN verification → Success
```

### 5.6 Buy Tokens (Electricity) Flow
```
[BuyTokensScreen]
    ├─► Select provider (KPLC, etc.)
    ├─► Enter meter number
    ├─► Select amount
    ├─► Select source
    └─→ PIN verification → Success → Token displayed
```

### 5.7 Pay Bills Flow
```
[PayBillsScreen]
    ├─► Select biller category
    ├─► Select specific biller
    ├─► Enter account/consumer number
    ├─► Enter amount
    └─→ PIN verification → Success
```

### 5.8 Swap (Currency/Token Exchange) Flow
```
[SwapScreen]
    │
    ├─► Select "From" currency/token
    ├─► Select "To" currency/token
    ├─► Enter amount
    ├─► View exchange rate
    └─► [Swap] → PIN verification → Success
```

### 5.9 eCitizen Services Flow
```
[EcitizenServicesScreen]
    │
    ├─► NTSA Services
    │   ├── [EcitizenDetailsScreen]
    │   └── [TrackApplicationScreen]
    │
    ├─► KRA Services
    │   ├── [EcitizenDetailsScreen]
    │   └── [TrackApplicationScreen]
    │
    ├─► Immigration
    │   ├── [EcitizenDetailsScreen]
    │   └── [TrackApplicationScreen]
    │
    └─► Other services
            └── [WebviewScreen]
```

### 5.10 Government Procurement Flow
```
[GovernmentProcurementScreen]
    │
    ├─► View Tenders
    │   └── [TenderDetailsScreen]
    │           └── [Bid Application]
    │
    └─► Track Applications
            └── [TrackApplicationScreen]
```

### 5.11 Properties Flow
```
[MyPropertiesScreen]
    │
    ├─► Property List
    │   └── [PropertyDetailsScreen]
    │
    ├─► Add Property
    │   └── [PropertyDetailsScreen] (edit mode)
    │
    └─► Property Marketplace
            └── [PropertyDetailsScreen]
```

### 5.12 Wallet Top-up Flow
```
[WalletTopupScreen]
    │
    ├─► Bank Card
    │   └── [AddCardScreen] (if no card)
    │
    ├─► Bank Transfer (generate reference)
    │   └── Shows payment reference
    │
    └─► Mobile Money
            └── M-Pesa STK push
```

### 5.13 Withdraw Money Flow
```
[WithdrawMoneyScreen]
    │
    ├─► To Bank
    │   └── [BankWithdrawScreen]
    │
    └─► To Mobile Money
            └── [MobileWithdrawScreen]
```

### 5.14 Profile & Settings Flow
```
[ProfileScreen]
    │
    ├─► Personal Info
    │   └── [EditProfileScreen]
    │
    ├─► My Cards
    │   ├── [MyCardsScreen]
    │   │       └── [AddCardScreen]
    │   └── [AddCardScreen]
    │
    ├─► My Contacts
    │   ├── [ContactListScreen]
    │   │       └── [AddContactScreen]
    │   └── [AddContactScreen]
    │
    └─► Settings
            └── [SettingsScreen]
                    ├── Theme (Dark/Light)
                    ├── Security
                    └── Notifications
```

### 5.15 Cards Management Flow
```
[MyCardsScreen]
    │
    ├─► View all saved cards
    │   └── [CardDetailsScreen]
    │
    └─► Add New Card
            └── [AddCardScreen]
                    ├─→ Card number input
                    ├─→ Expiry/CVV
                    └─→ Cardholder name
```

---

## 6. Technologies & Libraries Used

### 6.1 Flutter Framework
- **Flutter**: 3.x (latest stable)
- **Dart**: 3.x

### 6.2 State Management
- **flutter_bloc** (^8.x) - BLoC pattern for state management
- **bloc** - Core BLoC library

### 6.3 Networking & API
- **dio** - HTTP client for API calls
- **connectivity_plus** - Network connectivity detection

### 6.4 Local Storage
- **shared_preferences** - Key-value storage (theme, onboarding status)
- **sqflite** - SQLite for local database (if used)

### 6.5 Security & Authentication
- **flutter_secure_storage** - Secure storage for tokens
- **local_auth** - Biometric authentication
- **smile_id** - Identity verification/KYC

### 6.6 UI Components
- **flutter_screenutil** - Responsive design
- **flutter_svg** - SVG rendering
- **heroicons** - Icon library
- **cached_network_image** - Image caching
- **shimmer** - Loading placeholders
- **flutter_slidable** - Swipeable list items

### 6.7 Utilities
- **intl** - Internationalization & formatting
- **uuid** - Unique ID generation
- **url_launcher** - External URL handling
- **vibration** - Haptic feedback

### 6.8 Payments Integration (Expected)
- Stripe (cards)
- M-Pesa (mobile money - Kenya)
- Bank APIs

---

## 7. Key Services

| Service | Purpose |
|---------|---------|
| **TokenService** | JWT token management & API auth |
| **SessionService** | Session timeout & background handling |
| **SmileIDInitService** | KYC/identity verification initialization |
| **LoggerService** | App logging & debugging |
| **VibrationService** | Haptic feedback |
| **WalletBloc** | Global wallet state management |

---

## 8. Navigation Routes Summary

```
App Start
    ├── SplashScreen
    │       └── OnboardingWrapper
    │               ├── OnboardingPageView (first time)
    │               │       └── SignInScreen
    │               │
    │               ├── VerifyPinScreen (returning)
    │               │       └── MainWrapper
    │               │
    │               └── SignInScreen (not authenticated)
    │                       └── VerifyPinScreen
    │
    └── MainWrapper (after auth)
            ├── HomeScreen
            │   ├── SendMoneyScreen
            │   ├── ReceiveMoneyScreen
            │   ├── BankWithdrawScreen
            │   ├── MobileWithdrawScreen
            │   ├── BuyAirtimeScreen
            │   ├── BuyTokensScreen
            │   ├── PayBillsScreen
            │   ├── SwapScreen
            │   ├── EcitizenServicesScreen
            │   ├── GovernmentProcurementScreen
            │   ├── MyPropertiesScreen
            │   ├── PropertyMarketplaceScreen
            │   ├── QrScanScreen
            │   ├── MyCardsScreen
            │   └── ProfileScreen
            │
            ├── TransactionsScreen
            │   ├── TransactionDetailsScreen
            │   └── SearchScreen
            │
            ├── OrdersPage
            │   ├── TrackApplicationScreen
            │   ├── ViewTendersScreen
            │   └── TenderDetailsScreen
            │
            └── MoreOptionsScreen (Modal)
                ├── WalletTopupScreen
                ├── WithdrawMoneyScreen
                ├── AddContactScreen
                ├── SettingsScreen
                └── WebviewScreen
```

---

## 9. Session & Security

- **Session Timeout**: Configurable via `SessionService`
- **PIN Verification**: Required on app launch and sensitive operations
- **Biometric Auth**: Optional via `local_auth`
- **KYC**: SmileID integration for identity verification

---

*Document generated for Comet Wallet (Fusionfi) - Flutter Application*