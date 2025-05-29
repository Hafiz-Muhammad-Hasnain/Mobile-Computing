import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'timetable_print_preview_screen.dart';
import 'package:animate_do/animate_do.dart';

class TeachersTimetableScreen extends StatelessWidget {
  final String teacherName;

  const TeachersTimetableScreen({super.key, required this.teacherName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('timetable_data')
              .where('instructor', isEqualTo: teacherName)
              .get(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

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
              children: [
                Text(
                  teacherName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (snapshot.connectionState == ConnectionState.done &&
                    docs.isNotEmpty)
                  Container(
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
                      'UPDATED AT: ${latestUpdate != null ? DateFormat('EEE MMM d yyyy').format(latestUpdate.toDate().toLocal()) : 'N/A'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          body: FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: _buildBody(context, snapshot, docs, latestUpdate),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<QuerySnapshot> snapshot,
    List<QueryDocumentSnapshot> docs,
    Timestamp? latestUpdate,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: SpinKitCircle(color: Colors.deepPurple, size: 60.0),
      );
    }

    if (docs.isEmpty) {
      return const Center(child: Text('No lectures found for this teacher.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTimetableContent(docs),
          const SizedBox(height: 24),
          _buildPrintButton(context, latestUpdate, docs),
          const SizedBox(height: 24),
        ],
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

    final weekDaysOrder = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final sortedGrouped = Map.fromEntries(
      weekDaysOrder
          .where((day) => grouped.containsKey(day))
          .map((day) => MapEntry(day, grouped[day]!)),
    );

    return Column(
      children:
          sortedGrouped.entries.map((entry) {
            final day = entry.key;
            final lectures = entry.value;

            // Sort lectures by parsed time (tarteeb sy 9,10,12,1,2 ...)
            lectures.sort((a, b) {
              DateTime aTime = _parseTime(a['start_time']);
              DateTime bTime = _parseTime(b['start_time']);
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

  // Helper to parse time for sorting
  DateTime _parseTime(dynamic timeStr) {
    if (timeStr == null) return DateTime(2000, 1, 1, 0, 0);
    final str = timeStr.toString().trim().toUpperCase();
    try {
      if (str.contains('AM') || str.contains('PM')) {
        return DateFormat('h:mm a').parse(str);
      }
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
      onPressed: () => _generateAndPreviewPdf(context, docs, latestUpdate),
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

  Future<void> _generateAndPreviewPdf(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
    Timestamp? latestUpdate,
  ) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(const SnackBar(content: Text('Generating PDF...')));

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
                    semester: '', // Not used for teacher timetable
                    program: '', // Not used for teacher timetable
                    section: '', // Not used for teacher timetable
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

    final weekDaysOrder = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final sortedGrouped = Map.fromEntries(
      weekDaysOrder
          .where((day) => grouped.containsKey(day))
          .map((day) => MapEntry(day, grouped[day]!)),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          if (grouped.isEmpty) {
            return [pw.Center(child: pw.Text('No timetable data available'))];
          }

          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    teacherName,
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
            ...sortedGrouped.entries.map((entry) {
              final lectures =
                  entry.value..sort((a, b) {
                    DateTime aTime = _parseTime(a['start_time']);
                    DateTime bTime = _parseTime(b['start_time']);
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
                    headers: ['Subject', 'Timing', 'Room', 'Class'],
                    data:
                        lectures.map((lecture) {
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
                            '${lecture['program']?.toString() ?? ''} ${lecture['semester']?.toString() ?? ''} Sec-${lecture['sec']?.toString() ?? ''}',
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
            child: Padding(
              padding: EdgeInsets.only(left: 12), // <-- Add left padding here
              child: Text(
                'SUBJECT',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.left, // Keep left for heading
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TIMING',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ROOM',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'CLASS',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
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
    final program = lecture['program'] ?? '';
    final semester = lecture['semester'] ?? '';
    final section = lecture['sec'] ?? '';

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // SUBJECT
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    subject,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 14),
                    softWrap: true,
                  ),
                ),
              ),

              // TIMING (with vertical layout)
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(startTime, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 2),
                    const Text("-", style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(endTime, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),

              // ROOM
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    room,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),

              // CLASS (Semester, Program, Section)
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (semester.isNotEmpty)
                      Text(
                        semester,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    if (program.isNotEmpty)
                      Text(
                        program,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    if (section.isNotEmpty)
                      Text(
                        'Section $section',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
