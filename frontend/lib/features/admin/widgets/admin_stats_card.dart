// lib/features/admin/widgets/admin_stats_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminStatsCard extends StatelessWidget {
  final String title;
  final AsyncValue<int> count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AdminStatsCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              count.when(
                data: (value) => Text(
                  value.toString(),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => const Text('Erreur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}