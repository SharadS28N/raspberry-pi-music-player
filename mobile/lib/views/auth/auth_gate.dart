import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../repositories/auth_repository.dart';
import '../../main.dart';
import 'login_view.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: AppAuthRepository.instance.authStateChanges,
      initialData: AppAuthRepository.instance.currentUser,
      builder: (context, snapshot) {
        if (!AppAuthRepository.instance.isInitialized) {
          return const Scaffold(
            backgroundColor: Color(0xFF000000),
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return const MainNavigationScreen();
        }

        return const LoginView(isRootGate: true);
      },
    );
  }
}
