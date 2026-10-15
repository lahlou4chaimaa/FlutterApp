
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showMessage(
        'Veuillez remplir tous les champs.',
        isError: true,
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showMessage(
        'Veuillez saisir une adresse email valide.',
        isError: true,
      );
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Le mot de passe doit contenir au moins 6 caractères.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nom': name,
          'phone': phone,
        },
      );

      if (!mounted) return;

      if (response.user == null) {
        _showMessage(
          'Inscription impossible. Aucun utilisateur créé.',
          isError: true,
        );
        return;
      }

      if (response.session != null) {
        _showMessage(
          'Compte créé avec succès. Vous êtes connecté.',
        );

        // Si ton application exige une navigation directe
        // vers HomePage après inscription, ajoute-la ici.
      } else {
        _showMessage(
          'Compte créé. Vérifiez votre email pour confirmer votre inscription.',
        );

        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      debugPrint('Supabase signup error: ${e.message}');
      debugPrint('Status code: ${e.statusCode}');

      if (mounted) {
        _showMessage(
          _getSignUpErrorMessage(e),
          isError: true,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Unexpected signup error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showMessage(
          'Une erreur inattendue est survenue. Vérifiez votre connexion.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getSignUpErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('already registered') ||
        message.contains('user already registered')) {
      return 'Cette adresse email possède déjà un compte.';
    }

    if (message.contains('password')) {
      return 'Mot de passe refusé : ${e.message}';
    }

    if (message.contains('email')) {
      return 'Vérifiez votre adresse email : ${e.message}';
    }

    if (message.contains('too many requests')) {
      return 'Trop de tentatives. Veuillez réessayer plus tard.';
    }

    return 'Erreur lors de l’inscription : ${e.message}';
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/image.png',
                  height: 80,
                  width: 80,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Password (minimum 6 characters)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
