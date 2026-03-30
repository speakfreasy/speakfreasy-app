import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'core/router.dart';

const _supabaseUrl = 'https://rtbjubzgvsedfnumjksu.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0Ymp1YnpndnNlZGZudW1qa3N1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkzOTE5NzQsImV4cCI6MjA4NDk2Nzk3NH0.HG5LxtfAzHv2rJhODIn48dXnXz9jjG0rKyAJWlHJFoY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: SpeakFreasyApp(),
    ),
  );
}

// Quick reference to Supabase client
final supabase = Supabase.instance.client;

class SpeakFreasyApp extends ConsumerWidget {
  const SpeakFreasyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SpeakFreasy',
      theme: SFTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
