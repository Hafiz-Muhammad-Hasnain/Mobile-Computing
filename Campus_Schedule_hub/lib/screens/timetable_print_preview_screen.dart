import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:typed_data';

class TimetablePrintPreviewScreen extends StatefulWidget {
  final pw.Document pdfDocument;
  final String semester;
  final String program;
  final String section;
  final Timestamp? latestUpdate;

  const TimetablePrintPreviewScreen({
    super.key,
    required this.pdfDocument,
    required this.semester,
    required this.program,
    required this.section,
    required this.latestUpdate,
  });

  @override
  State<TimetablePrintPreviewScreen> createState() =>
      _TimetablePrintPreviewScreenState();
}

class _TimetablePrintPreviewScreenState
    extends State<TimetablePrintPreviewScreen> {
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    final saved = await widget.pdfDocument.save();
    setState(() {
      _pdfBytes = saved;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        title: const Text('Print Timetable'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed:
                _pdfBytes == null
                    ? null
                    : () {
                      Printing.layoutPdf(onLayout: (format) => _pdfBytes!);
                    },
          ),
          IconButton(
            icon: const Icon(Icons.share), // Changed from download to share
            onPressed:
                _pdfBytes == null
                    ? null
                    : () async {
                      Printing.sharePdf(
                        bytes: _pdfBytes!,
                        filename:
                            'Timetable_${widget.semester}_${widget.program}_${widget.section}.pdf',
                      );
                    },
          ),
        ],
      ),
      body:
          _pdfBytes != null
              ? PdfPreview(
                build: (format) => _pdfBytes!,
                allowPrinting: false,
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SpinKitCircle(color: Colors.deepPurple, size: 50),
                    SizedBox(height: 16),
                    Text(
                      'Generating PDF...',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
