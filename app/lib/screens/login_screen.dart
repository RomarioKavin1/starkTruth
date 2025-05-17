import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _connecting = false;
  bool _connected = false;
  String? _walletAddress;
  String? _error;

  // Mock connect function
  Future<void> _connectWallet() async {
    setState(() {
      _connecting = true;
      _error = null;
    });
    await Future.delayed(const Duration(seconds: 2));
    // Randomly succeed/fail for mock
    if (DateTime.now().second % 2 == 0) {
      setState(() {
        _connected = true;
        _walletAddress = '0xFAKE1234...ABCD';
        _connecting = false;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(context).pushReplacementNamed('/main');
      });
    } else {
      setState(() {
        _error = 'Failed to connect. Try again!';
        _connecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet, size: 80, color: Colors.greenAccent.shade400),
              const SizedBox(height: 24),
              Text(
                'Connect Wallet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              if (_connected && _walletAddress != null)
                Column(
                  children: [
                    Text('Connected!', style: TextStyle(color: Colors.greenAccent.shade400, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(_walletAddress!, style: const TextStyle(color: Colors.white70)),
                  ],
                )
              else ...[
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade400,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: _connecting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.link),
                  label: Text(_connecting ? 'Connecting...' : 'Connect Wallet'),
                  onPressed: _connecting ? null : _connectWallet,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
