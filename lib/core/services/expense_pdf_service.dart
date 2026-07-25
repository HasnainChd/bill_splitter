import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/models/expense.dart';

class ExpensePdfService {
  static String _sanitizeAscii(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune == 0x2022) {
        buffer.write('-');
      } else if (rune == 0x2014 || rune == 0x2013) {
        buffer.write('-');
      } else if (rune == 0x2026) {
        buffer.write('...');
      } else if (rune == 0x201C || rune == 0x201D) {
        buffer.write('"');
      } else if (rune == 0x2018 || rune == 0x2019) {
        buffer.write("'");
      } else if (rune == 0x20A8) {
        buffer.write('Rs');
      } else if (rune <= 255) {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static Future<Uint8List> generateExpensePdf({
    required Expense expense,
    required String paidByName,
    required List<Map<String, dynamic>> splits,
    required String categoryName,
  }) async {
    final pdf = pw.Document();

    final dateStr = expense.date.toString().substring(0, 10);
    final safeCurrency = _sanitizeAscii(expense.currency);
    final safeSplitType = _sanitizeAscii(expense.splitType);
    final formattedAmount =
        '$safeCurrency ${expense.amount.toStringAsFixed(2)}';
    final safeTitle = _sanitizeAscii(expense.title);
    final safePayerName = _sanitizeAscii(paidByName);
    final safeCategoryName = _sanitizeAscii(categoryName);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Equally',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#5B4BF5'),
                    ),
                  ),
                  pw.Text(
                    'Expense Receipt',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 2, color: PdfColor.fromHex('#5B4BF5')),
              pw.SizedBox(height: 16),

              // Expense Title
              pw.Text(
                safeTitle,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              // Date & Category
              pw.Row(
                children: [
                  pw.Text('Date: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateStr),
                  pw.SizedBox(width: 24),
                  pw.Text('Category: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(safeCategoryName),
                ],
              ),
              pw.SizedBox(height: 16),

              // Total Amount Card Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F0EEFF'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Total Amount',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      formattedAmount,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#5B4BF5'),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Paid by: $safePayerName',
                        style: const pw.TextStyle(fontSize: 13)),
                    pw.Text('Split type: $safeSplitType',
                        style: const pw.TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Split Breakdown Table
              pw.Text(
                'Split Breakdown',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F0EEFF'),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Member',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Share',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Member Rows
                  ...splits.map((split) {
                    final memberName = _sanitizeAscii(split['name'] as String);
                    final memberAmount = split['amount'] as double;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(memberName),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '$safeCurrency ${memberAmount.toStringAsFixed(2)}',
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              // Notes Section (if available)
              if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Notes',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(_sanitizeAscii(expense.notes!)),
                ),
              ],

              // Footer
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated by Equally - devorastudios.dev',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.Text(
                    DateTime.now().toString().substring(0, 16),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
