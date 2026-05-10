import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Step 1: Service selection (Prématuré / À terme)
/// This step determines which collection the dossier will be saved to.
class Step1Service extends StatefulWidget {
  final Function(String) onServiceSelected;
  final String initialValue;

  const Step1Service({
    super.key,
    required this.onServiceSelected,
    this.initialValue = '',
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez le service',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Cette sélection détermine le type de dossier et le suivi associé.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  title: 'Nouveau-né Prématuré',
                  subtitle: 'Âge gestationnel < 37 SA',
                  description: 'Surveillance renforcée, soins intensifs',
                  icon: Icons.access_time,
                  value: AppConstants.servicePremature,
                  color: const Color(0xFF7B2D8E),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildServiceCard(
                  title: 'Nouveau-né à terme',
                  subtitle: 'Âge gestationnel ≥ 37 SA',
                  description: 'Surveillance standard, retour avec la mère',
                  icon: Icons.celebration,
                  value: AppConstants.serviceFullTerm,
                  color: AppColors.stableGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (_selectedService != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.medicalBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.medicalBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedService == AppConstants.servicePremature
                          ? 'Dossier prématuré sélectionné'
                          : 'Dossier à terme sélectionné',
                      style: const TextStyle(fontWeight: FontWeight.w500),
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
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    final isSelected = _selectedService == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedService = value;
          widget.onServiceSelected(value);
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? color.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              if (isSelected)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.check_circle, color: color, size: 20),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
