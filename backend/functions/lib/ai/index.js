"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.analyzeDossier = exports.callClaudeAI = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
// Claude API configuration
// Note: In production, store API key in Firebase Secrets or Environment Config
const CLAUDE_API_KEY = functions.config().claude?.api_key || '';
const CLAUDE_API_URL = 'https://api.anthropic.com/v1/messages';
// Cloud Function to call Claude API (proxy to protect API key)
exports.callClaudeAI = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { prompt, maxTokens = 500, temperature = 0.7 } = data;
    if (!prompt) {
        throw new functions.https.HttpsError('invalid-argument', 'Prompt is required');
    }
    try {
        const response = await fetch(CLAUDE_API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-api-key': CLAUDE_API_KEY,
                'anthropic-version': '2023-06-01',
            },
            body: JSON.stringify({
                model: 'claude-3-sonnet-20240229',
                max_tokens: maxTokens,
                temperature: temperature,
                messages: [
                    {
                        role: 'user',
                        content: prompt,
                    },
                ],
            }),
        });
        const result = await response.json();
        if (!response.ok) {
            console.error('Claude API error:', result);
            throw new Error(result.error?.message || 'Claude API error');
        }
        // Log the AI interaction for audit
        await db.collection('ai_logs').add({
            userId: context.auth.uid,
            promptLength: prompt.length,
            responseLength: result.content?.[0]?.text?.length || 0,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            model: 'claude-3-sonnet',
        });
        return {
            analysis: result.content?.[0]?.text || 'Aucune analyse disponible',
            usage: result.usage,
        };
    }
    catch (error) {
        console.error('Claude API error:', error);
        throw new functions.https.HttpsError('internal', 'AI service unavailable');
    }
});
// Analyze dossier endpoint (convenience function)
exports.analyzeDossier = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { dossierId, dossierType } = data;
    if (!dossierId) {
        throw new functions.https.HttpsError('invalid-argument', 'Dossier ID is required');
    }
    // Fetch dossier data
    const collection = dossierType === 'premature' ? 'dossiers_prematures' : 'dossiers_a_terme';
    const dossierDoc = await db.collection(collection).doc(dossierId).get();
    if (!dossierDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Dossier not found');
    }
    const dossier = dossierDoc.data();
    // Build prompt
    const prompt = `
    En tant qu'assistant médical néonatal (IA d'assistance uniquement), analysez ce dossier:
    
    - Type: ${dossierType === 'premature' ? 'Prématuré' : 'À terme'}
    - Âge gestationnel: ${dossier?.gestationalAge || 'N/A'} SA
    - Poids naissance: ${dossier?.birthWeight || 'N/A'} g
    - Température: ${dossier?.bodyTemperature || 'N/A'} °C
    - Glycémie: ${dossier?.bloodGlucose || 'N/A'} mg/dL
    - APGAR 1min: ${dossier?.apgar1 || 'N/A'} | APGAR 5min: ${dossier?.apgar5 || 'N/A'}
    - Coloration: ${dossier?.coloration || 'N/A'}
    - Respiration: ${dossier?.respiration || 'N/A'}
    - Tonus: ${dossier?.tonus || 'N/A'}
    
    Fournissez:
    1. Résumé clinique concis
    2. Points de vigilance
    3. Recommandations générales
    
    Rappel: Vous êtes un assistant - toute décision médicale revient au professionnel.
  `;
    try {
        const response = await fetch(CLAUDE_API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-api-key': CLAUDE_API_KEY,
                'anthropic-version': '2023-06-01',
            },
            body: JSON.stringify({
                model: 'claude-3-haiku-20240307',
                max_tokens: 800,
                temperature: 0.5,
                messages: [{ role: 'user', content: prompt }],
            }),
        });
        const result = await response.json();
        await db.collection('ai_logs').add({
            userId: context.auth.uid,
            dossierId,
            analysisType: 'dossier_analysis',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {
            analysis: result.content?.[0]?.text || 'Analyse non disponible',
        };
    }
    catch (error) {
        console.error('Analysis error:', error);
        throw new functions.https.HttpsError('internal', 'Analysis failed');
    }
});
//# sourceMappingURL=index.js.map