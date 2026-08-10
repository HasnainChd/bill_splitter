import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Helper class to hold a reconstructed horizontal line of text
class ReconstructedLine {
  final double centerY;
  final List<TextElement> elements;
  final String text;

  ReconstructedLine({
    required this.centerY,
    required this.elements,
    required this.text,
  });
}

class ReceiptScannerService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<ReceiptScanResult> scanReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    // 1. Collect all TextElements across all blocks and lines
    final List<TextElement> allElements = [];
    for (final TextBlock block in recognizedText.blocks) {
      for (final TextLine line in block.lines) {
        for (final TextElement element in line.elements) {
          if (element.text.trim().isNotEmpty) {
            allElements.add(element);
          }
        }
      }
    }

    // 2. Group elements into horizontal lines based on Y proximity
    final List<ReconstructedLine> reconstructedLines =
        _groupElementsByYProximity(allElements);

    // 3. Extract total and merchant from reconstructed lines
    final double? amount = _extractTotal(reconstructedLines);
    final String title = _extractMerchant(reconstructedLines);

    final result = ReceiptScanResult(
      rawText: recognizedText.text,
      extractedAmount: amount,
      extractedTitle: title,
    );

    // Debug logging
    debugPrint('=== RECEIPT LINES ===');
    for (final line in reconstructedLines) {
      debugPrint('Y:${line.centerY.toInt()} | ${line.text}');
    }
    debugPrint(
        '=== EXTRACTED: amount=${result.extractedAmount} title=${result.extractedTitle} ===');

    return result;
  }

  /// Groups elements within 20px Y-distance, sorts each group left-to-right (X position),
  /// and returns lines sorted top-to-bottom (Y position).
  List<ReconstructedLine> _groupElementsByYProximity(
      List<TextElement> elements) {
    if (elements.isEmpty) return [];

    // Sort elements by Y-center position ascending
    final sorted = List<TextElement>.from(elements)
      ..sort((a, b) {
        final aY = a.boundingBox.top + (a.boundingBox.height / 2);
        final bY = b.boundingBox.top + (b.boundingBox.height / 2);
        return aY.compareTo(bY);
      });

    final List<List<TextElement>> clusters = [];

    for (final element in sorted) {
      final elementY =
          element.boundingBox.top + (element.boundingBox.height / 2);
      bool addedToCluster = false;

      for (final cluster in clusters) {
        // Calculate average Y of cluster
        final clusterYAvg = cluster.fold<double>(
                0.0,
                (sum, e) =>
                    sum + (e.boundingBox.top + (e.boundingBox.height / 2))) /
            cluster.length;

        // Y proximity threshold: 20 pixels
        if ((elementY - clusterYAvg).abs() <= 20.0) {
          cluster.add(element);
          addedToCluster = true;
          break;
        }
      }

      if (!addedToCluster) {
        clusters.add([element]);
      }
    }

    final List<ReconstructedLine> lines = [];

    for (final cluster in clusters) {
      // Sort elements in each cluster left-to-right (by boundingBox.left)
      cluster.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

      final avgY = cluster.fold<double>(
              0.0,
              (sum, e) =>
                  sum + (e.boundingBox.top + (e.boundingBox.height / 2))) /
          cluster.length;

      final joinedText = cluster
          .map((e) => e.text.trim())
          .where((t) => t.isNotEmpty)
          .join(' ');

      lines.add(ReconstructedLine(
        centerY: avgY,
        elements: cluster,
        text: joinedText,
      ));
    }

    // Sort lines top-to-bottom by Y-center
    lines.sort((a, b) => a.centerY.compareTo(b.centerY));

    return lines;
  }

  /// Search reconstructed lines from bottom to top for total keyword,
  /// and extract the rightmost number.
  double? _extractTotal(List<ReconstructedLine> lines) {
    final totalKeywords = RegExp(
      r'\b(grand\s+total|total|amount\s+due|amount\s+payable|net\s+amount|to\s+pay)\b',
      caseSensitive: false,
    );

    // Search from bottom up
    for (int i = lines.length - 1; i >= 0; i--) {
      final lineText = lines[i].text;

      if (totalKeywords.hasMatch(lineText)) {
        final number = _extractRightmostNumber(lineText);
        if (number != null && number > 0) return number;

        // Check adjacent line if total value is on next line below
        if (i + 1 < lines.length) {
          final nextNumber = _extractRightmostNumber(lines[i + 1].text);
          if (nextNumber != null && nextNumber > 0) return nextNumber;
        }
      }
    }

    // Fallback: Largest number on receipt
    double? largest;
    for (final line in lines) {
      final number = _extractRightmostNumber(line.text);
      if (number != null && number > 0) {
        if (largest == null || number > largest) {
          largest = number;
        }
      }
    }
    return largest;
  }

  /// Extract the LAST (rightmost) number on a line and parse standard or European format
  double? _extractRightmostNumber(String lineText) {
    // Strip currency symbols first
    final cleaned = lineText.replaceAll(
        RegExp(r'[£€¥₹$]|\bPKR\b|\bRS\.?\b|\bUSD\b|\bRs\b',
            caseSensitive: false),
        '');

    // Extract all candidate number tokens from line
    final tokenPattern = RegExp(r'(\d+(?:[,\.]\d+)*)');
    final matches = tokenPattern.allMatches(cleaned);

    double? lastParsedNumber;

    for (final match in matches) {
      final token = match.group(1)!;
      final parsed = _parseNumberToken(token);
      if (parsed != null && parsed > 0) {
        lastParsedNumber = parsed;
      }
    }

    return lastParsedNumber;
  }

  /// Parses number token considering both standard (1,234.56) and European (1.234,56 / 25,25) formats
  double? _parseNumberToken(String rawToken) {
    String token = rawToken.trim();
    if (token.isEmpty) return null;

    // Has both period and comma
    if (token.contains('.') && token.contains(',')) {
      final lastPeriod = token.lastIndexOf('.');
      final lastComma = token.lastIndexOf(',');

      if (lastPeriod > lastComma) {
        // Standard format: 1,234.56 -> remove commas
        token = token.replaceAll(',', '');
      } else {
        // European format: 1.234,56 -> remove periods, change comma to period
        token = token.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (token.contains(',')) {
      // Contains comma but no period
      final parts = token.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        // European decimal: 25,25 -> 25.25
        token = token.replaceAll(',', '.');
      } else {
        // Thousands separator without decimal: 1,234 -> 1234
        token = token.replaceAll(',', '');
      }
    }

    return double.tryParse(token);
  }

  /// Extract merchant name from top 10 reconstructed lines
  String _extractMerchant(List<ReconstructedLine> lines) {
    final skipWords = <String>{
      'receipt',
      'invoice',
      'bill',
      'sale',
      'cash',
      'tax',
      'total',
      'subtotal',
      'item',
      'qty',
      'quantity',
      'price',
      'amount',
      'thank',
      'you',
      'visit',
      'again',
      'please',
      'come',
      'server',
      'table',
      'guests',
      'phone',
      'ref',
      'card',
      'type',
      'entry',
      'time',
      'status',
      'date',
      'authorization',
      'approved',
      'contactless',
      'swiped',
      'chip',
      'visa',
      'mastercard',
      'payment',
      'transaction',
      'order',
      'no',
      'number',
      'id',
      'code',
      'tran',
      'xid',
    };

    for (final line in lines.take(10)) {
      final trimmed = line.text.trim();

      if (trimmed.length < 3) continue;

      // Skip separator lines
      if (RegExp(r'^[-=_*#]{3,}$').hasMatch(trimmed)) continue;

      // Skip web/email
      if (RegExp(r'@|www\.|\.com|\.net|\.org|\.pk', caseSensitive: false)
          .hasMatch(trimmed)) {
        continue;
      }
      // Skip digit-heavy lines (>50% digits)
      final digitCount = trimmed.replaceAll(RegExp(r'[^0-9]'), '').length;
      final totalChars = trimmed.replaceAll(' ', '').length;
      if (totalChars > 0 && (digitCount / totalChars) > 0.5) continue;

      // Skip lines with currency symbols
      if (RegExp(r'[$£€¥₹]|\bPKR\b|\bRS\b|\bUSD\b', caseSensitive: false)
          .hasMatch(trimmed)) {
        continue;
      }

      // Skip single skip words
      if (skipWords.contains(trimmed.toLowerCase())) continue;

      // Capitalize properly and return
      return trimmed
          .split(' ')
          .map((w) => w.isNotEmpty
              ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
              : w)
          .join(' ');
    }

    return lines.isNotEmpty ? lines.first.text : '';
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class ReceiptScanResult {
  final String rawText;
  final double? extractedAmount;
  final String extractedTitle;

  const ReceiptScanResult({
    required this.rawText,
    required this.extractedAmount,
    required this.extractedTitle,
  });

  bool get hasAmount => extractedAmount != null && extractedAmount! > 0;
  bool get hasTitle => extractedTitle.isNotEmpty;
}
