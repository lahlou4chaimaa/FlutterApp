import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_theme.dart';
import 'screens/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wtmzujapcgmfzvuxeqnv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0bXp1amFwY2dtZnp2dXhlcW52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4ODk5MjgsImV4cCI6MjEwNzQ2NTkyOH0.TX_uv1gft16GWGpFudqiH-6HUv2VeYYob6NcjBNNI28',
  );

  final user = Supabase.instance.client.auth.currentUser;
  appThemeMode.value =
      user?.userMetadata?['dark_mode'] == true
          ? ThemeMode.dark
          : ThemeMode.light;

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _authSubscription =
        supabase.auth.onAuthStateChange.listen((event) {
      final user = event.session?.user;

      if (user != null) {
        appThemeMode.value =
            user.userMetadata?['dark_mode'] == true
                ? ThemeMode.dark
                : ThemeMode.light;
      } else {
        appThemeMode.value = ThemeMode.light;
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'SkillUp',
          debugShowCheckedModeBanner: false,
          theme: buildSkillUpTheme(isDark: false),
          darkTheme: buildSkillUpTheme(isDark: true),
          themeMode: mode,
          home: const LoginPage(),
        );
      },
    );
  }
}