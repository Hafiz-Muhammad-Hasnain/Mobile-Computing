import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'timetable_print_preview_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class StudentTimetableScreen extends StatelessWidget {
  final String semester;
  final String program;
  final String section;

  const StudentTimetableScreen({
    super.key,
    required this.semester,
    required this.program,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('timetable_data')
              .where('semester', isEqualTo: semester)
              .where('program', isEqualTo: program)
              .where('sec', isEqualTo: section)
              .get(),
      builder: (context, snapshot) {
        final appBarTitle = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 24,
              child: Text(
                '$program | $semester Sec-$section',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.docs.isNotEmpty)
              _buildLatestUpdate(snapshot.data!.docs),
          ],
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFF3E5F5),
            appBar: AppBar(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              title: appBarTitle,
            ),
            body: const Center(
              child: SpinKitCircle(color: Colors.deepPurple, size: 60.0),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFF3E5F5),
            appBar: AppBar(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              title: appBarTitle,
            ),
            body: const Center(child: Text('No timetable data found.')),
          );
        }

        final docs = snapshot.data!.docs;

        return _TimetableContent(
          semester: semester,
          program: program,
          section: section,
          docs: docs,
        );
      },
    );
  }

  Widget _buildLatestUpdate(List<QueryDocumentSnapshot> docs) {
    Timestamp? latestUpdate;
    for (var doc in docs) {
      final ts = doc['last_updated'];
      if (ts is Timestamp) {
        if (latestUpdate == null ||
            ts.toDate().isAfter(latestUpdate.toDate())) {
          latestUpdate = ts;
        }
      }
    }
    if (latestUpdate == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          // Use .toLocal() for correct date on all devices
          'UPDATED AT: ${DateFormat('EEE MMM d yyyy').format(latestUpdate.toDate().toLocal())}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _TimetableContent extends StatelessWidget {
  final String semester;
  final String program;
  final String section;
  final List<QueryDocumentSnapshot> docs;

  const _TimetableContent({
    required this.semester,
    required this.program,
    required this.section,
    required this.docs,
  });

  @override
  Widget build(BuildContext context) {
    Timestamp? latestUpdate;
    for (var doc in docs) {
      final ts = doc['last_updated'];
      if (ts is Timestamp) {
        if (latestUpdate == null ||
            ts.toDate().isAfter(latestUpdate.toDate())) {
          latestUpdate = ts;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 24,
              child: Text(
                '$program | $semester Sec-$section',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (latestUpdate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    // Use .toLocal() for correct date on all devices
                    'UPDATED AT: ${DateFormat('EEE MMM d yyyy').format(latestUpdate.toDate().toLocal())}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTimetableContent(docs),
              const SizedBox(height: 10),
              _buildPrintButton(context, latestUpdate, docs),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimetableContent(List<QueryDocumentSnapshot> docs) {
    final data = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in data) {
      final day = item['day'] ?? 'Unknown';
      grouped.putIfAbsent(day, () => []).add(item);
    }

    // Sort days so Monday comes before Tuesday, etc.
    final weekDaysOrder = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final sortedEntries =
        grouped.entries.toList()..sort((a, b) {
          int aIndex = weekDaysOrder.indexOf(a.key);
          int bIndex = weekDaysOrder.indexOf(b.key);
          if (aIndex == -1) aIndex = 100; // Unknown days at end
          if (bIndex == -1) bIndex = 100;
          return aIndex.compareTo(bIndex);
        });

    return Column(
      children:
          sortedEntries.map((entry) {
            final day = entry.key;
            final lectures = entry.value;
            // --- Robust sorting: parse time as DateTime for accurate order ---
            lectures.sort((a, b) {
              final aTime = _parseTime(a['start_time']);
              final bTime = _parseTime(b['start_time']);
              return aTime.compareTo(bTime);
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$day (${lectures.length} lectures)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepPurple),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      const Divider(height: 0),
                      ...lectures.map(_buildLectureRow).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
    );
  }

  /// Helper to parse time robustly for sorting
  DateTime _parseTime(dynamic timeStr) {
    if (timeStr == null) return DateTime(2000, 1, 1, 0, 0);
    final str = timeStr.toString().trim().toUpperCase();
    try {
      // Try parsing as "h:mm AM/PM"
      if (str.contains('AM') || str.contains('PM')) {
        return DateFormat('h:mm a').parse(str);
      }
      // Try parsing as "HH:mm" or "H:mm"
      final parts = str.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final min =
            int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return DateTime(2000, 1, 1, hour, min);
      }
    } catch (_) {}
    return DateTime(2000, 1, 1, 0, 0);
  }

  Widget _buildPrintButton(
    BuildContext context,
    Timestamp? latestUpdate,
    List<QueryDocumentSnapshot> docs,
  ) {
    return ElevatedButton.icon(
      onPressed: () async {
        final scaffold = ScaffoldMessenger.of(context);
        scaffold.showSnackBar(
          const SnackBar(content: Text('Generating PDF...')),
        );

        try {
          final pdf = await _generatePdf(docs, latestUpdate);
          if (context.mounted) {
            scaffold.hideCurrentSnackBar();
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 400),
                pageBuilder:
                    (_, __, ___) => FadeInRight(
                      duration: const Duration(milliseconds: 400),
                      child: TimetablePrintPreviewScreen(
                        pdfDocument: pdf,
                        semester: semester,
                        program: program,
                        section: section,
                        latestUpdate: latestUpdate,
                      ),
                    ),
                transitionsBuilder: (_, animation, __, child) => child,
              ),
            );
          }
        } catch (e) {
          scaffold.showSnackBar(
            SnackBar(content: Text('Failed to generate PDF: $e')),
          );
        }
      },
      icon: const Icon(Icons.print, size: 20),
      label: const Text('Print Timetable', style: TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 6,
        shadowColor: Colors.deepPurple.withOpacity(0.3),
      ),
    );
  }

  Future<pw.Document> _generatePdf(
    List<QueryDocumentSnapshot> docs,
    Timestamp? latestUpdate,
  ) async {
    final doc = pw.Document();
    final data = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in data) {
      final day = item['day']?.toString() ?? 'Unknown';
      grouped.putIfAbsent(day, () => []).add(item);
    }

    // Sort days for PDF as well
    final weekDaysOrder = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final sortedEntries =
        grouped.entries.toList()..sort((a, b) {
          int aIndex = weekDaysOrder.indexOf(a.key);
          int bIndex = weekDaysOrder.indexOf(b.key);
          if (aIndex == -1) aIndex = 100;
          if (bIndex == -1) bIndex = 100;
          return aIndex.compareTo(bIndex);
        });

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          if (sortedEntries.isEmpty) {
            return [pw.Center(child: pw.Text('No timetable data available'))];
          }

          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$program | $semester Sec-$section',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (latestUpdate != null)
                    pw.Text(
                      // Use .toLocal() for correct date in PDF
                      'Updated: ${DateFormat('EEE MMM d yyyy').format(latestUpdate.toDate().toLocal())}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            ...sortedEntries.map((entry) {
              final lectures =
                  entry.value..sort((a, b) {
                    final aTime = _parseTime(a['start_time']);
                    final bTime = _parseTime(b['start_time']);
                    return aTime.compareTo(bTime);
                  });

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    entry.key,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Table.fromTextArray(
                    context: context,
                    border: pw.TableBorder.all(width: 0.5),
                    cellAlignment: pw.Alignment.centerLeft,
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    headerAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.center,
                      2: pw.Alignment.center,
                      3: pw.Alignment.centerLeft,
                    },
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(1.5),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(2),
                    },
                    headers: ['Subject', 'Timing', 'Room', 'Instructor'],
                    data:
                        lectures.map((lecture) {
                          // Format time as "hh:mm" (12-hour, no AM/PM)
                          String formatTime(String t) {
                            try {
                              final dt = DateFormat('h:mm a').parse(t);
                              return DateFormat('hh:mm').format(dt);
                            } catch (_) {
                              try {
                                final dt = DateFormat('HH:mm').parse(t);
                                return DateFormat('hh:mm').format(dt);
                              } catch (_) {
                                return t
                                    .replaceAll(RegExp(r'(AM|PM|am|pm)'), '')
                                    .trim();
                              }
                            }
                          }

                          final startTime = formatTime(
                            lecture['start_time'] ?? '',
                          );
                          final endTime = formatTime(lecture['end_time'] ?? '');
                          return [
                            lecture['subject']?.toString() ?? 'N/A',
                            '$startTime - $endTime',
                            lecture['room']?.toString() ?? 'N/A',
                            lecture['instructor']?.toString() ?? 'N/A',
                          ];
                        }).toList(),
                  ),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),
          ];
        },
      ),
    );

    return doc;
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: const [
          Expanded(
            flex: 4,
            child: Text(
              'SUBJECT',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TIMING',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ROOM',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'INSTRUCTOR',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLectureRow(Map<String, dynamic> lecture) {
    final startTimeRaw = lecture['start_time'] ?? '';
    final endTimeRaw = lecture['end_time'] ?? '';
    final subject = lecture['subject'] ?? '';
    final room = lecture['room'] ?? '';
    final instructor = lecture['instructor'] ?? '';

    // Format time as "hh:mm" (12-hour, no AM/PM)
    String formatTime(String t) {
      try {
        final cleaned = t.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
        final dt = DateFormat('h:mm a').parse(cleaned);
        return DateFormat('hh:mm').format(dt);
      } catch (_) {
        try {
          final dt = DateFormat('HH:mm').parse(t);
          return DateFormat('hh:mm').format(dt);
        } catch (_) {
          return t.replaceAll(RegExp(r'(AM|PM|am|pm)'), '').trim();
        }
      }
    }

    final startTime = formatTime(startTimeRaw);
    final endTime = formatTime(endTimeRaw);

    return Column(
      children: [
        const Divider(height: 0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  subject,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 14),
                  softWrap: true,
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(startTime, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 2),
                    const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(endTime, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  room,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  instructor,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 14),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
