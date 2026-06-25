import 'package:intl/intl.dart';

class AppDateFormatter {
  static String format(DateTime date, String formatPattern) {
    String intlPattern;
    switch (formatPattern) {
      case 'MM/DD/YYYY':
        intlPattern = 'MM/dd/yyyy';
        break;
      case 'DD/MM/YYYY':
        intlPattern = 'dd/MM/yyyy';
        break;
      case 'YYYY-MM-DD':
        intlPattern = 'yyyy-MM-dd';
        break;
      case 'DD-MM-YYYY':
        intlPattern = 'dd-MM-yyyy';
        break;
      case 'MMM DD, YYYY':
        intlPattern = 'MMM dd, yyyy';
        break;
      default:
        intlPattern = 'MM/dd/yyyy';
    }
    return DateFormat(intlPattern).format(date);
  }
}
