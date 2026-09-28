import 'package:flutter/material.dart';

/// Splash screen shown while the app initializes.
/// TODO: Implement full splash screen in T-14.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
