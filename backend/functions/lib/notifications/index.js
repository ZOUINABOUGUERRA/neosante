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
exports.cleanupOldNotifications = exports.onTransferApproved = exports.onTransferRequest = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
// Send notification when transfer is requested
exports.onTransferRequest = functions.firestore
    .document('transfers/{transferId}')
    .onCreate(async (snap, context) => {
    const transfer = snap.data();
    const notification = {
        userId: transfer.requestedTo,
        title: 'Nouvelle demande de transfert',
        body: `Le dossier ${transfer.dossierNumber} (${transfer.newbornName}) demande un transfert vers votre service`,
        type: 'transfer_request',
        data: {
            transferId: snap.id,
            dossierId: transfer.dossierId,
            dossierNumber: transfer.dossierNumber,
        },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await db.collection('notifications').add(notification);
    return { success: true };
});
// Send notification when transfer is approved
exports.onTransferApproved = functions.firestore
    .document('transfers/{transferId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status !== 'approved' && after.status === 'approved') {
        const notification = {
            userId: after.requestedBy,
            title: 'Transfert approuvé',
            body: `Le transfert du dossier ${after.dossierNumber} a été approuvé. Vous pouvez accéder au dossier.`,
            type: 'transfer_approved',
            data: {
                transferId: context.params.transferId,
                dossierId: after.dossierId,
                dossierNumber: after.dossierNumber,
            },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await db.collection('notifications').add(notification);
    }
    if (before.status !== 'rejected' && after.status === 'rejected') {
        const notification = {
            userId: after.requestedBy,
            title: 'Transfert refusé',
            body: `Le transfert du dossier ${after.dossierNumber} a été refusé. Raison: ${after.rejectionReason || 'Non spécifiée'}`,
            type: 'transfer_rejected',
            data: {
                transferId: context.params.transferId,
                dossierId: after.dossierId,
            },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await db.collection('notifications').add(notification);
    }
    return { success: true };
});
// Clean up old notifications (older than 30 days) - runs daily
exports.cleanupOldNotifications = functions.pubsub
    .schedule('0 3 * * *')
    .timeZone('Europe/Paris')
    .onRun(async (context) => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 30);
    const oldNotifications = await db
        .collection('notifications')
        .where('createdAt', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
        .get();
    const batch = db.batch();
    oldNotifications.docs.forEach(doc => {
        batch.delete(doc.ref);
    });
    await batch.commit();
    console.log(`Cleaned up ${oldNotifications.docs.length} old notifications`);
    return { deletedCount: oldNotifications.docs.length };
});
//# sourceMappingURL=index.js.map