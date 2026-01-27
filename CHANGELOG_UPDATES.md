# Comet Wallet - UI & State Management Updates

## Summary of Changes

### 1. **State Management - BLoC Pattern**
   - **Added Dependencies**: `flutter_bloc: ^8.1.5` and `equatable: ^2.0.5` to `pubspec.yaml`
   - **Created BLoC Structure**:
     - `lib/bloc/wallet_event.dart` - Defines wallet events (FetchWalletData, TopUpWallet, SendMoney, UpdateBalance, AddTransaction, RefreshWallet)
     - `lib/bloc/wallet_state.dart` - Defines wallet states (WalletInitial, WalletLoading, WalletLoaded, WalletError, WalletBalanceUpdated)
     - `lib/bloc/wallet_bloc.dart` - BLoC implementation that handles state transitions and updates the app in real-time when top-ups or money transfers occur

### 2. **Font Changes**
   - Changed default font family from 'Satoshi' to 'Outfit' across the entire app
   - Updated `lib/main.dart` theme configurations for both light and dark modes
   - All TextStyle instances now use 'Outfit' font family

### 3. **UI/UX Improvements on Home Screen**

   #### Balance Card Updates:
   - **Eye Icon Repositioned**: Moved from Total Balance label to top-left corner for revealing/hiding balance
   - **Removed Elements**:
     - ✓ Commented out search icon in header
     - ✓ Commented out date display in balance card
     - ✓ Commented out currency badge in balance card top-right
     - ✓ Removed information at the bottom left of balance card (Date & Change indicator)
   - **Title Enhancement**: "Total Balance" title is now larger (18sp → 18sp styling with better prominence)
   - **Balance Amount**: Increased font size for better visibility (52sp)

### 4. **Bottom Navigation - Floating Design**
   - Updated `lib/widgets/custom_bottom_nav.dart` to use `Positioned` widget
   - Changed from `SafeArea` + `bottomNavigationBar` to floating overlay using `Stack` in `lib/screens/main_wrapper.dart`
   - Removed the background that was touching the screen edges
   - Enhanced shadow effects for better depth perception
   - Navigation now floats on top of all content

### 5. **Real-time State Updates**
   - Updated `lib/screens/home_screen.dart` to use `BlocBuilder` instead of `AnimatedBuilder` with `WalletProvider`
   - Integrated BLoC events for:
     - Top-up transactions
     - Money transfers
     - Balance updates
     - Transaction history
   - Income/Expense calculations automatically update when state changes

### 6. **File Structure**
   - Created new files:
     - `lib/bloc/wallet_event.dart`
     - `lib/bloc/wallet_state.dart`
     - `lib/bloc/wallet_bloc.dart`
   - Backed up original files:
     - `lib/screens/home_screen_old.dart`
     - `lib/bloc/wallet_bloc_old.dart`

## Implementation Details

### BLoC Event Handling:
```dart
- TopUpWallet: Creates new transaction, updates balance immediately
- SendMoney: Deducts from balance, records transaction instantly
- UpdateBalance: Updates currency balance directly
- AddTransaction: Adds transaction and recalculates summaries
- RefreshWallet: Syncs wallet data
```

### UI Changes:
- Balance visibility toggle (eye icon) moved to top-left
- Larger "Total Balance" title for better hierarchy
- Increased balance amount font size (52sp)
- Removed date, currency badge, and bottom-left info from balance card
- Floating bottom navigation with enhanced styling

## Testing Recommendations

1. Test BLoC state transitions for top-up scenarios
2. Verify money transfer updates balance in real-time
3. Check floating navigation doesn't overlap content on different screen sizes
4. Verify Outfit font loads correctly on all pages
5. Test balance visibility toggle functionality
6. Verify no lingering background edges on bottom navigation
