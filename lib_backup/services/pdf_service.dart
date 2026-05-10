// frontend/lib/services/pdf_service.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

class PdfService {
  // ✅ إزالة const - استخدام static final بدلاً من static const
  static final PdfColor _primaryColor = PdfColor(43, 122, 120);
  // static final PdfColor _headerColor = PdfColor(51, 51, 51);

  /// Generate and save PDF
  static Future<File> generateAndSave(
      String dossierId, String dossierType) async {
    try {
      final pdf = await generateDossierPDF(dossierId, dossierType);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/dossier_$dossierId.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }

  /// Generate PDF and return as pw.Document
  static Future<pw.Document> generateDossierPDF(
      String dossierId, String dossierType) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(dossierType)
          .doc(dossierId)
          .get();

      if (!doc.exists) {
        throw Exception('Dossier non trouvé');
      }

      final data = doc.data()!;
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            _buildHeader(data),
            pw.SizedBox(height: 20),
            _buildPatientInfo(data),
            pw.SizedBox(height: 20),
            _buildBirthData(data),
            pw.SizedBox(height: 20),
            _buildFooter(dossierId),
          ],
        ),
      );

      return pdf;
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }

  /// Generate and share PDF
  static Future<void> generateAndShare(
      String dossierId, String dossierType) async {
    try {
      final file = await generateAndSave(dossierId, dossierType);
      await Printing.sharePdf(
        bytes: await file.readAsBytes(),
        filename: 'dossier_$dossierId.pdf',
      );
    } catch (e) {
      throw Exception('Erreur lors du partage du PDF: $e');
    }
  }

  /// Generate and print PDF
  static Future<void> generateAndPrint(
      String dossierId, String dossierType) async {
    try {
      final pdf = await generateDossierPDF(dossierId, dossierType);
      await Printing.layoutPdf(
        onLayout: (format) async => await pdf.save(),
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'impression du PDF: $e');
    }
  }

  static pw.Widget _buildHeader(Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            'NÉOSANTÉ',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'Système Intelligent de Néonatologie',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: _primaryColor, thickness: 2),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'FICHE MÉDICALE',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'N° Dossier: ${data['dossierNumber'] ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPatientInfo(Map<String, dynamic> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'IDENTIFICATION DU PATIENT',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
                color: _primaryColor),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildInfoColumn('Nouveau-né', data['newbornName'] ?? 'N/A'),
              _buildInfoColumn('Mère', data['motherName'] ?? 'N/A'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildInfoColumn(
                  'Date naissance', _formatDate(data['birthDateTime'])),
              _buildInfoColumn(
                  'Âge gestationnel', '${data['gestationalAge'] ?? '?'} SA'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBirthData(Map<String, dynamic> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DONNÉES À LA NAISSANCE',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
                color: _primaryColor),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildInfoColumn('Poids', '${data['birthWeight'] ?? '?'} g'),
              _buildInfoColumn(
                  'Température', '${data['bodyTemperature'] ?? '?'} °C'),
              _buildInfoColumn(
                  'Glycémie', '${data['bloodGlucose'] ?? '?'} mg/dL'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildInfoColumn('APGAR 1min', '${data['apgar1'] ?? '?'}/10'),
              _buildInfoColumn('APGAR 5min', '${data['apgar5'] ?? '?'}/10'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(String dossierId) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Document généré par NéoSanté',
                    style:
                        const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                pw.Text(
                    'Date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                    style:
                        const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              ],
            ),
            pw.Container(
              width: 80,
              height: 80,
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: dossierId,
                drawText: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInfoColumn(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  static String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (date is Timestamp) {
      final dt = date.toDate();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return date.toString();
  }
}
