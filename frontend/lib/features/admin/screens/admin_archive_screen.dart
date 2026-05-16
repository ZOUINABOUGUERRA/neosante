// lib/features/admin/screens/admin_archive_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/colors.dart';
import '../../../shared/extensions/context_ext.dart';
//import 'package:archive/archive.dart';
import '/features/archives/providers/archive_provider.dart';

class AdminArchiveScreen extends ConsumerStatefulWidget {
  const AdminArchiveScreen({super.key});

  @override
  ConsumerState<AdminArchiveScreen> createState() => _AdminArchiveScreenState();
}

class _AdminArchiveScreenState extends ConsumerState<AdminArchiveScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archives complètes'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('archives')
            .orderBy('archivedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final archives = snapshot.data!.docs;
          if (archives.isEmpty) {
            return const Center(child: Text('Aucune archive'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: archives.length,
            itemBuilder: (context, index) {
              final data = archives[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(
                    Icons.archive,
                    color: AppColors.medicalBlue,
                  ),
                  title: Text(data['newbornName'] ?? 'Nouveau-né'),
                  subtitle: Text('Dossier: ${data['dossierNumber']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.restore,
                          color: AppColors.stableGreen,
                        ),
                        onPressed: () => _restoreArchive(archives[index].id),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppColors.emergencyRed,
                        ),
                        onPressed: () => _deleteArchive(archives[index].id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _restoreArchive(String id) async {
    final confirmed = await context.showConfirmationDialog(
      title: 'Restaurer',
      message: 'Restaurer ce dossier ?',
      confirmText: 'Restaurer',
    );
    if (confirmed != true) return;
    // Appel à archiveProvider.restoreArchive
    await ref.read(archiveProvider.notifier).restoreArchive(id);
    if (mounted) context.showSuccessSnackBar('Dossier restauré');
  }

  Future<void> _deleteArchive(String id) async {
    final confirmed = await context.showConfirmationDialog(
      title: 'Supprimer',
      message: 'Supprimer définitivement ?',
      confirmText: 'Supprimer',
      confirmColor: AppColors.emergencyRed,
    );
    if (confirmed != true) return;
    await ref.read(archiveProvider.notifier).deleteArchivePermanently(id);
    if (mounted) context.showSuccessSnackBar('Archive supprimée');
  }
}
