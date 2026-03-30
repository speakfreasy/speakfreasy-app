import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../ui/widgets/sf_button.dart';
import '../../data/auth_repository.dart';
import '../../core/session/session_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Refresh session
      ref.read(sessionProvider.notifier).refresh();

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SFColors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),
                  Image.network(
                    'https://rtbjubzgvsedfnumjksu.supabase.co/storage/v1/object/public/SPEAKFREASY/speak.png',
                    height: 360,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: SFColors.creamMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _signIn(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SFColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SFColors.error),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: SFColors.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SFButton(
                    label: 'Sign In',
                    onPressed: _signIn,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: Text(
                      'Create Account',
                      style: TextStyle(color: SFColors.gold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
