// frontend/lib/features/auth/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../theme/colors.dart';
import '../../../shared/extensions/context_ext.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      context.showErrorSnackBar('Veuillez entrer votre adresse email');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      context.showErrorSnackBar('Email invalide');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).sendPasswordReset(email);
      setState(() => _emailSent = true);
    } catch (e) {
      context.showErrorSnackBar('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.lock_reset,
              size: 64,
              color: AppColors.medicalBlue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Réinitialisation du mot de passe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
              style: TextStyle(color: AppColors.darkGray),
            ),
            const SizedBox(height: 32),

            if (_emailSent)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.stableGreen.withValues(alpha: 0.1), // ✅ تم التعديل
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.stableGreen),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.stableGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Email envoyé! Vérifiez votre boîte de réception.',
                        style: const TextStyle(color: AppColors.stableGreen),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _sendResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.medicalBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Envoyer l\'email'),
                ),
            ],

            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // ✅ تم التعديل
              child: const Text('Retour à la connexion'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}