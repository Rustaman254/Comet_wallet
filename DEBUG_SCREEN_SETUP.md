# How to Add Debug Screen to Settings (Optional)

## Option 1: Add Debug Button to Settings Screen

If you have a `settings_screen.dart`, add this button:

```dart
import '../screens/debug_token_screen.dart';

// In your settings screen, add this button:
ListTile(
  leading: const Icon(Icons.bug_report),
  title: const Text('Debug Token Status'),
  subtitle: const Text('View authentication status'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DebugTokenScreen(),
      ),
    );
  },
)
```

## Option 2: Add via Named Route

In your `main.dart` or routing configuration:

```dart
Map<String, WidgetBuilder> get routes => {
  '/': (context) => const HomeScreen(),
  '/login': (context) => const LoginScreen(),
  '/settings': (context) => const SettingsScreen(),
  '/debug-token': (context) => const DebugTokenScreen(),  // Add this line
  // ... other routes
};
```

Then navigate to it:
```dart
Navigator.pushNamed(context, '/debug-token');
```

## Option 3: Floating Action Button for Quick Access

Add to any screen for quick debugging:

```dart
import '../screens/debug_token_screen.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('My Screen')),
    body: const Center(child: Text('Content')),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DebugTokenScreen()),
        );
      },
      child: const Icon(Icons.bug_report),
    ),
  );
}
```

## Option 4: Debug Menu in App Drawer

Add to your main drawer:

```dart
ListTile(
  leading: const Icon(Icons.developer_mode),
  title: const Text('Developer Tools'),
  children: [
    ListTile(
      leading: const Icon(Icons.bug_report),
      title: const Text('Token Debug'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DebugTokenScreen()),
        );
      },
    ),
  ],
)
```

## Features of Debug Screen

The `DebugTokenScreen` provides:

1. **Status Summary** - See at a glance:
   - Token Exists (✓/✗)
   - Token Not Empty (✓/✗)
   - Is Authenticated (✓/✗)
   - Token Length

2. **Token Preview** - Shows first 20 characters of JWT token

3. **Stored User Data** - Shows:
   - Token (full)
   - User ID
   - Email
   - Phone Number

4. **Action Buttons**:
   - **Refresh Status** - Update token info from storage
   - **Run Full Diagnostics** - Complete verification (console output)
   - **Test Wallet Token Access** - Check wallet-specific token availability

5. **Console Output** - All actions print detailed logs to console

## Usage During Testing

1. **After Login**: Navigate to debug screen
2. **Check Status**: Should show all green checkmarks
3. **Click "Run Full Diagnostics"**: Opens console with detailed info
4. **Before Wallet Top-Up**: Verify token still available
5. **If Top-Up Fails**: Click "Test Wallet Token Access" to debug

## Sample Console Output

When you click buttons, you'll see:
```
[DEBUG] ========== TOKEN STATUS DEBUG ==========
[DEBUG] Token Debug Info: {
  token_exists: true,
  token_not_empty: true,
  token_length: 456,
  token_preview: 'eyJhbGciOiJIUzI1NiI...',
  is_authenticated: true
}
[DEBUG] User Data: {
  token: 'eyJhbGciOiJIUzI1NiIsInR5cCI...',
  user_id: '12345',
  email: 'user@example.com',
  phone_number: '254712345678'
}
[DEBUG] Is Authenticated: true
[DEBUG] ========== END TOKEN STATUS DEBUG ==========
```

## Removing Debug Screen Later

Once fixed, simply don't add the navigation. The screen file remains but won't be accessible.

## Complete Settings Screen Example

```dart
import 'package:flutter/material.dart';
import '../screens/debug_token_screen.dart';
import '../services/token_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Account'),
            enabled: false,
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () => Navigator.pushNamed(context, '/edit-profile'),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: () => Navigator.pushNamed(context, '/change-password'),
          ),
          const Divider(),
          const ListTile(
            title: Text('Support'),
            enabled: false,
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Debug Token Status'),
            subtitle: const Text('View authentication info'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DebugTokenScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await TokenService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
```

---

That's all! The debug screen is optional for quick troubleshooting. Remove it before production if desired.
