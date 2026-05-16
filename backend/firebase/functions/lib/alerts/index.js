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
exports.evaluateMedicalAlertsFullTerm = exports.evaluateMedicalAlerts = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
// ✅ تأكد من تهيئة admin
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
// Alert thresholds
const THRESHOLDS = {
    GLUCOSE: { CRITICAL: 40, WARNING: 45, HIGH: 150 },
    TEMPERATURE: { EMERGENCY: 32, HYPOTHERMIA: 36, FEVER: 37.5 },
    APGAR: { CRITICAL: 3, WARNING: 6 }
};
// Trigger when a dossier is created or updated
exports.evaluateMedicalAlerts = functions.firestore
    .document('dossiers_prematures/{dossierId}')
    .onWrite(async (change, context) => {
    const dossierData = change.after.exists ? change.after.data() : null;
    if (!dossierData)
        return null;
    const dossierId = context.params.dossierId;
    const alerts = await generateAlerts(dossierData, dossierId);
    // Save alerts to Firestore
    const batch = db.batch();
    const alertIds = [];
    for (const alert of alerts) {
        const alertRef = db.collection('alerts').doc();
        alertIds.push(alertRef.id);
        batch.set(alertRef, { ...alert, id: alertRef.id });
    }
    // Update dossier with highest severity
    const highestSeverity = getHighestSeverity(alerts);
    if (highestSeverity) {
        batch.update(change.after.ref, { alertSeverity: highestSeverity });
    }
    await batch.commit();
    // Send push notifications for critical alerts
    // ✅ تمرير alertIds مع الإشعارات
    for (let i = 0; i < alerts.length; i++) {
        if (alerts[i].severity === 'critical') {
            await sendCriticalAlertNotification(alerts[i], dossierData, alertIds[i]);
        }
    }
    return { alertsGenerated: alerts.length };
});
// Same for full-term dossiers
exports.evaluateMedicalAlertsFullTerm = functions.firestore
    .document('dossiers_a_terme/{dossierId}')
    .onWrite(async (change, context) => {
    const dossierData = change.after.exists ? change.after.data() : null;
    if (!dossierData)
        return null;
    const dossierId = context.params.dossierId;
    const alerts = await generateAlerts(dossierData, dossierId);
    const batch = db.batch();
    const alertIds = [];
    for (const alert of alerts) {
        const alertRef = db.collection('alerts').doc();
        alertIds.push(alertRef.id);
        batch.set(alertRef, { ...alert, id: alertRef.id });
    }
    const highestSeverity = getHighestSeverity(alerts);
    if (highestSeverity) {
        batch.update(change.after.ref, { alertSeverity: highestSeverity });
    }
    await batch.commit();
    for (let i = 0; i < alerts.length; i++) {
        if (alerts[i].severity === 'critical') {
            await sendCriticalAlertNotification(alerts[i], dossierData, alertIds[i]);
        }
    }
    return { alertsGenerated: alerts.length };
});
async function generateAlerts(dossierData, dossierId) {
    const alerts = [];
    // Check glucose
    const glucose = dossierData.bloodGlucose;
    if (glucose !== null && glucose !== undefined) {
        if (glucose < THRESHOLDS.GLUCOSE.CRITICAL) {
            alerts.push(createAlert(dossierId, dossierData, 'glucose', glucose, 'critical', `🔴 GLUCOSE CRITIQUE: ${glucose} mg/dL - Urgence immédiate`));
        }
        else if (glucose < THRESHOLDS.GLUCOSE.WARNING) {
            alerts.push(createAlert(dossierId, dossierData, 'glucose', glucose, 'warning', `🟠 GLUCOSE BASSE: ${glucose} mg/dL - Surveillance rapprochée`));
        }
        else if (glucose > THRESHOLDS.GLUCOSE.HIGH) {
            alerts.push(createAlert(dossierId, dossierData, 'glucose', glucose, 'medium', `🟡 GLUCOSE ÉLEVÉE: ${glucose} mg/dL - Contrôle nécessaire`));
        }
    }
    // Check temperature
    const temp = dossierData.bodyTemperature;
    if (temp !== null && temp !== undefined) {
        if (temp < THRESHOLDS.TEMPERATURE.EMERGENCY) {
            alerts.push(createAlert(dossierId, dossierData, 'temperature', temp, 'critical', `🔴 TEMPÉRATURE CRITIQUE: ${temp}°C - Hypothermie sévère`));
        }
        else if (temp < THRESHOLDS.TEMPERATURE.HYPOTHERMIA) {
            alerts.push(createAlert(dossierId, dossierData, 'temperature', temp, 'warning', `🟠 HYPOTHERMIE: ${temp}°C - Réchauffement nécessaire`));
        }
        else if (temp > THRESHOLDS.TEMPERATURE.FEVER) {
            alerts.push(createAlert(dossierId, dossierData, 'temperature', temp, 'critical', `🔴 RISQUE INFECTIEUX: ${temp}°C - Évaluation urgente`));
        }
    }
    // Check APGAR
    const apgar = dossierData.apgar1;
    if (apgar !== null && apgar !== undefined) {
        if (apgar < THRESHOLDS.APGAR.CRITICAL) {
            alerts.push(createAlert(dossierId, dossierData, 'apgar', apgar, 'critical', `🔴 APGAR CRITIQUE: ${apgar}/10 - Réanimation immédiate`));
        }
        else if (apgar < THRESHOLDS.APGAR.WARNING) {
            alerts.push(createAlert(dossierId, dossierData, 'apgar', apgar, 'warning', `🟠 APGAR BAS: ${apgar}/10 - Surveillance étroite`));
        }
    }
    // Check respiration
    if (dossierData.respiration === 'absente') {
        alerts.push(createAlert(dossierId, dossierData, 'respiration', dossierData.respiration, 'critical', '🔴 RESPIRATION ABSENTE - Réanimation immédiate'));
    }
    else if (dossierData.respiration === 'faible irrégulière') {
        alerts.push(createAlert(dossierId, dossierData, 'respiration', dossierData.respiration, 'warning', '🟠 RESPIRATION FAIBLE/IRRÉGULIÈRE - Assistance respiratoire'));
    }
    // Check cry
    if (dossierData.cry === 'absent') {
        alerts.push(createAlert(dossierId, dossierData, 'cri', dossierData.cry, 'critical', '🔴 CRI ABSENT - Réanimation respiratoire'));
    }
    // Check tonus
    if (dossierData.tonus === 'flasque') {
        alerts.push(createAlert(dossierId, dossierData, 'tonus', dossierData.tonus, 'warning', '🟠 TONUS FLASQUE - Évaluation neurologique urgente'));
    }
    return alerts;
}
function createAlert(dossierId, dossierData, parameter, value, severity, message) {
    return {
        dossierId,
        dossierNumber: dossierData.dossierNumber || '',
        newbornName: dossierData.newbornName || '',
        parameter,
        value,
        severity,
        message,
        isRead: false,
        isAcknowledged: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
}
function getHighestSeverity(alerts) {
    const severities = alerts.map(a => a.severity);
    if (severities.includes('critical'))
        return 'critical';
    if (severities.includes('warning'))
        return 'warning';
    if (severities.includes('medium'))
        return 'medium';
    return null;
}
async function sendCriticalAlertNotification(alert, dossierData, alertId) {
    const usersSnapshot = await db
        .collection('users')
        .where('role', 'in', ['admin', 'sage-femme'])
        .get();
    const batch = db.batch();
    for (const userDoc of usersSnapshot.docs) {
        const notificationRef = db.collection('notifications').doc();
        batch.set(notificationRef, {
            userId: userDoc.id,
            title: '🚨 ALERTE CRITIQUE',
            body: `${dossierData.newbornName || 'Nouveau-né'}: ${alert.message}`,
            type: 'emergency_alert',
            data: { dossierId: alert.dossierId, alertId: alertId },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    await batch.commit();
}
//# sourceMappingURL=index.js.map