import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;

  const AppText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.align,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: fontSize != null ? (fontSize! * textScaleFactor).sp : null,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}
