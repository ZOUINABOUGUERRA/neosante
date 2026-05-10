// frontend/lib/features/admin/widgets/user_card.dart

import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../shared/models/user_model.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onResetPassword;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onResetPassword,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: user.isAdmin
                      ? AppColors.medicalBlue
                      : AppColors.stableGreen,
                  child: Text(
                    user.initials,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isAdmin
                        ? AppColors.medicalBlue.withValues(alpha: 0.2)
                        : AppColors.stableGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isAdmin ? 'Admin' : 'Sage-femme',
                    style: TextStyle(
                      fontSize: 10,
                      color: user.isAdmin ? AppColors.medicalBlue : AppColors.stableGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Créé le: ${_formatDate(user.createdAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
                if (!user.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Désactivé',
                      style: TextStyle(fontSize: 10, color: AppColors.warningOrange),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Modifier',
                  onPressed: onEdit,
                  color: AppColors.medicalBlue,
                ),
                _buildActionButton(
                  icon: Icons.lock_reset,
                  label: 'Reset MDP',
                  onPressed: onResetPassword,
                  color: AppColors.warningOrange,
                ),
                _buildActionButton(
                  icon: user.isActive ? Icons.block : Icons.check_circle,
                  label: user.isActive ? 'Désactiver' : 'Activer',
                  onPressed: onToggleStatus,
                  color: user.isActive ? AppColors.emergencyRed : AppColors.stableGreen,
                ),
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Supprimer',
                  onPressed: onDelete,
                  color: AppColors.emergencyRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}