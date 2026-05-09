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
      child: InkWell(
        onTap: isEnabled ? () => onRoleChanged(role) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}