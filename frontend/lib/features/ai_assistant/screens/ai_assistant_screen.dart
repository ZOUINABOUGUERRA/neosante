import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../providers/ai_provider.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? dossierData;
  final String? dossierId;

  const AIAssistantScreen({
    super.key,
    this.dossierData,
    this.dossierId,
  });

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final TextEditingController _questionController = TextEditingController();
  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _chatHistory = [];

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
    await ref.read(aiAssistantProvider.notifier).analyzeDossier(widget.dossierData!);
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
      // ✅ إزالة المتغير غير المستخدم fullPrompt
      // Build a prompt with context from the dossier if available directly in the call
      
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

  Future<String> _simulateAIResponse(String question, Map<String, dynamic>? dossierData) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Simple keyword-based responses for demo
    final lowerQuestion = question.toLowerCase();
    
    if (lowerQuestion.contains('glycémie') || lowerQuestion.contains('glucose')) {
      if (dossierData != null && dossierData['bloodGlucose'] != null) {
        final glucose = dossierData['bloodGlucose'];
        if (glucose < 40) {
          return '⚠️ ALERTE: La glycémie est critique (${glucose} mg/dL). Recommandation: Administrer G10 IV en bolus (2 mL/kg) et contrôler dans 30 minutes.';
        } else if (glucose < 45) {
          return '⚠️ Surveillance: Glycémie basse (${glucose} mg/dL). Recommandation: Alimentation entérale précoce et contrôle glycémique dans 1 heure.';
        } else if (glucose > 150) {
          return '⚠️ Attention: Hyperglycémie (${glucose} mg/dL). Recommandation: Réduire l\'apport glucosé et contrôler dans 2 heures.';
        } else {
          return '✅ Glycémie normale (${glucose} mg/dL). Poursuivre la surveillance habituelle.';
        }
      } else {
        return 'Pour évaluer la glycémie, je dois connaître la valeur mesurée. Une glycémie normale chez le nouveau-né se situe entre 45 et 150 mg/dL.';
      }
    }
    
    if (lowerQuestion.contains('température') || lowerQuestion.contains('temp')) {
      if (dossierData != null && dossierData['bodyTemperature'] != null) {
        final temp = dossierData['bodyTemperature'];
        if (temp < 32) {
          return '🔴 URGENCE: Hypothermie sévère (${temp}°C). Recommandation: Réchauffement immédiat en incubateur, surveillance rapprochée.';
        } else if (temp < 36) {
          return '🟠 Attention: Hypothermie (${temp}°C). Recommandation: Peau à peau ou incubateur, contrôle toutes les 30 minutes.';
        } else if (temp > 37.5) {
          return '🔴 Attention: Hyperthermie (${temp}°C). Recommandation: Évaluer risque infectieux, bilan si persistance.';
        } else {
          return '✅ Température normale (${temp}°C).';
        }
      } else {
        return 'La température normale du nouveau-né se situe entre 36°C et 37,5°C. Une hypothermie (<36°C) ou une hyperthermie (>37,5°C) nécessite une attention particulière.';
      }
    }
    
    if (lowerQuestion.contains('apgar')) {
      if (dossierData != null && dossierData['apgar1'] != null) {
        final apgar = dossierData['apgar1'];
        if (apgar < 3) {
          return '🔴 URGENCE: APGAR critique ($apgar/10). Recommandation: Réanimation immédiate, ventilation assistée.';
        } else if (apgar < 5) {
          return '🟠 Surveillance: APGAR bas ($apgar/10). Recommandation: Assistance respiratoire si besoin.';
        } else {
          return '✅ APGAR satisfaisant ($apgar/10).';
        }
      } else {
        return 'Le score d\'APGAR évalue 5 critères à 1 et 5 minutes: Couleur, Fréquence cardiaque, Réflexes, Tonus, Respiration. Un score <7 nécessite une surveillance.';
      }
    }
    
    if (lowerQuestion.contains('prématuré') || lowerQuestion.contains('premature')) {
      return 'La prématurité (<37 SA) nécessite une surveillance renforcée. Points clés:\n'
          '• Maintien de la température (incubateur)\n'
          '• Surveillance glycémique systématique\n'
          '• Prévention des infections\n'
          '• Alimentation adaptée (lait maternel enrichi si besoin)\n'
          '• Dépistage rétinopathie du prématuré si <32 SA';
    }
    
    if (lowerQuestion.contains('ictère') || lowerQuestion.contains('jaunisse')) {
      return 'L\'ictère néonatal est fréquent. Recommandations:\n'
          '• Surveillance de l\'extension (face → tronc → membres)\n'
          '• Bilirubine transcutanée si extension au tronc\n'
          '• Photothérapie si seuils atteints\n'
          '• Sévérité augmentée chez le prématuré';
    }
    
    // Default response
    return 'Je suis l\'assistant IA NéoSanté. Je peux vous aider à analyser:\n'
        '• Les résultats de glycémie\n'
        '• La température corporelle\n'
        '• Le score d\'APGAR\n'
        '• La prise en charge du prématuré\n'
        '• L\'ictère néonatal\n'
        '• Et d\'autres paramètres néonataux\n\n'
        'Posez-moi une question spécifique sur ce dossier médical.';
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiAssistantProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant IA Médical'),
        backgroundColor: Colors.transparent,
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
              const PopupMenuItem(value: 'clear', child: Text('Effacer l\'historique')),
            ],
          ),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout(aiState) : _buildMobileLayout(aiState),
    );
  }

  Widget _buildDesktopLayout(AIAssistantState state) {
    return Row(
      children: [
        // Left panel - Analysis
        Expanded(
          flex: 2,
          child: _buildAnalysisPanel(state),
        ),
        // Right panel - Chat / Questions
        Expanded(
          flex: 1,
          child: _buildChatPanel(),
        ),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
  gradient: LinearGradient(
    colors: [AppColors.medicalBlue, AppColors.lightBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.all(Radius.circular(16)),
),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assistant, size: 32, color: AppColors.medicalBlue),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assistant AI Médical',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Analyse assistée par IA (Claude API)',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child:const 
             Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '⚠️ L\'IA est un outil d\'ASSISTANCE uniquement.\nToute décision médicale reste sous la responsabilité du professionnel de santé.',
                    style: TextStyle(fontSize: 12),
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
            Text('Analyse en cours...'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Analysis Result
        if (state.hasAnalysis) ...[
          _buildSectionHeader('📊 Analyse clinique', Icons.analytics),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                state.analysisResult,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Risk Factors
        if (state.hasRiskFactors) ...[
          _buildSectionHeader('⚠️ Facteurs de risque identifiés', Icons.warning),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: state.riskFactors.map((risk) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: AppColors.warningOrange),
                      const SizedBox(width: 12),
                      Expanded(child: Text(risk)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Observation Suggestions
        if (state.hasSuggestions) ...[
          _buildSectionHeader('💡 Suggestions d\'observations', Icons.lightbulb),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: state.suggestions.map((suggestion) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 18, color: AppColors.stableGreen),
                      const SizedBox(width: 12),
                      Expanded(child: Text(suggestion)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // No data state
        if (!state.hasAnalysis && !state.hasSuggestions && !state.hasRiskFactors && !state.isLoading)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.assistant_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  widget.dossierData == null
                      ? 'Sélectionnez un dossier pour obtenir une analyse IA'
                      : 'Cliquez sur "Analyser" pour obtenir une évaluation',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (widget.dossierData != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton.icon(
                      onPressed: _analyzeCurrentDossier,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Analyser le dossier'),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChatPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
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
                  'Poser une question',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                        Text('L\'IA réfléchit...'),
                      ],
                    ),
                  );
                }
                
                final messageIndex = _isAnalyzing ? _chatHistory.length - 1 - (index - 1) : _chatHistory.length - 1 - index;
                if (messageIndex < 0 || messageIndex >= _chatHistory.length) return const SizedBox.shrink();
                
                final message = _chatHistory[messageIndex];
                final isUser = message['role'] == 'user';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.medicalBlue : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: !isUser ? Border.all(color: Colors.grey.shade200) : null,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            message['content'],
                            style: TextStyle(
                              color: isUser ? Colors.white : AppColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                    decoration: const InputDecoration(
                      hintText: 'Posez une question médicale...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _askCustomQuestion(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.medicalBlue,
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 18, color: Colors.white),
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
          Icon(icon, size: 20, color: AppColors.medicalBlue),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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