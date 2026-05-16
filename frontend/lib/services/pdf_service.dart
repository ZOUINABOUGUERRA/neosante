import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfService {
  static final PdfColor _primaryColor =
      const PdfColor.fromInt(0xFF2196F3);

  // ---------------- GENERATE ----------------

  static Future<pw.Document> generateDossierPDF(
    String dossierId,
    String dossierType,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(dossierType)
          .doc(dossierId)
          .get();

      if (!doc.exists) {
        throw Exception('Dossier non trouvé');
      }

      final data = doc.data() ?? {};
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
      throw Exception('Erreur PDF: $e');
    }
  }

  // ---------------- PRINT ----------------

  static Future<void> generateAndPrint(
    String dossierId,
    String dossierType,
  ) async {
    final pdf =
        await generateDossierPDF(dossierId, dossierType);

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // ---------------- SHARE ----------------

  static Future<void> generateAndShare(
    String dossierId,
    String dossierType,
  ) async {
    final pdf =
        await generateDossierPDF(dossierId, dossierType);

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'dossier_$dossierId.pdf',
    );
  }

  // ---------------- SAVE (FIXED) ----------------
  // 🚀 important: ما تستعملش print كـ save وهمي

  static Future<void> generateAndSave(
    String dossierId,
    String dossierType,
  ) async {
    final pdf =
        await generateDossierPDF(dossierId, dossierType);

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'dossier_$dossierId.pdf',
    );
  }

  // ================= HEADER =================

  static pw.Widget _buildHeader(
      Map<String, dynamic> data) {
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
            style: pw.TextStyle(
              fontSize: 12,
              color: _primaryColor,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: _primaryColor, thickness: 2),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'FICHE MÉDICALE',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
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

  // ================= PATIENT =================

  static pw.Widget _buildPatientInfo(
      Map<String, dynamic> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'IDENTIFICATION DU PATIENT',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Row(
            children: [
              _buildInfoColumn(
                'Nouveau-né',
                data['newbornName'] ?? 'N/A',
              ),
              _buildInfoColumn(
                'Mère',
                data['motherName'] ?? 'N/A',
              ),
            ],
          ),

          pw.SizedBox(height: 8),

          pw.Row(
            children: [
              _buildInfoColumn(
                'Naissance',
                _formatDate(
                    data['birthDateTime']),
              ),
              _buildInfoColumn(
                'Âge gestationnel',
                '${data['gestationalAge'] ?? '?'} SA',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= BIRTH DATA =================

  static pw.Widget _buildBirthData(
      Map<String, dynamic> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DONNÉES À LA NAISSANCE',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Row(
            children: [
              _buildInfoColumn(
                'Poids',
                '${data['birthWeight'] ?? '?'} g',
              ),
              _buildInfoColumn(
                'Température',
                '${data['bodyTemperature'] ?? '?'} °C',
              ),
              _buildInfoColumn(
                'Glycémie',
                '${data['bloodGlucose'] ?? '?'} mg/dL',
              ),
            ],
          ),

          pw.SizedBox(height: 8),

          pw.Row(
            children: [
              _buildInfoColumn(
                'APGAR 1min',
                '${data['apgar1'] ?? '?'}/10',
              ),
              _buildInfoColumn(
                'APGAR 5min',
                '${data['apgar5'] ?? '?'}/10',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= FOOTER =================

  static pw.Widget _buildFooter(
      String dossierId) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),

        pw.Row(
          mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Document généré par NéoSanté',
                  style: const pw.TextStyle(
                      fontSize: 8),
                ),
                pw.Text(
                  'Date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                  style: const pw.TextStyle(
                      fontSize: 8),
                ),
              ],
            ),

            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: dossierId,
              drawText: false,
              width: 60,
              height: 60,
            ),
          ],
        ),
      ],
    );
  }

  // ================= HELPERS =================

  static pw.Widget _buildInfoColumn(
    String label,
    String value,
  ) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: _primaryColor,
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  static String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    if (date is Timestamp) {
      final dt = date.toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    }

    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }

    return 'N/A';
  }
}