import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../../../core/errors/failure.dart';
import '../../../theme/colors.dart';
import '../../../core/constants/app_constants.dart';
//import '../../../features/admin/screens/admin_dashboard.dart';
//import '../../../features/dashboard/screens/dashboard_screen.dart';

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
        if (user?.role == AppConstants.roleAdmin) {
          context.go('/admin/dashboard');
        } else {
          context.go('/dashboard');
        }
      }
    } on Failure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
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
              elevation: 24, // ✅ زيادة الظل
              shadowColor: Colors.black.withValues(alpha: 0.3), // ✅ لون الظل
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40), // ✅ زيادة الانحناء
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.95),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ إضافة ظل للأيقونة
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.medicalBlue, AppColors.lightBlue],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.medicalBlue.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.baby_changing_station,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'NéoSanté',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.medicalBlue,
                        ),
                      ),
                      const Text(
                        'Système Intelligent de Néonatologie',
                        style: TextStyle(color: AppColors.darkGray),
                      ),
                      const SizedBox(height: 32),

                      // ✅ تحسين تصميم الـ SegmentedButton
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey.withValues(alpha: 0.1),
                        ),
                        child: SegmentedButton<String>(
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
                                return Colors.transparent;
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
                      ),
                      const SizedBox(height: 24),

                      // ✅ تحسين تصميم حقول الإدخال
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email, color: AppColors.medicalBlue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.withValues(alpha: 0.1),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock, color: AppColors.medicalBlue),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.medicalBlue,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.withValues(alpha: 0.1),
                        ),
                        obscureText: _obscurePassword,
                      ),
                      const SizedBox(height: 24),

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        // ✅ تحسين تصميم الزر
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.medicalBlue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                            shadowColor: AppColors.medicalBlue.withValues(alpha: 0.5),
                          ),
                          child: const Text(
                            'Se connecter',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          context.pushNamed('forgot-password');
                        },
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(color: AppColors.medicalBlue),
                        ),
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