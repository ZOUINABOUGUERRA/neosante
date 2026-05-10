import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../../../core/errors/failure.dart';
import '../../../theme/colors.dart';
import '../../../shared/extensions/context_ext.dart';
import '../../../core/constants/app_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'sage-femme';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _updateCredentials();
  }

  void _updateCredentials() {
    if (_selectedRole == 'admin') {
      _emailController.text = AppConstants.testAdminEmail;
      _passwordController.text = AppConstants.testAdminPassword;
    } else {
      _emailController.text = AppConstants.testSageFemmeEmail;
      _passwordController.text = AppConstants.testSageFemmePassword;
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (mounted) {
        final user = ref.read(authProvider).user;
        if (user?.isAdmin == true) {
          GoRouter.of(context).pushReplacementNamed('/admin/dashboard');
        } else {
          GoRouter.of(context).pushReplacementNamed('/dashboard');
        }
      }
    } on Failure catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.medicalBlue, AppColors.lightBlue],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.medicalBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.baby_changing_station,
                        size: 60,
                        color: AppColors.medicalBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'NéoSanté',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.medicalBlue,
                      ),
                    ),
                    const Text(
                      'Système Intelligent de Néonatologie',
                      style: TextStyle(color: AppColors.darkGray),
                    ),
                    const SizedBox(height: 32),

                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'sage-femme',
                          label: Text('👩‍⚕️ Sage-Femme'),
                        ),
                        ButtonSegment(
                          value: 'admin',
                          label: Text('👨‍💼 Administrateur'),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (set) {
                        setState(() {
                          _selectedRole = set.first;
                          _updateCredentials();
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.medicalBlue;
                            }
                            return Colors.grey[200];
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return AppColors.darkGray;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                      obscureText: _obscurePassword,
                    ),
                    const SizedBox(height: 24),

                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.medicalBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        GoRouter.of(context).pushNamed('forgot-password');
                      },
                      child: const Text('Mot de passe oublié ?'),
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    Text(
                      'Développé par NéoSanté Medical Team',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}