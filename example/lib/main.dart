import 'package:apple_sign_in_plugin/apple_sign_in_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the plugin with your specific credentials
  // correct key path and IDs are required for this to work
  await AppleSignInPlugin.initialize(
    pemKeyPath: 'assets/keys/apple_private_key.pem',
    keyId: 'YOUR_KEY_ID',
    teamId: 'YOUR_TEAM_ID',
    bundleId: 'YOUR_APP_BUNDLE_ID',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apple Sign In Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const SignInPage(),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  AppleSignInResult? _result;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isSignedIn = AppleSignInPlugin.isSignedIn();
    setState(() {
      _isLoggedIn = isSignedIn;
    });
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await AppleSignInPlugin.signInWithApple();
      if (result != null) {
        setState(() {
          _result = result;
          _isLoggedIn = true;
        });
        if (kDebugMode) {
          print('Sign in success: ${result.email}');
          print('ID Token: ${result.idToken}');
          print('Access Token: ${result.accessToken}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sign in error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await AppleSignInPlugin.signOut();
      setState(() {
        _result = null;
        _isLoggedIn = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Sign out error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apple Sign In Plugin'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: _isLoggedIn ? _buildUserProfile() : _buildLoginButton(),
              ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.apple, size: 80),
        const SizedBox(height: 20),
        const Text(
          'Sign in to access your account',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _signIn,
            icon: const Icon(Icons.apple),
            label: const Text('Sign in with Apple'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfile() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Icon(Icons.account_circle, size: 80)),
          const SizedBox(height: 30),
          const Text('User Details:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(),
          if (_result != null) ...[
            _userInfoRow('Name',
                '${_result?.givenName ?? ''} ${_result?.familyName ?? ''}'),
            _userInfoRow('Email', _result?.email ?? 'N/A'),
            _userInfoRow(
                'User ID',
                _result?.userIdentifier != null
                    ? '${_result!.userIdentifier!.substring(0, 5)}...'
                    : 'N/A'),
            const Divider(),
            const Text('Tokens (Backend Ready):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            _userInfoRow('Info',
                'Full result object contains ID Token,\nAccess Token & Refresh Token.'),
          ] else
            const Text('Session active (details pending fresh login)'),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
