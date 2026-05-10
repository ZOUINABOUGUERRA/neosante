// frontend/lib/shared/widgets/pdf_viewer.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../theme/colors.dart';

/// PDF Viewer widget for displaying PDF files
class PdfViewer extends StatefulWidget {
  final String pdfUrl;
  final String? title;
  final bool showShareButton;
  final bool showPrintButton;
  final bool showDownloadButton;

  const PdfViewer({
    super.key,
    required this.pdfUrl,
    this.title,
    this.showShareButton = true,
    this.showPrintButton = true,
    this.showDownloadButton = true,
  });

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  bool _isLoading = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Document PDF'),
        backgroundColor: Colors.transparent,
        actions: _buildActions(),
      ),
      body: _buildBody(),
    );
  }

  List<Widget> _buildActions() {
    final List<Widget> actions = [];

    if (widget.showPrintButton) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.print),
          onPressed: _printPdf,
          tooltip: 'Imprimer',
        ),
      );
    }

    if (widget.showShareButton) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _sharePdf,
          tooltip: 'Partager',
        ),
      );
    }

    if (widget.showDownloadButton) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _downloadPdf,
          tooltip: 'Télécharger',
        ),
      );
    }

    return actions;
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.emergencyRed,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PdfPreview(
          canChangePageFormat: true,
          canChangeOrientation: true,
          canDebug: false,
          // ✅ إزالة maxScaleWidth (غير مدعوم)
          build: (format) async {
            setState(() => _isLoading = false);
            final pdfBytes = await _loadPdf();
            return pdfBytes;
          },
          pdfFileName: widget.title?.replaceAll(' ', '_') ?? 'document.pdf',
        ),
        if (_isLoading)
          Container(
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  // ✅ إصلاح: إضافة نوع Uint8List والاستيراد المناسب
  Future<Uint8List> _loadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to load PDF: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Erreur lors du chargement du PDF: $e');
      return Uint8List(0);
    }
  }

  Future<void> _printPdf() async {
    try {
      final pdfBytes = await _loadPdf();
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: widget.title ?? 'Document',
      );
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'impression: $e');
    }
  }

  Future<void> _sharePdf() async {
    try {
      final pdfBytes = await _loadPdf();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: widget.title?.replaceAll(' ', '_') ?? 'document.pdf',
      );
    } catch (e) {
      _showErrorSnackBar('Erreur lors du partage: $e');
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Impossible d\'accéder au dossier de téléchargement');
      }

      final pdfBytes = await _loadPdf();
      final fileName = widget.title?.replaceAll(' ', '_') ?? 'document.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      _showSuccessSnackBar('PDF téléchargé avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur lors du téléchargement: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.emergencyRed,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.stableGreen,
      ),
    );
  }
}

/// Simple PDF viewer with minimal UI
class SimplePdfViewer extends StatelessWidget {
  final String pdfUrl;
  final double height;

  const SimplePdfViewer({
    super.key,
    required this.pdfUrl,
    this.height = 400,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PdfPreview(
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        build: (format) async {
          // ✅ إصلاح: استخدام http.get بدلاً من HttpClient
          final response = await http.get(Uri.parse(pdfUrl));
          if (response.statusCode == 200) {
            return response.bodyBytes;
          } else {
            throw Exception('Failed to load PDF');
          }
        },
      ),
    );
  }
}

/// PDF thumbnail preview
class PdfThumbnail extends StatelessWidget {
  final String pdfUrl;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const PdfThumbnail({
    super.key,
    required this.pdfUrl,
    this.width = 120,
    this.height = 160,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child:const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 48,
              color: AppColors.emergencyRed,
            ),
            const SizedBox(height: 8),
            const Text(
              'PDF',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// PDF viewer dialog
Future<void> showPdfViewerDialog(
  BuildContext context,
  String pdfUrl, {
  String? title,
}) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            AppBar(
              title: Text(title ?? 'Document PDF'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: SimplePdfViewer(pdfUrl: pdfUrl),
            ),
          ],
        ),
      ),
    ),
  );
}