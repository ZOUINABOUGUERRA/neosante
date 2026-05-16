// lib/features/admin/screens/add_edit_user_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../shared/extensions/context_ext.dart';
import '../../../services/auth_service.dart';

class AddEditUserScreen extends ConsumerStatefulWidget {
  final String? userId; // إذا كان null => إضافة، وإلا تعديل
  const AddEditUserScreen({super.key, this.userId});

  @override
  ConsumerState<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends ConsumerState<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _role = 'sage-femme';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    // Logique pour charger les données d'un utilisateur existant (si modification)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userId == null ? 'Ajouter un utilisateur' : 'Modifier un utilisateur'),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (v) {
                  if (widget.userId == null && (v == null || v.length < 6)) {
                    return 'Minimum 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (widget.userId == null)
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirmer mot de passe'),
                  obscureText: true,
                  validator: (v) =>
                      v != _passwordController.text ? 'Ne correspond pas' : null,
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                //value: _role,
                decoration: const InputDecoration(labelText: 'Rôle'),
                items: const [
                  DropdownMenuItem(value: 'sage-femme', child: Text('Sage-femme')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                ],
                onChanged: (value) => setState(() => _role = value!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.stableGreen,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.userId == null ? 'Ajouter' : 'Modifier'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveUser() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);
  try {
    final auth = ref.read(authServiceProvider);
    if (widget.userId == null) {
      // ✅ Ajout d'un nouvel utilisateur
      await auth.createFullUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: _role,
      );
      if (mounted) {
        context.showSuccessSnackBar('Utilisateur ajouté avec succès');
      }
    } else {
      // ✅ Modification d'un utilisateur existant
      await auth.updateUser(widget.userId!, {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'role': _role,
      });
      if (mounted) {
        context.showSuccessSnackBar('Utilisateur modifié avec succès');
      }
    }
    if (mounted) {
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      context.showErrorSnackBar('Erreur: ${e.toString()}');
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
}