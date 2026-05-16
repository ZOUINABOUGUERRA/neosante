import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Step 1: Service selection
/// 👩‍⚕️ Maternité → Nouveau-né prématuré / Nouveau-né à terme
/// 🏥 Service Néonatal → Prématuré / À terme (après transfert)
class Step1Service extends StatefulWidget {
  final Function(String) onServiceSelected;
  final String initialValue;
  final bool
  isTransferMode; // ✅ vrai si c'est un transfert vers Service Néonatal

  const Step1Service({
    super.key,
    required this.onServiceSelected,
    this.initialValue = '',
    this.isTransferMode = false,
  });

  @override
  State<Step1Service> createState() => _Step1ServiceState();
}

class _Step1ServiceState extends State<Step1Service> {
  String? _selectedService;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.initialValue.isEmpty ? null : widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header avec icône
          Row(
            children: [
              Icon(
                widget.isTransferMode ? Icons.local_hospital : Icons.woman,
                color: AppColors.medicalBlue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                widget.isTransferMode
                    ? '🏥 Service Néonatal'
                    : '👩‍⚕️ Maternité',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.medicalBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.isTransferMode
                ? 'Sélectionnez le type de nouveau-né pour le service néonatal'
                : 'La sélection détermine le type de dossier et le suivi associé',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 32),

          // ✅ Deux cartes principales
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  emoji: '👶',
                  title: widget.isTransferMode
                      ? 'Prématuré'
                      : 'Nouveau-né prématuré',
                  subtitle: widget.isTransferMode
                      ? '< 37 SA'
                      : 'Âge gestationnel < 37 SA',
                  description: 'Surveillance renforcée, soins intensifs',
                  value: AppConstants.servicePremature,
                  color: const Color(0xFF7B2D8E),
                  isTransferMode: widget.isTransferMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildServiceCard(
                  emoji: '🍼',
                  title: widget.isTransferMode
                      ? 'À terme'
                      : 'Nouveau-né à terme',
                  subtitle: widget.isTransferMode
                      ? '≥ 37 SA'
                      : 'Âge gestationnel ≥ 37 SA',
                  description: 'Surveillance standard, retour avec la mère',
                  value: AppConstants.serviceFullTerm,
                  color: AppColors.stableGreen,
                  isTransferMode: widget.isTransferMode,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ✅ Message de confirmation
          if (_selectedService != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.stableGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.stableGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.stableGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedService == AppConstants.servicePremature
                          ? '✓ Fiche de suivi prématuré sélectionnée'
                          : '✓ Fiche de suivi à terme sélectionnée',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String emoji,
    required String title,
    required String subtitle,
    required String description,
    required String value,
    required Color color,
    required bool isTransferMode,
  }) {
    final isSelected = _selectedService == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedService = value;
          widget.onServiceSelected(value);
        });
      },
      borderRadius: BorderRadius.circular(24),
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
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(24),
          color: isSelected ? null : Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Emoji ou icône
              Text(emoji, style: const TextStyle(fontSize: 42)),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: isTransferMode ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              if (!isTransferMode)
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white70 : Colors.grey[500],
                  ),
                ),
              const SizedBox(height: 16),
              if (isSelected)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 22),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
