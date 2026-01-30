import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showLogin = true;

  void toggleView() {
    setState(() => _showLogin = !_showLogin);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        if (_showLogin) {
          return LoginScreen(onSignUpClicked: toggleView);
        } else {
          return SignupScreen(onLoginClicked: toggleView);
        }
      },
    );
  }
}
