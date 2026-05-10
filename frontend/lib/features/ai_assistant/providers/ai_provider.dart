import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/ai_service.dart';
//import '../../../core/errors/failure.dart';

/// AI Assistant state class
class AIAssistantState {
  final String analysisResult;
  final List<String> suggestions;
  final List<String> riskFactors;
  final bool isLoading;
  final String? error;
  final String currentContext; // 'dossier', 'general', 'alert'

  const AIAssistantState({
    this.analysisResult = '',
    this.suggestions = const [],
    this.riskFactors = const [],
    this.isLoading = false,
    this.error = null,
    this.currentContext = 'general',
  });

  AIAssistantState copyWith({
    String? analysisResult,
    List<String>? suggestions,
    List<String>? riskFactors,
    bool? isLoading,
    String? error,
    String? currentContext,
  }) {
    return AIAssistantState(
      analysisResult: analysisResult ?? this.analysisResult,
      suggestions: suggestions ?? this.suggestions,
      riskFactors: riskFactors ?? this.riskFactors,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentContext: currentContext ?? this.currentContext,
    );
  }

  bool get hasAnalysis => analysisResult.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;
  bool get hasRiskFactors => riskFactors.isNotEmpty;
}

/// AI Assistant provider
final aiAssistantProvider = StateNotifierProvider<AIAssistantNotifier, AIAssistantState>((ref) {
  return AIAssistantNotifier();
});

/// AI Assistant notifier for managing AI interactions
class AIAssistantNotifier extends StateNotifier<AIAssistantState> {
  //final AIService _aiService = AIService();

  AIAssistantNotifier() : super(const AIAssistantState());

  /// Analyze a dossier and get medical insights
  Future<void> analyzeDossier(Map<String, dynamic> dossierData) async {
    state = state.copyWith(isLoading: true, error: null, currentContext: 'dossier');
    
    try {
      final analysis = await AIService.analyzeDossier(dossierData);
      final suggestions = await AIService.suggestObservations(dossierData);
      final riskFactors = await AIService.predictRiskFactors(dossierData);
      
      state = state.copyWith(
        analysisResult: analysis,
        suggestions: suggestions,
        riskFactors: riskFactors,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        analysisResult: 'Service AI temporairement indisponible. Veuillez réessayer plus tard.',
      );
    }
  }

  /// Generate a medical summary for a dossier
  Future<String> generateSummary(Map<String, dynamic> dossierData) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final summary = await AIService.generateSummary(dossierData);
      state = state.copyWith(
        analysisResult: summary,
        isLoading: false,
      );
      return summary;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return '';
    }
  }

  /// Get suggestions for observations
  Future<List<String>> getObservationSuggestions(Map<String, dynamic> dossierData) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final suggestions = await AIService.suggestObservations(dossierData);
      state = state.copyWith(suggestions: suggestions, isLoading: false);
      return suggestions;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get risk factor predictions
  Future<List<String>> getRiskFactors(Map<String, dynamic> dossierData) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final riskFactors = await AIService.predictRiskFactors(dossierData);
      state = state.copyWith(riskFactors: riskFactors, isLoading: false);
      return riskFactors;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Clear the current analysis
  void clearAnalysis() {
    state = const AIAssistantState();
  }

  /// Set current context
  void setContext(String context) {
    state = state.copyWith(currentContext: context);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for quick AI analysis (used in dossier detail)
final quickAnalysisProvider = FutureProvider.family<String, Map<String, dynamic>>((ref, dossierData) async {
  return await AIService.analyzeDossier(dossierData);
});

/// Provider for AI suggestions only
final aiSuggestionsProvider = FutureProvider.family<List<String>, Map<String, dynamic>>((ref, dossierData) async {
  return await AIService.suggestObservations(dossierData);
});

/// Provider for AI risk factors only
final aiRiskFactorsProvider = FutureProvider.family<List<String>, Map<String, dynamic>>((ref, dossierData) async {
  return await AIService.predictRiskFactors(dossierData);
});