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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateDossierPDF = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const pdfkit_1 = __importDefault(require("pdfkit"));
const os = __importStar(require("os"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const db = admin.firestore();
const bucket = admin.storage().bucket();
// Generate PDF for a dossier
exports.generateDossierPDF = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { dossierId, dossierType } = data;
    if (!dossierId || !dossierType) {
        throw new functions.https.HttpsError('invalid-argument', 'Dossier ID and type are required');
    }
    // Fetch dossier data
    const dossierDoc = await db.collection(dossierType).doc(dossierId).get();
    if (!dossierDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Dossier not found');
    }
    const dossier = dossierDoc.data();
    // Create PDF
    const doc = new pdfkit_1.default({ margin: 50, size: 'A4' });
    const tempFilePath = path.join(os.tmpdir(), `dossier_${dossierId}.pdf`);
    const writeStream = fs.createWriteStream(tempFilePath);
    doc.pipe(writeStream);
    // Header
    doc.fontSize(24).font('Helvetica-Bold').text('NÉOSANTÉ', { align: 'center' });
    doc.fontSize(12).font('Helvetica').text('Système Intelligent de Néonatologie', { align: 'center' });
    doc.moveDown();
    doc.strokeColor('#2B7A78').lineWidth(2).moveTo(50, doc.y).lineTo(550, doc.y).stroke();
    doc.moveDown();
    doc.fontSize(18).font('Helvetica-Bold').text('FICHE MÉDICALE', { align: 'center' });
    doc.fontSize(10).font('Helvetica').text(`N° Dossier: ${dossier?.dossierNumber || 'N/A'}`, { align: 'center' });
    doc.moveDown();
    // Patient Information
    addSection(doc, 'IDENTIFICATION DU PATIENT');
    addField(doc, 'Nouveau-né', dossier?.newbornName || 'N/A');
    addField(doc, 'Mère', dossier?.motherName || 'N/A');
    addField(doc, 'Date naissance', formatDate(dossier?.birthDateTime));
    addField(doc, 'Âge gestationnel', `${dossier?.gestationalAge || '?'} SA`);
    doc.moveDown();
    // Birth Data
    addSection(doc, 'DONNÉES À LA NAISSANCE');
    addField(doc, 'Poids', `${dossier?.birthWeight || '?'} g`);
    addField(doc, 'Température', `${dossier?.bodyTemperature || '?'} °C`);
    addField(doc, 'Glycémie', `${dossier?.bloodGlucose || '?'} mg/dL`);
    addField(doc, 'APGAR 1min', `${dossier?.apgar1 || '?'}/10`);
    addField(doc, 'APGAR 5min', `${dossier?.apgar5 || '?'}/10`);
    addField(doc, 'Coloration', dossier?.coloration || 'N/A');
    addField(doc, 'Respiration', dossier?.respiration || 'N/A');
    addField(doc, 'Tonus', dossier?.tonus || 'N/A');
    doc.moveDown();
    // Systematic Gestures
    addSection(doc, 'GESTES SYSTÉMATIQUES');
    addCheckField(doc, 'Préchauffé', dossier?.prechauffe);
    addCheckField(doc, 'Séchage', dossier?.sechage);
    addCheckField(doc, 'Stimulation', dossier?.stimulation);
    addField(doc, 'Clampage', dossier?.clampage || 'N/A');
    addCheckField(doc, 'Vitamine K', dossier?.vitamineK);
    addCheckField(doc, 'Bracelet', dossier?.bracelet);
    addField(doc, 'Mise sous chaleur', dossier?.miseSousChaleur || 'N/A');
    doc.moveDown();
    // Resuscitation
    addSection(doc, 'RÉANIMATION');
    addField(doc, 'Airway', dossier?.airway || 'N/A');
    if (dossier?.breathing)
        addField(doc, 'Breathing', dossier.breathing);
    if (dossier?.circulation)
        addField(doc, 'Circulation', dossier.circulation);
    if (dossier?.disabilityMedications)
        addField(doc, 'Médicaments', dossier.disabilityMedications);
    doc.moveDown();
    // Footer
    doc.fontSize(10).font('Helvetica');
    doc.text(`Document généré par NéoSanté - ${new Date().toLocaleDateString('fr-FR')}`, 50, doc.y + 20);
    // QR Code placeholder
    doc.rect(470, doc.y - 40, 80, 80).stroke();
    doc.fontSize(8).text('QR Code', 500, doc.y - 20, { align: 'center' });
    // Finalize PDF
    doc.end();
    await new Promise((resolve) => writeStream.on('finish', resolve));
    // Upload to Cloud Storage
    const fileName = `pdfs/${dossierId}_${Date.now()}.pdf`;
    await bucket.upload(tempFilePath, {
        destination: fileName,
        metadata: {
            contentType: 'application/pdf',
            metadata: {
                dossierId,
                generatedBy: context.auth.uid,
                generatedAt: new Date().toISOString(),
            },
        },
    });
    // Get download URL
    const file = bucket.file(fileName);
    const [url] = await file.getSignedUrl({
        action: 'read',
        expires: Date.now() + 7 * 24 * 60 * 60 * 1000,
    });
    // Clean up temp file
    fs.unlinkSync(tempFilePath);
    return { pdfUrl: url, fileName };
});
function addSection(doc, title) {
    doc.moveDown();
    doc.fontSize(14).font('Helvetica-Bold').fillColor('#2B7A78').text(title);
    doc.fontSize(10).font('Helvetica').fillColor('#000000');
    doc.moveDown(0.5);
}
function addField(doc, label, value) {
    doc.font('Helvetica-Bold').text(`${label}: `, { continued: true });
    doc.font('Helvetica').text(value);
}
function addCheckField(doc, label, value) {
    const checkmark = value ? '✓' : '□';
    doc.font('Helvetica').text(`${checkmark} ${label}`);
}
function formatDate(timestamp) {
    if (!timestamp)
        return 'N/A';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString('fr-FR');
}
//# sourceMappingURL=index.js.map