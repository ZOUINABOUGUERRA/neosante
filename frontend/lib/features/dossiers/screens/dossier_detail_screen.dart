import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../theme/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/pdf_service.dart';
import '../../../shared/extensions/context_ext.dart';

class DossierDetailScreen extends ConsumerStatefulWidget {
  final String dossierId;

  const DossierDetailScreen({
    super.key,
    required this.dossierId,
  });

  @override
  ConsumerState<DossierDetailScreen> createState() =>
      _DossierDetailScreenState();
}

class _DossierDetailScreenState
    extends ConsumerState<DossierDetailScreen> {
  Map<String, dynamic>? _dossierData;

  String _dossierType = '';

  bool _isLoading = true;

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadDossier();
  }

  // =========================
  // HELPERS
  // =========================

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  String _formatDate(dynamic value) {
    final parsedDate = _parseDate(value);

    if (parsedDate == null) {
      return 'N/A';
    }

    return DateFormat(
      'dd/MM/yyyy HH:mm',
      'fr_FR',
    ).format(parsedDate);
  }

  // =========================
  // LOAD DOSSIER
  // =========================

  Future<void> _loadDossier() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance
              .collection(
                AppConstants.dossiersPrematuresCollection,
              )
              .doc(widget.dossierId)
              .get();

      if (doc.exists) {
        _dossierType =
            AppConstants.dossiersPrematuresCollection;

        _dossierData = doc.data();

        if (_dossierData != null) {
          _dossierData!['id'] = doc.id;
        }
      } else {
        doc = await FirebaseFirestore.instance
            .collection(
              AppConstants.dossiersATermeCollection,
            )
            .doc(widget.dossierId)
            .get();

        if (doc.exists) {
          _dossierType =
              AppConstants.dossiersATermeCollection;

          _dossierData = doc.data();

          if (_dossierData != null) {
            _dossierData!['id'] = doc.id;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading dossier: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================
  // ARCHIVE DOSSIER
  // =========================

  Future<void> _archiveDossier() async {
    final confirmed =
        await context.showConfirmationDialog(
      title: '📦 Archiver le dossier',
      message:
          'Êtes-vous sûr de vouloir archiver ce dossier ?',
      confirmText: 'Archiver',
      confirmColor: AppColors.warningOrange,
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.archivesCollection)
          .doc(widget.dossierId)
          .set({
        ..._dossierData!,
        'archivedAt': FieldValue.serverTimestamp(),
        'originalCollection': _dossierType,
      });

      await FirebaseFirestore.instance
          .collection(_dossierType)
          .doc(widget.dossierId)
          .delete();

      if (mounted) {
        context.showSuccessSnackBar(
          '✅ Dossier archivé avec succès',
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          '❌ Erreur: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_dossierData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dossier non trouvé'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text('📭 Dossier introuvable'),
            ],
          ),
        ),
      );
    }

    final bool isPremature =
        _dossierData!['serviceType'] ==
            AppConstants.servicePremature;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                _dossierData!['newbornName'] ??
                    'Dossier médical',
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 8),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isPremature
                    ? Colors.purple
                    : AppColors.stableGreen,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                isPremature
                    ? 'Prématuré'
                    : 'À terme',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),

        backgroundColor: Colors.transparent,

        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
            ),
            tooltip: 'Exporter PDF',
            onPressed: () {
              PdfService.generateAndShare(
                widget.dossierId,
                _dossierType,
              );
            },
          ),

          if (_dossierData!['status'] !=
              AppConstants.dossierStatusArchived)
            IconButton(
              icon: const Icon(Icons.archive),
              tooltip: 'Archiver',
              onPressed: _archiveDossier,
            ),

          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partager',
            onPressed: () {
              PdfService.generateAndShare(
                widget.dossierId,
                _dossierType,
              );
            },
          ),
        ],
      ),

      body: DefaultTabController(
        length: 4,
        initialIndex: _selectedTab,
        child: Column(
          children: [
            // STATUS BAR
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 16,
              ),
              color: _getStatusColor(
                _dossierData!['status'],
              ).withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(
                      _dossierData!['status'],
                    ),
                    color: _getStatusColor(
                      _dossierData!['status'],
                    ),
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    _getStatusLabel(
                      _dossierData!['status'],
                    ),
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color: _getStatusColor(
                        _dossierData!['status'],
                      ),
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '🔢 N° ${_dossierData!['dossierNumber'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // TABS
            Container(
              color: Colors.white,
              child: TabBar(
                onTap: (index) {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                labelColor:
                    AppColors.medicalBlue,
                unselectedLabelColor:
                    Colors.grey,
                indicatorColor:
                    AppColors.medicalBlue,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.info),
                    text: '📋 Info',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.health_and_safety,
                    ),
                    text: '📊 Données',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.medical_services,
                    ),
                    text: '🔧 Soins',
                  ),
                  Tab(
                    icon: Icon(Icons.timeline),
                    text: '📈 Surveillance',
                  ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildInfoTab(),
                  _buildBirthDataTab(),
                  _buildCareTab(),
                  _buildSurveillanceTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // INFO TAB
  // =========================

  Widget _buildInfoTab() {
    final data = _dossierData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionCard(
            '👶 Nouveau-né',
            Icons.baby_changing_station,
            [
              _buildInfoRow(
                'Nom',
                data['newbornName'] ?? 'N/A',
              ),

              _buildInfoRow(
                'Date naissance',
                _formatDate(
                  data['birthDateTime'],
                ),
              ),

              _buildInfoRow(
                'Âge gestationnel',
                '${data['gestationalAge'] ?? '?'} SA',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            '👩 Mère',
            Icons.woman,
            [
              _buildInfoRow(
                'Nom',
                data['motherName'] ?? 'N/A',
              ),

              _buildInfoRow(
                'Mode d\'accouchement',
                data['deliveryMethod'] ??
                    'N/A',
              ),

              _buildInfoRow(
                'ATCD',
                data['atcd'] ?? 'Aucun',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            '📁 Métadonnées',
            Icons.folder,
            [
              _buildInfoRow(
                'Créé par',
                data['createdBy'] ?? 'N/A',
              ),

              _buildInfoRow(
                'Créé le',
                _formatDate(
                  data['createdAt'],
                ),
              ),

              _buildInfoRow(
                'Dernière mise à jour',
                _formatDate(
                  data['updatedAt'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // BIRTH DATA TAB
  // =========================

  Widget _buildBirthDataTab() {
    final data = _dossierData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionCard(
            '📏 Mensurations',
            Icons.straighten,
            [
              _buildInfoRow(
                'Poids de naissance',
                '${_parseDouble(data['birthWeight'])} g',
              ),

              _buildInfoRow(
                'Température',
                '${_parseDouble(data['bodyTemperature'])} °C',
              ),

              _buildInfoRow(
                'Glycémie',
                '${_parseDouble(data['bloodGlucose'])} mg/dL',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // CARE TAB
  // =========================

  Widget _buildCareTab() {
    final data = _dossierData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionCard(
            '🔧 Soins et gestes',
            Icons.medical_services,
            [
              _buildInfoRow(
                'Préchauffe',
                data['prechauffe'] == true
                    ? 'Oui'
                    : 'Non',
              ),

              _buildInfoRow(
                'Séchage',
                data['sechage'] == true
                    ? 'Oui'
                    : 'Non',
              ),

              _buildInfoRow(
                'Stimulation',
                data['stimulation'] == true
                    ? 'Oui'
                    : 'Non',
              ),

              _buildInfoRow(
                'Vitamine K',
                data['vitamineK'] == true
                    ? 'Oui'
                    : 'Non',
              ),

              _buildInfoRow(
                'Bracelet',
                data['bracelet'] == true
                    ? 'Oui'
                    : 'Non',
              ),

              _buildInfoRow(
                'Clampage',
                data['clampage'] ?? 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // SURVEILLANCE TAB
  // =========================

  Widget _buildSurveillanceTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(
            AppConstants
                .surveillanceCollection,
          )
          .where(
            'dossierId',
            isEqualTo: widget.dossierId,
          )
          .orderBy(
            'recordedAt',
            descending: true,
          )
          .snapshots(),

      builder: (
        context,
        AsyncSnapshot<QuerySnapshot>
            snapshot,
      ) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '❌ Erreur: ${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        final documents =
            snapshot.data!.docs;

        final glucose = documents
            .where(
              (d) => d['type'] == 'glucose',
            )
            .toList();

        final temps = documents
            .where(
              (d) =>
                  d['type'] == 'temperature',
            )
            .toList();

        return SingleChildScrollView(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSectionCard(
                '📈 Dernières mesures',
                Icons.timeline,
                [
                  if (glucose.isNotEmpty)
                    _buildInfoRow(
                      'Dernière glycémie',
                      '${glucose.first['value']} mg/dL',
                      subtitle: _formatDate(
                        glucose.first[
                            'recordedAt'],
                      ),
                    ),

                  if (temps.isNotEmpty)
                    _buildInfoRow(
                      'Dernière température',
                      '${temps.first['value']} °C',
                      subtitle: _formatDate(
                        temps.first[
                            'recordedAt'],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // UI HELPERS
  // =========================

  Widget _buildSectionCard(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color:
                      AppColors.medicalBlue,
                ),

                const SizedBox(width: 12),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    String? subtitle,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w500,
            ),
          ),

          if (subtitle != null)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 4,
              ),

              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // STATUS HELPERS
  // =========================

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return AppColors.stableGreen;

      case 'transferred':
        return AppColors.warningOrange;

      case 'archived':
        return Colors.grey;

      default:
        return AppColors.medicalBlue;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'active':
        return Icons.check_circle;

      case 'transferred':
        return Icons.swap_horiz;

      case 'archived':
        return Icons.archive;

      default:
        return Icons.info;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'active':
        return '📄 Dossier actif';

      case 'transferred':
        return '🚑 Transféré';

      case 'archived':
        return '📦 Archivé';

      default:
        return 'Statut inconnu';
    }
  }
}