import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase
  await Supabase.initialize(
    url: 'https://wtmzujapcgmfzvuxeqnv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0bXp1amFwY2dtZnp2dXhlcW52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4ODk5MjgsImV4cCI6MjEwNzQ2NTkyOH0.TX_uv1gft16GWGpFudqiH-6HUv2VeYYob6NcjBNNI28',
  );

  runApp(const MyApp());
}

// Instance globale pour accéder à Supabase facilement
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Supabase MultiPlateformes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}