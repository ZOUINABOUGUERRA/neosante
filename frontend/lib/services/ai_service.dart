import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/errors/failure.dart';

/// AI service for Claude API integration.
class AIService {
  static const String _functionUrl = 'https://us-central1-neosante.cloudfunctions.net/callClaudeAI';

  /// Vérifie si l'âge gestationnel indique une prématurité (< 37 SA)
  static bool _isPremature(dynamic gestationalAge) {
    if (gestationalAge == null) return false;
    final age = gestationalAge is int ? gestationalAge : int.tryParse(gestationalAge.toString());
    return age != null && age < 37;
  }

  /// Analyze neonatal dossier data and return medical insights
  static Future<String> analyzeDossier(Map<String, dynamic> dossierData) async {
    try {
      final prompt = _buildAnalysisPrompt(dossierData);
      
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'maxTokens': 500,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['analysis'] ?? 'Analyse non disponible';
      } else {
        return 'Service AI temporairement indisponible. Veuillez réessayer plus tard.';
      }
    } catch (e) {
      throw AIFailure(message: 'Erreur lors de l\'analyse IA: $e', originalError: e);
    }
  }

  /// Build analysis prompt for Claude
  static String _buildAnalysisPrompt(Map<String, dynamic> dossierData) {
    final gestationalAge = dossierData['gestationalAge'];
    final isPremature = _isPremature(gestationalAge);
    
    return '''
      Vous êtes l'assistant IA médical NéoSanté. Votre rôle est d'ASSISTER les professionnels de santé, jamais de les remplacer.
      
      Analysez ce dossier néonatal:
      
      IDENTIFICATION:
      - Type: ${dossierData['serviceType'] == 'premature' ? 'Prématuré' : 'À terme'}
      - Prématurité: ${isPremature ? 'Oui' : 'Non'} (${gestationalAge ?? '?'} SA)
      - Nouveau-né: ${dossierData['newbornName'] ?? 'N/A'}
      - Mère: ${dossierData['motherName'] ?? 'N/A'}
      
      DONNÉES NAISSANCE:
      - Poids: ${dossierData['birthWeight'] ?? '?'} g
      - Température: ${dossierData['bodyTemperature'] ?? '?'} °C
      - Glycémie: ${dossierData['bloodGlucose'] ?? '?'} mg/dL
      - APGAR 1min: ${dossierData['apgar1'] ?? '?'} | APGAR 5min: ${dossierData['apgar5'] ?? '?'}
      - Coloration: ${dossierData['coloration'] ?? 'N/A'}
      - Respiration: ${dossierData['respiration'] ?? 'N/A'}
      - Tonus: ${dossierData['tonus'] ?? 'N/A'}
      - Malformations: ${dossierData['malformations'] ?? 'Aucune signalée'}
      
      Veuillez fournir:
      1. Résumé clinique concis (2-3 phrases)
      2. Points de vigilance (max 3)
      3. Recommandations générales (max 2, non contraignantes)
      
      Format de réponse: texte simple, pas de markdown.
      Rappel: Vous êtes un assistant - toute décision médicale revient au professionnel.
    ''';
  }

  /// Generate a medical summary for a dossier
  static Future<String> generateSummary(Map<String, dynamic> dossierData) async {
    try {
      final prompt = '''
        En tant qu'assistant médical néonatal, générez un résumé clinique concis pour ce dossier:
        
        Nouveau-né: ${dossierData['newbornName']}
        Âge gestationnel: ${dossierData['gestationalAge']} SA
        Poids naissance: ${dossierData['birthWeight']} g
        APGAR: ${dossierData['apgar1']}/10 à 1 min, ${dossierData['apgar5']}/10 à 5 min
        Glycémie: ${dossierData['bloodGlucose']} mg/dL
        Température: ${dossierData['bodyTemperature']} °C
        
        Points d'attention: ${dossierData['malformations'] ?? 'Aucun'}
        
        Rédigez un résumé professionnel de 2-3 phrases. Ne donnez PAS de diagnostic définitif.
      ''';
      
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'maxTokens': 300,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['analysis'] ?? 'Résumé non disponible';
      }
      return 'Résumé temporairement indisponible';
    } catch (e) {
      return 'Service AI indisponible. Résumé généré automatiquement.';
    }
  }

  /// Suggest observations based on patient data
  static Future<List<String>> suggestObservations(Map<String, dynamic> dossierData) async {
    try {
      final prompt = '''
        Basé sur les données néonatales suivantes, suggérez des observations cliniques pertinentes:
        
        - Âge gestationnel: ${dossierData['gestationalAge']} SA
        - Poids: ${dossierData['birthWeight']} g
        - Glycémie: ${dossierData['bloodGlucose']} mg/dL
        - Température: ${dossierData['bodyTemperature']} °C
        
        Proposez 3 observations courtes que la sage-femme pourrait noter.
      ''';
      
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'maxTokens': 200,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['analysis'] as String;
        return text.split('\n').where((l) => l.trim().isNotEmpty).toList();
      }
      return _getDefaultSuggestions(dossierData);
    } catch (e) {
      return _getDefaultSuggestions(dossierData);
    }
  }

  /// Predict potential complications based on risk factors
  static Future<List<String>> predictRiskFactors(Map<String, dynamic> dossierData) async {
    try {
      final gestationalAge = dossierData['gestationalAge'] as int? ?? 0;
      final isPremature = gestationalAge < 37;
      
      final prompt = '''
        En tant qu'outil d'aide à la décision (NE REMPLACE PAS LE JUGEMENT MÉDICAL),
        identifiez les facteurs de risque potentiels pour ce nouveau-né:
        
        - Prématurité: ${isPremature ? 'Oui' : 'Non'} ($gestationalAge SA)
        - Poids naissance: ${dossierData['birthWeight']} g
        - APGAR 1min: ${dossierData['apgar1']}
        - Glycémie: ${dossierData['bloodGlucose']} mg/dL
        
        Listez jusqu'à 3 risques potentiels (ex: hypoglycémie, hypothermie, détresse respiratoire).
      ''';
      
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'maxTokens': 250,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['analysis'] as String;
        return text.split('\n').where((l) => l.trim().isNotEmpty).toList();
      }
      return _getDefaultRiskFactors(dossierData);
    } catch (e) {
      return _getDefaultRiskFactors(dossierData);
    }
  }

  /// Default suggestions fallback when AI is unavailable
  static List<String> _getDefaultSuggestions(Map<String, dynamic> dossierData) {
    final suggestions = <String>[];
    
    final glucose = dossierData['bloodGlucose'] as double?;
    if (glucose != null && glucose < 45) {
      suggestions.add('Surveillance glycémique rapprochée');
    }
    
    final temp = dossierData['bodyTemperature'] as double?;
    if (temp != null && temp < 36.0) {
      suggestions.add('Patient hypotherme - réchauffement nécessaire');
    }
    
    suggestions.add('Surveillance des signes vitaux toutes les 4 heures');
    suggestions.add('Observer alimentation et élimination');
    
    return suggestions;
  }

  /// Default risk factors fallback
  static List<String> _getDefaultRiskFactors(Map<String, dynamic> dossierData) {
    final risks = <String>[];
    
    final gestationalAge = dossierData['gestationalAge'] as int?;
    if (gestationalAge != null && gestationalAge < 37) {
      risks.add('Risque lié à la prématurité (immaturité organique)');
    }
    
    final glucose = dossierData['bloodGlucose'] as double?;
    if (glucose != null && glucose < 45) {
      risks.add('Risque d\'hypoglycémie néonatale');
    }
    
    final weight = dossierData['birthWeight'] as double?;
    if (weight != null && weight < 2500) {
      risks.add('Hypotrophie - risque métabolique');
    }
    
    if (risks.isEmpty) {
      risks.add('Aucun facteur de risque majeur identifié');
    }
    
    return risks;
  }
}