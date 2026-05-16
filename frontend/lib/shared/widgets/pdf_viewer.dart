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
        title: Text(widget.title ?? '📄 Document PDF'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          icon: const Icon(Icons.print_rounded),
          onPressed: _printPdf,
          tooltip: 'Imprimer',
        ),
      );
    }

    if (widget.showShareButton) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: _sharePdf,
          tooltip: 'Partager',
        ),
      );
    }

    if (widget.showDownloadButton) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.download_rounded),
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
              Icons.error_outline_rounded,
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
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('🔄 Réessayer'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
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
          // ✅ تم إزالة maxScaleWidth لأنها غير مدعومة
          build: (format) async {
            setState(() => _isLoading = false);
            return await _loadPdf();
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

  Future<Uint8List> _loadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to load PDF: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = '❌ Erreur lors du chargement du PDF: $e');
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
      _showErrorSnackBar('❌ Erreur lors de l\'impression: $e');
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
      _showErrorSnackBar('❌ Erreur lors du partage: $e');
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

      _showSuccessSnackBar('✅ PDF téléchargé avec succès');
    } catch (e) {
      _showErrorSnackBar('❌ Erreur lors du téléchargement: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.emergencyRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.stableGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 48,
              color: AppColors.emergencyRed,
            ),
            SizedBox(height: 8),
            Text(
              '📄 PDF',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            AppBar(
              title: Text(title ?? '📄 Document PDF'),
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
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