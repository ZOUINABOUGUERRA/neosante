import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/colors.dart';
import '../../../shared/extensions/context_ext.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/archive_provider.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  String _selectedFilter = 'all'; // 'all', 'premature', 'fullterm'
  final TextEditingController _searchController = TextEditingController();
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(archiveSearchProvider.notifier).state = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final archiveState = ref.watch(archiveProvider);
    final filteredArchives = ref.watch(filteredArchivesProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    // Apply type filter
    final displayArchives = _applyTypeFilter(filteredArchives);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archives'),
        backgroundColor: Colors.transparent,
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          // More options
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_old') {
                _showDeleteOldDialog();
              } else if (value == 'stats') {
                _showStatsDialog(archiveState);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'stats', child: Text('Statistiques')),
              const PopupMenuItem(
                  value: 'delete_old',
                  child: Text('Supprimer les anciennes archives')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tous', 'all', archiveState.totalCount),
                  const SizedBox(width: 8),
                  _buildFilterChip('👶 Prématurés', 'premature',
                      archiveState.prematureCount),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      '🍼 À terme', 'fullterm', archiveState.fullTermCount),
                ],
              ),
            ),
          ),
          // Archive count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${displayArchives.length} dossier(s) archivé(s)',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (_searchController.text.isNotEmpty)
                  Chip(
                    label: Text('Recherche: ${_searchController.text}'),
                    onDeleted: () {
                      _searchController.clear();
                      ref.read(archiveSearchProvider.notifier).state = '';
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Archive list
          Expanded(
            child: archiveState.isLoading && displayArchives.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : displayArchives.isEmpty
                    ? _buildEmptyState()
                    : isDesktop
                        ? _buildDesktopGrid(displayArchives)
                        : _buildMobileList(displayArchives),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = selected ? value : 'all');
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppColors.medicalBlue.withValues(alpha: 0.2),
      checkmarkColor: AppColors.medicalBlue,
    );
  }

  List<Map<String, dynamic>> _applyTypeFilter(
      List<Map<String, dynamic>> archives) {
    if (_selectedFilter == 'all') return archives;

    return archives.where((archive) {
      final isPremature = archive['originalCollection'] ==
              AppConstants.dossiersPrematuresCollection ||
          archive['serviceType'] == AppConstants.servicePremature;
      return _selectedFilter == 'premature' ? isPremature : !isPremature;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.archive, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune archive',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Les dossiers clôturés apparaîtront ici',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid(List<Map<String, dynamic>> archives) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: archives.length,
      itemBuilder: (context, index) {
        final archive = archives[index];
        return _buildArchiveCard(archive);
      },
    );
  }

  Widget _buildMobileList(List<Map<String, dynamic>> archives) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: archives.length,
      itemBuilder: (context, index) {
        final archive = archives[index];
        return _buildArchiveCard(archive);
      },
    );
  }

  Widget _buildArchiveCard(Map<String, dynamic> archive) {
    final archivedAt = archive['archivedAt'] as Timestamp?;
    final archivedDate = archivedAt?.toDate() ?? DateTime.now();
    final isPremature = archive['originalCollection'] ==
            AppConstants.dossiersPrematuresCollection ||
        archive['serviceType'] == AppConstants.servicePremature;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showArchiveDetails(archive),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type badge
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPremature
                          ? Colors.purple.withValues(alpha: 0.2)
                          : AppColors.stableGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPremature ? 'Prématuré' : 'À terme',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            isPremature ? Colors.purple : AppColors.stableGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      archive['dossierNumber'] ?? 'N/A',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Patient info
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.medicalBlue.withValues(alpha: 0.1),
                    child:
                        const Icon(Icons.archive, color: AppColors.medicalBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          archive['newbornName'] ?? 'Nouveau-né',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Mère: ${archive['motherName'] ?? 'N/A'}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Medical info
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.calendar_today,
                      '${archive['gestationalAge'] ?? '?'} SA'),
                  _buildInfoChip(Icons.monitor_weight,
                      '${archive['birthWeight'] ?? '?'} g'),
                  _buildInfoChip(Icons.access_time,
                      DateFormat('dd/MM/yyyy', 'fr_FR').format(archivedDate)),
                ],
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isRestoring
                          ? null
                          : () => _restoreArchive(archive['id']),
                      icon: _isRestoring
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.restore),
                      label: const Text('Restaurer'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteArchive(archive['id']),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.emergencyRed,
                        side: const BorderSide(color: AppColors.emergencyRed),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _restoreArchive(String archiveId) async {
    final confirmed = await context.showConfirmationDialog(
      title: 'Restaurer le dossier',
      message: 'Êtes-vous sûr de vouloir restaurer ce dossier ?\n\n'
          'Il sera réactivé dans la liste des dossiers actifs.',
      confirmText: 'Restaurer',
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    try {
      final restoredId =
          await ref.read(archiveProvider.notifier).restoreArchive(archiveId);
      if (mounted && restoredId != null) {
        context.showSuccessSnackBar('Dossier restauré avec succès');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Erreur lors de la restauration');
      }
    } finally {
      setState(() => _isRestoring = false);
    }
  }

  Future<void> _deleteArchive(String archiveId) async {
    final confirmed = await context.showConfirmationDialog(
      title: 'Supprimer définitivement',
      message: '⚠️ Attention : Cette action est irréversible.\n\n'
          'Le dossier sera définitivement supprimé de la base de données.\n\n'
          'Êtes-vous sûr de vouloir continuer ?',
      confirmText: 'Supprimer',
      confirmColor: AppColors.emergencyRed,
    );

    if (confirmed != true) return;

    try {
      final success = await ref
          .read(archiveProvider.notifier)
          .deleteArchivePermanently(archiveId);
      if (mounted && success) {
        context.showSuccessSnackBar('Archive supprimée');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }

  void _showArchiveDetails(Map<String, dynamic> archive) {
    final archivedAt = archive['archivedAt'] as Timestamp?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Détails de l\'archive',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailSection('👶 Nouveau-né', [
                _buildDetailRow('Nom', archive['newbornName'] ?? 'N/A'),
                _buildDetailRow(
                    'Date naissance',
                    archive['birthDateTime'] != null
                        ? DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(
                            (archive['birthDateTime'] as Timestamp).toDate())
                        : 'N/A'),
                _buildDetailRow('Âge gestationnel',
                    '${archive['gestationalAge'] ?? '?'} SA'),
                _buildDetailRow('Poids', '${archive['birthWeight'] ?? '?'} g'),
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('👩 Mère', [
                _buildDetailRow('Nom', archive['motherName'] ?? 'N/A'),
                _buildDetailRow(
                    'Mode accouchement', archive['deliveryMethod'] ?? 'N/A'),
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('📅 Archivage', [
                _buildDetailRow(
                    'Date d\'archivage',
                    archivedAt != null
                        ? DateFormat('dd/MM/yyyy HH:mm', 'fr_FR')
                            .format(archivedAt.toDate())
                        : 'N/A'),
                _buildDetailRow('Collection originale',
                    archive['originalCollection'] ?? 'N/A'),
              ]),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Fermer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _restoreArchive(archive['id']);
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Restaurer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher dans les archives'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nom, numéro de dossier...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              ref.read(archiveSearchProvider.notifier).state = '';
              Navigator.pop(context);
            },
            child: const Text('Effacer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteOldDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les anciennes archives'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Supprimer les archives plus anciennes que :'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDaysButton(30, '30 jours'),
                const SizedBox(width: 8),
                _buildDaysButton(90, '90 jours'),
                const SizedBox(width: 8),
                _buildDaysButton(180, '6 mois'),
                const SizedBox(width: 8),
                _buildDaysButton(365, '1 an'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysButton(int days, String label) {
    return ElevatedButton(
      onPressed: () async {
        Navigator.pop(context);
        final confirmed = await context.showConfirmationDialog(
          title: 'Confirmation',
          message:
              'Supprimer définitivement toutes les archives de plus de $days ?\n\n'
              'Cette action est irréversible.',
          confirmText: 'Supprimer',
          confirmColor: AppColors.emergencyRed,
        );

        if (confirmed == true) {
          final count =
              await ref.read(archiveProvider.notifier).deleteOldArchives(days);
          if (mounted) {
            context.showSuccessSnackBar('$count archive(s) supprimée(s)');
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.emergencyRed,
      ),
      child: Text(label),
    );
  }

  void _showStatsDialog(ArchiveState archiveState) {
    final stats = ref.read(archiveProvider.notifier).getStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques des archives'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total des archives', archiveState.totalCount),
            _buildStatRow('Dossiers prématurés', archiveState.prematureCount),
            _buildStatRow('Dossiers à terme', archiveState.fullTermCount),
            const Divider(height: 24),
            const Text('Par mois :',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...(stats['byMonth'] as Map<String, int>).entries.map((entry) {
              return _buildStatRow(entry.key, entry.value);
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
