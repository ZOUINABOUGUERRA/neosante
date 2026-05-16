import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../providers/ai_provider.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? dossierData;
  final String? dossierId;

  const AIAssistantScreen({super.key, this.dossierData, this.dossierId});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final TextEditingController _questionController = TextEditingController();
  bool _isAnalyzing = false;
  final List<Map<String, dynamic>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    if (widget.dossierData != null) {
      _analyzeCurrentDossier();
    }
  }

  Future<void> _analyzeCurrentDossier() async {
    if (widget.dossierData == null) return;

    setState(() => _isAnalyzing = true);
    await ref
        .read(aiAssistantProvider.notifier)
        .analyzeDossier(widget.dossierData!);
    setState(() => _isAnalyzing = false);
  }

  Future<void> _askCustomQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _chatHistory.add({
        'role': 'user',
        'content': question,
        'timestamp': DateTime.now(),
      });
      _isAnalyzing = true;
    });

    try {
      final response = await _simulateAIResponse(question, widget.dossierData);

      setState(() {
        _chatHistory.add({
          'role': 'assistant',
          'content': response,
          'timestamp': DateTime.now(),
        });
        _questionController.clear();
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _chatHistory.add({
          'role': 'assistant',
          'content': 'Désolé, une erreur est survenue. Veuillez réessayer.',
          'timestamp': DateTime.now(),
          'isError': true,
        });
        _isAnalyzing = false;
      });
    }
  }

  Future<String> _simulateAIResponse(
    String question,
    Map<String, dynamic>? dossierData,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    final lowerQuestion = question.toLowerCase();

    if (lowerQuestion.contains('glycémie') ||
        lowerQuestion.contains('glucose')) {
      if (dossierData != null && dossierData['bloodGlucose'] != null) {
        final glucose = dossierData['bloodGlucose'];
        if (glucose < 40) {
          return '⚠️ **ALERTE CRITIQUE:** La glycémie est à $glucose mg/dL (<40).\n\n**Recommandation:** Administrer G10 IV en bolus (2 mL/kg) et contrôler dans 30 minutes.';
        } else if (glucose < 45) {
          return '⚠️ **Surveillance rapprochée:** Glycémie à $glucose mg/dL (40-45).\n\n**Recommandation:** Alimentation entérale précoce, contrôle dans 1 heure.';
        } else if (glucose > 150) {
          return '⚠️ **Attention:** Hyperglycémie à $glucose mg/dL (>150).\n\n**Recommandation:** Réduire l\'apport glucosé, contrôler dans 2 heures.';
        } else {
          return '✅ **Glycémie normale:** $glucose mg/dL (45-150).\n\nPoursuivre la surveillance habituelle.';
        }
      } else {
        return '📊 **À propos de la glycémie:**\n\nLa glycémie normale chez le nouveau-né se situe entre **45 et 150 mg/dL**.\n\n• <40 mg/dL: Hypoglycémie sévère\n• 40-45 mg/dL: Hypoglycémie modérée\n• >150 mg/dL: Hyperglycémie';
      }
    }

    if (lowerQuestion.contains('température') ||
        lowerQuestion.contains('temp')) {
      if (dossierData != null && dossierData['bodyTemperature'] != null) {
        final temp = dossierData['bodyTemperature'];
        if (temp < 32) {
          return '🔴 **URGENCE:** Hypothermie sévère ($temp°C).\n\n**Recommandation:** Réchauffement immédiat en incubateur, surveillance continue.';
        } else if (temp < 36) {
          return '🟠 **Attention:** Hypothermie ($temp°C).\n\n**Recommandation:** Peau à peau ou incubateur, contrôle toutes les 30 minutes.';
        } else if (temp > 37.5) {
          return '🔴 **Attention:** Hyperthermie ($temp°C).\n\n**Recommandation:** Évaluer risque infectieux, bilan si persistance.';
        } else {
          return '✅ **Température normale:** $temp°C (36-37.5°C).';
        }
      } else {
        return '🌡️ **Température normale du nouveau-né:** 36°C à 37.5°C\n\n• <36°C: Hypothermie\n• >37.5°C: Hyperthermie (risque infectieux)';
      }
    }

    if (lowerQuestion.contains('apgar')) {
      if (dossierData != null && dossierData['apgar1'] != null) {
        final apgar = dossierData['apgar1'];
        if (apgar < 3) {
          return '🔴 **URGENCE:** APGAR critique ($apgar/10).\n\n**Recommandation:** Réanimation immédiate, ventilation assistée.';
        } else if (apgar < 5) {
          return '🟠 **Surveillance:** APGAR bas ($apgar/10).\n\n**Recommandation:** Assistance respiratoire si besoin.';
        } else {
          return '✅ **APGAR satisfaisant:** $apgar/10.';
        }
      } else {
        return '📋 **Score d\'APGAR:** Évalue 5 critères à 1 et 5 minutes:\n\n1. **A**ppearance (Couleur)\n2. **P**ulse (FC)\n3. **G**rimace (Réflexes)\n4. **A**ctivity (Tonus)\n5. **R**espiration\n\nUn score <7 nécessite une surveillance.';
      }
    }

    if (lowerQuestion.contains('prématuré') ||
        lowerQuestion.contains('premature')) {
      return '👶 **Prise en charge du prématuré (<37 SA):**\n\n'
          '• **Température:** Maintien en incubateur\n'
          '• **Glycémie:** Surveillance systématique\n'
          '• **Infections:** Prévention renforcée\n'
          '• **Alimentation:** Lait maternel enrichi si besoin\n'
          '• **Dépistage:** Rétinopathie si <32 SA';
    }

    if (lowerQuestion.contains('ictère') ||
        lowerQuestion.contains('jaunisse')) {
      return '🟡 **Ictère néonatal - Recommandations:**\n\n'
          '• Surveillance de l\'extension (face → tronc → membres)\n'
          '• Bilirubine transcutanée si extension au tronc\n'
          '• Photothérapie si seuils atteints\n'
          '• Sévérité augmentée chez le prématuré';
    }

    return '🤖 **Assistant IA NéoSanté - Aide disponible**\n\nJe peux vous aider à analyser:\n\n'
        '• 🔬 Résultats de **glycémie**\n'
        '• 🌡️ **Température** corporelle\n'
        '• 📊 **Score d\'APGAR**\n'
        '• 👶 **Prématurité** et soins\n'
        '• 🟡 **Ictère** néonatal\n\n'
        'Posez-moi une question spécifique sur ce dossier médical.';
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiAssistantProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Assistant IA Médical'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (widget.dossierData != null) {
                _analyzeCurrentDossier();
              } else {
                ref.read(aiAssistantProvider.notifier).clearAnalysis();
              }
            },
            tooltip: 'Nouvelle analyse',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                ref.read(aiAssistantProvider.notifier).clearAnalysis();
                setState(() => _chatHistory.clear());
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 18),
                    SizedBox(width: 8),
                    Text('Effacer l\'historique'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isDesktop
          ? _buildDesktopLayout(aiState)
          : _buildMobileLayout(aiState),
    );
  }

  Widget _buildDesktopLayout(AIAssistantState state) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildAnalysisPanel(state)),
        Expanded(flex: 1, child: _buildChatPanel()),
      ],
    );
  }

  Widget _buildMobileLayout(AIAssistantState state) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppColors.medicalBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.medicalBlue,
            tabs: [
              Tab(icon: Icon(Icons.analytics), text: 'Analyse'),
              Tab(icon: Icon(Icons.chat), text: 'Questions'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildAnalysisContent(state),
                ),
                _buildChatPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisPanel(AIAssistantState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header avec design amélioré
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.medicalBlue, AppColors.lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assistant,
                    size: 32,
                    color: AppColors.medicalBlue,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assistant AI Médical',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Powered by Claude API',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ✅ Disclaimer amélioré
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1), // ✅ بديل shade50
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.2),
              ), // ✅ بديل shade200
            ),
            child: const Row(
              children: [
                Icon(Icons.medical_information, color: Colors.orange, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⚠️ L\'IA est un outil d\'ASSISTANCE uniquement.\nToute décision médicale reste sous la responsabilité du professionnel.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildAnalysisContent(state),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent(AIAssistantState state) {
    if (state.isLoading || _isAnalyzing) {
      return const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Analyse en cours...',
              style: TextStyle(color: AppColors.medicalBlue),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.hasAnalysis) ...[
          _buildSectionHeader('📊 Analyse clinique', Icons.analytics),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                state.analysisResult,
                style: const TextStyle(height: 1.6, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        if (state.hasRiskFactors) ...[
          _buildSectionHeader('⚠️ Facteurs de risque', Icons.warning),
          Container(
            decoration: BoxDecoration(
              color: AppColors.emergencyRed.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.emergencyRed.withValues(alpha: 0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: state.riskFactors
                    .map(
                      (risk) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 20,
                              color: AppColors.emergencyRed,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                risk,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        if (state.hasSuggestions) ...[
          _buildSectionHeader('💡 Suggestions', Icons.lightbulb),
          Container(
            decoration: BoxDecoration(
              color: AppColors.stableGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.stableGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: state.suggestions
                    .map(
                      (suggestion) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 20,
                              color: AppColors.stableGreen,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],

        if (!state.hasAnalysis &&
            !state.hasSuggestions &&
            !state.hasRiskFactors)
          _buildEmptyAnalysisCard(),
      ],
    );
  }

  Widget _buildEmptyAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.assistant_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            widget.dossierData == null
                ? 'Sélectionnez un dossier pour obtenir une analyse IA'
                : 'Cliquez sur "Analyser" pour obtenir une évaluation médicale',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          if (widget.dossierData != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton.icon(
                onPressed: _analyzeCurrentDossier,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Analyser le dossier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.medicalBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(left: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Row(
              children: [
                Icon(Icons.chat, color: AppColors.medicalBlue),
                SizedBox(width: 8),
                Text(
                  '💬 Questions médicales',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(width: 8),
                Text(
                  '(Assistant IA)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              reverse: true,
              itemCount: _chatHistory.length + (_isAnalyzing ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0 && _isAnalyzing) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(width: 12),
                        Text('🤔 L\'IA réfléchit...'),
                      ],
                    ),
                  );
                }

                final messageIndex = _isAnalyzing
                    ? _chatHistory.length - 1 - (index - 1)
                    : _chatHistory.length - 1 - index;

                if (messageIndex < 0 || messageIndex >= _chatHistory.length) {
                  return const SizedBox.shrink();
                }

                final message = _chatHistory[messageIndex];
                final isUser = message['role'] == 'user';
                final isError = message['isError'] == true;

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.medicalBlue
                          : (isError ? Colors.red.shade50 : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: !isUser
                          ? Border.all(color: Colors.grey.shade200)
                          : null,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          message['content'],
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : (isError ? Colors.red : AppColors.darkGray),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(message['timestamp']),
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Posez une question médicale...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _askCustomQuestion(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.medicalBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 20, color: Colors.white),
                    onPressed: _isAnalyzing ? null : _askCustomQuestion,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.medicalBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.medicalBlue),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }
}
