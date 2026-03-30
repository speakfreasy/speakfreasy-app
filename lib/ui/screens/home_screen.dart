import 'package:flutter/material.dart';
import '../../core/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SFColors.black,
      body: const Center(
        child: Text(
          'Home content coming later',
          style: TextStyle(
            color: SFColors.creamMuted,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
