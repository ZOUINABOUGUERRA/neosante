import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/dossier_provider.dart';
import '../widgets/dossier_card.dart';

class DossierListScreen extends ConsumerStatefulWidget {
  const DossierListScreen({super.key});

  @override
  ConsumerState<DossierListScreen> createState() => _DossierListScreenState();
}

class _DossierListScreenState extends ConsumerState<DossierListScreen> {
  String _selectedFilter = 'active';
  String _selectedType = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDossiers();
  }

  void _loadDossiers() {
    if (_selectedType == 'all' || _selectedType == 'premature') {
      ref.read(dossierProvider.notifier).loadDossiers(
        AppConstants.dossiersPrematuresCollection,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );
    }
    if (_selectedType == 'all' || _selectedType == 'fullterm') {
      ref.read(dossierProvider.notifier).loadDossiers(
        AppConstants.dossiersATermeCollection,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dossierState = ref.watch(dossierProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossiers médicaux'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        // ✅ Correction: utiliser GoRouter.of(context) au lieu de context directement
        onPressed: () => GoRouter.of(context).pushNamed('/dossiers/create'),
        child: const Icon(Icons.add),
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
                  _buildFilterChip('Tous', 'all', _selectedFilter),
                  const SizedBox(width: 8),
                  _buildFilterChip('Actifs', 'active', _selectedFilter),
                  const SizedBox(width: 8),
                  _buildFilterChip('Transférés', 'transferred', _selectedFilter),
                  const SizedBox(width: 8),
                  _buildFilterChip('Archivés', 'archived', _selectedFilter),
                ],
              ),
            ),
          ),
          // Type tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTypeChip('Tous', 'all'),
                const SizedBox(width: 8),
                _buildTypeChip('👶 Prématurés', 'premature'),
                const SizedBox(width: 8),
                _buildTypeChip('🍼 À terme', 'fullterm'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Dossier count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${dossierState.dossiers.length} dossiers',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (_searchQuery.isNotEmpty)
                  Chip(
                    label: Text('Recherche: $_searchQuery'),
                    onDeleted: () {
                      setState(() => _searchQuery = '');
                      _loadDossiers();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Dossier list
          Expanded(
            child: dossierState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : dossierState.dossiers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Aucun dossier trouvé'),
                          ],
                        ),
                      )
                    : isDesktop
                        ? _buildDesktopGrid(dossierState.dossiers)
                        : _buildMobileList(dossierState.dossiers),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selected) {
    final isSelected = selected == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = selected ? value : 'all');
        _loadDossiers();
      },
      backgroundColor: Colors.grey.shade100,
      // ✅ Correction: withOpacity → withValues
      selectedColor: AppColors.medicalBlue.withValues(alpha: 0.2),
      checkmarkColor: AppColors.medicalBlue,
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedType = selected ? value : 'all');
        _loadDossiers();
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppColors.medicalBlue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
      ),
    );
  }

  Widget _buildDesktopGrid(List<dynamic> dossiers) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: dossiers.length,
      itemBuilder: (context, index) {
        final dossier = dossiers[index] as Map<String, dynamic>;
        return DossierCard(
          dossier: dossier,
          // ✅ Correction: utiliser GoRouter.of(context)
          onTap: () => GoRouter.of(context).pushNamed('/dossiers/${dossier['id']}'),
        );
      },
    );
  }

  Widget _buildMobileList(List<dynamic> dossiers) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dossiers.length,
      itemBuilder: (context, index) {
        final dossier = dossiers[index] as Map<String, dynamic>;
        return DossierCard(
          dossier: dossier,
          // ✅ Correction: utiliser GoRouter.of(context)
          onTap: () => GoRouter.of(context).pushNamed('/dossiers/${dossier['id']}'),
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher un dossier'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Nom, numéro de dossier...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _searchQuery = _searchController.text);
              Navigator.pop(context);
              _loadDossiers();
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filtres',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterOption('Tous', 'all'),
                _buildFilterOption('Actifs', 'active'),
                _buildFilterOption('Transférés', 'transferred'),
                _buildFilterOption('Archivés', 'archived'),
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildTypeOption('Tous', 'all'),
                _buildTypeOption('Prématurés', 'premature'),
                _buildTypeOption('À terme', 'fullterm'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'all';
                        _selectedType = 'all';
                      });
                      Navigator.pop(context);
                      _loadDossiers();
                    },
                    child: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadDossiers();
                    },
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = selected ? value : 'all');
      },
      backgroundColor: Colors.grey.shade100,
      // ✅ Correction: withOpacity → withValues
      selectedColor: AppColors.medicalBlue.withValues(alpha: 0.2),
    );
  }

  Widget _buildTypeOption(String label, String value) {
    final isSelected = _selectedType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedType = selected ? value : 'all');
      },
      backgroundColor: Colors.grey.shade100,
      // ✅ Correction: withOpacity → withValues
      selectedColor: AppColors.medicalBlue.withValues(alpha: 0.2),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}