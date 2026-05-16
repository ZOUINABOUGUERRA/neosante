import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/dossier_provider.dart';
import '../widgets/dossier_card.dart';
import '../../../shared/models/dossier_model.dart';

class DossierListScreen extends ConsumerStatefulWidget {
  const DossierListScreen({super.key});

  @override
  ConsumerState<DossierListScreen> createState() =>
      _DossierListScreenState();
}

class _DossierListScreenState
    extends ConsumerState<DossierListScreen> {
  String _selectedFilter = 'active';
  String _selectedType = 'all';
  String _searchQuery = '';

  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDossiers();
    });
  }

  void _loadDossiers() {
    final notifier = ref.read(dossierProvider.notifier);

    if (_selectedType == 'all' ||
        _selectedType == 'premature') {
      notifier.loadDossiers(
        AppConstants.dossiersPrematuresCollection,
        status:
            _selectedFilter == 'all'
                ? null
                : _selectedFilter,
      );
    }

    if (_selectedType == 'all' ||
        _selectedType == 'fullterm') {
      notifier.loadDossiers(
        AppConstants.dossiersATermeCollection,
        status:
            _selectedFilter == 'all'
                ? null
                : _selectedFilter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dossierState = ref.watch(dossierProvider);

    final isDesktop =
        MediaQuery.of(context).size.width > 800;

    /// ✅ FIX SEARCH
    final List<DossierModel> filteredDossiers =
        _searchQuery.trim().isEmpty
            ? dossierState.dossiers
            : dossierState.dossiers.where((dossier) {
              final newbornName =
                  dossier.newbornName
                      .toLowerCase()
                      .trim();

              final dossierNumber =
                  dossier.dossierNumber
                      .toLowerCase()
                      .trim();

              final query =
                  _searchQuery
                      .toLowerCase()
                      .trim();

              return newbornName.contains(query) ||
                  dossierNumber.contains(query);
            }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Dossiers médicaux'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Rechercher',
            onPressed: _showSearchDialog,
          ),

          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrer',
            onPressed: _showFilterDialog,
          ),

          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
            backgroundColor:
                AppColors.medicalBlue,

            onPressed: () {
              GoRouter.of(
                context,
              ).pushNamed('create_dossier');
            },

            icon: const Icon(Icons.add),
            label: const Text('Nouveau'),
          ),

      body: Column(
        children: [
          /// STATUS FILTERS
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),

            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,

              child: Row(
                children: [
                  _buildFilterChip(
                    '📋 Tous',
                    'all',
                  ),

                  const SizedBox(width: 8),

                  _buildFilterChip(
                    '🟢 Actifs',
                    'active',
                  ),

                  const SizedBox(width: 8),

                  _buildFilterChip(
                    '🟠 Transférés',
                    'transferred',
                  ),

                  const SizedBox(width: 8),

                  _buildFilterChip(
                    '📦 Archivés',
                    'archived',
                  ),
                ],
              ),
            ),
          ),

          /// TYPE FILTERS
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),

            child: Row(
              children: [
                _buildTypeChip(
                  '👶 Tous',
                  'all',
                ),

                const SizedBox(width: 8),

                _buildTypeChip(
                  '👶 Prématurés',
                  'premature',
                ),

                const SizedBox(width: 8),

                _buildTypeChip(
                  '🍼 À terme',
                  'fullterm',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// COUNT + SEARCH CHIP
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),

            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                Text(
                  '📊 ${filteredDossiers.length} dossiers',

                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (_searchQuery.isNotEmpty)
                  Chip(
                    deleteIcon:
                        const Icon(
                          Icons.close,
                          size: 16,
                        ),

                    label: Text(
                      '🔍 ${_searchQuery.length > 20 ? '${_searchQuery.substring(0, 20)}...' : _searchQuery}',
                    ),

                    onDeleted: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });

                      _loadDossiers();
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// LIST
          Expanded(
            child:
                dossierState.isLoading &&
                        filteredDossiers.isEmpty
                    ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                    : filteredDossiers.isEmpty
                    ? _buildEmptyState()
                    : isDesktop
                    ? _buildDesktopGrid(
                      filteredDossiers,
                    )
                    : _buildMobileList(
                      filteredDossiers,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
  ) {
    final isSelected =
        _selectedFilter == value;

    return FilterChip(
      label: Text(label),

      selected: isSelected,

      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });

        _loadDossiers();
      },

      backgroundColor:
          Colors.grey.shade100,

      selectedColor:
          AppColors.medicalBlue,

      checkmarkColor: Colors.white,

      labelStyle: TextStyle(
        color:
            isSelected
                ? Colors.white
                : Colors.grey.shade700,

        fontWeight:
            isSelected
                ? FontWeight.bold
                : FontWeight.normal,
      ),
    );
  }

  Widget _buildTypeChip(
    String label,
    String value,
  ) {
    final isSelected =
        _selectedType == value;

    return ChoiceChip(
      label: Text(label),

      selected: isSelected,

      onSelected: (_) {
        setState(() {
          _selectedType = value;
        });

        _loadDossiers();
      },

      backgroundColor:
          Colors.grey.shade100,

      selectedColor:
          AppColors.medicalBlue,

      labelStyle: TextStyle(
        color:
            isSelected
                ? Colors.white
                : Colors.grey.shade700,
      ),
    );
  }

  Widget _buildDesktopGrid(
    List<DossierModel> dossiers,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),

      itemCount: dossiers.length,

      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),

      itemBuilder: (context, index) {
        final dossier = dossiers[index];

        return DossierCard(
          dossier: dossier.toMap(),

          onTap: () {
            GoRouter.of(context).pushNamed(
              'dossier_detail',

              pathParameters: {
                'id': dossier.id,
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMobileList(
    List<DossierModel> dossiers,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),

      itemCount: dossiers.length,

      itemBuilder: (context, index) {
        final dossier = dossiers[index];

        return Padding(
          padding:
              const EdgeInsets.only(bottom: 12),

          child: DossierCard(
            dossier: dossier.toMap(),

            onTap: () {
              GoRouter.of(context).pushNamed(
                'dossier_detail',

                pathParameters: {
                  'id': dossier.id,
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),

          const SizedBox(height: 16),

          Text(
            _searchQuery.isNotEmpty
                ? '🔍 Aucun résultat'
                : '📭 Aucun dossier',

            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _searchQuery.isNotEmpty
                ? 'Essayez avec un autre terme de recherche'
                : 'Appuyez sur + pour créer un nouveau dossier',

            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,

      builder:
          (context) => AlertDialog(
            title:
                const Text('🔍 Rechercher'),

            content: TextField(
              controller: _searchController,

              autofocus: true,

              decoration:
                  const InputDecoration(
                    hintText:
                        'Nom ou numéro du dossier',

                    border:
                        OutlineInputBorder(),

                    prefixIcon:
                        Icon(Icons.search),
                  ),

              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value;
                });

                Navigator.pop(context);
              },
            ),

            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pop(context),

                child: const Text('Annuler'),
              ),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchQuery =
                        _searchController.text;
                  });

                  Navigator.pop(context);
                },

                child:
                    const Text('Rechercher'),
              ),
            ],
          ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,

      shape:
          const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
          ),

      builder:
          (context) => Padding(
            padding:
                const EdgeInsets.all(20),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                const Text(
                  '⚙️ Filtres',

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                const Align(
                  alignment:
                      Alignment.centerLeft,

                  child: Text(
                    '📌 Statut',

                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,

                  children: [
                    _buildFilterOption(
                      'Tous',
                      'all',
                    ),

                    _buildFilterOption(
                      'Actifs',
                      'active',
                    ),

                    _buildFilterOption(
                      'Transférés',
                      'transferred',
                    ),

                    _buildFilterOption(
                      'Archivés',
                      'archived',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Align(
                  alignment:
                      Alignment.centerLeft,

                  child: Text(
                    '👶 Type',

                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,

                  children: [
                    _buildTypeOption(
                      'Tous',
                      'all',
                    ),

                    _buildTypeOption(
                      'Prématurés',
                      'premature',
                    ),

                    _buildTypeOption(
                      'À terme',
                      'fullterm',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child:
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedFilter =
                                    'all';

                                _selectedType =
                                    'all';
                              });

                              Navigator.pop(
                                context,
                              );

                              _loadDossiers();
                            },

                            child: const Text(
                              '🔄 Réinitialiser',
                            ),
                          ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child:
                          ElevatedButton(
                            style:
                                ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.medicalBlue,
                                ),

                            onPressed: () {
                              Navigator.pop(
                                context,
                              );

                              _loadDossiers();
                            },

                            child: const Text(
                              '✅ Appliquer',
                            ),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildFilterOption(
    String label,
    String value,
  ) {
    final isSelected =
        _selectedFilter == value;

    return FilterChip(
      label: Text(label),

      selected: isSelected,

      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },

      backgroundColor:
          Colors.grey.shade100,

      selectedColor:
          AppColors.medicalBlue,
    );
  }

  Widget _buildTypeOption(
    String label,
    String value,
  ) {
    final isSelected =
        _selectedType == value;

    return FilterChip(
      label: Text(label),

      selected: isSelected,

      onSelected: (_) {
        setState(() {
          _selectedType = value;
        });
      },

      backgroundColor:
          Colors.grey.shade100,

      selectedColor:
          AppColors.medicalBlue,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}