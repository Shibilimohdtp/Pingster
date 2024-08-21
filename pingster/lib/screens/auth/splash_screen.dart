import 'package:flutter/material.dart';
import 'package:pingster/providers/auth_provider.dart';
import 'package:pingster/theme.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
  }

  Future<void> _checkUserLoggedIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool isLoggedIn = await authProvider.isUserLoggedIn();

    if (isLoggedIn) {
      context.go('/chat');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PingsterTheme.primary200,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace this with your app logo
            Icon(
              Icons.chat_bubble_outline,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
