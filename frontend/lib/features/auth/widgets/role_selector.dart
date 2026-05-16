import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// Reusable role selector widget for login and user management
class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final bool isEnabled;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildRoleCard(
          role: 'sage-femme',
          label: 'Sage-Femme',
          icon: Icons.person,
          color: AppColors.medicalBlue,
        ),
        const SizedBox(width: 16),
        _buildRoleCard(
          role: 'admin',
          label: 'Administrateur',
          icon: Icons.admin_panel_settings,
          color: AppColors.lightBlue,
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedRole == role;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.8)],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
          // ✅ إضافة ظل جميل
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? () => onRoleChanged(role) : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : color,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 14,
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
