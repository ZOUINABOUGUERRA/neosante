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
exports.onTransferCompleted = exports.autoExpirePendingTransfers = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
// Auto-expire pending transfers after 7 days
exports.autoExpirePendingTransfers = functions.pubsub
    .schedule('0 4 * * *')
    .timeZone('Europe/Paris')
    .onRun(async (context) => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 7);
    const expiredTransfers = await db
        .collection('transfers')
        .where('status', '==', 'pending')
        .where('requestedAt', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
        .get();
    const batch = db.batch();
    for (const doc of expiredTransfers.docs) {
        batch.update(doc.ref, {
            status: 'rejected',
            rejectionReason: 'Expiré - aucune réponse sous 7 jours',
            respondedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Notify requester
        const transfer = doc.data();
        const notification = {
            userId: transfer.requestedBy,
            title: 'Transfert expiré',
            body: `Le transfert du dossier ${transfer.dossierNumber} a expiré (7 jours sans réponse)`,
            type: 'transfer_rejected',
            data: { transferId: doc.id, dossierId: transfer.dossierId },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        batch.set(db.collection('notifications').doc(), notification);
    }
    await batch.commit();
    console.log(`Expired ${expiredTransfers.docs.length} pending transfers`);
    return { expiredCount: expiredTransfers.docs.length };
});
// Update dossier status when transfer is completed
exports.onTransferCompleted = functions.firestore
    .document('transfers/{transferId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status !== 'completed' && after.status === 'completed') {
        // Update dossier status
        const dossierRef = db.collection('dossiers_prematures').doc(after.dossierId);
        const dossierDoc = await dossierRef.get();
        if (dossierDoc.exists) {
            await dossierRef.update({
                status: 'archived',
                transferCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        else {
            await db.collection('dossiers_a_terme').doc(after.dossierId).update({
                status: 'archived',
                transferCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    }
    return { success: true };
});
//# sourceMappingURL=index.js.map