import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/settings_provider.dart';
import '../../core/utils/app_date_formatter.dart';
import '../providers/screen_providers.dart';

class DatePickerField extends ConsumerWidget {
  const DatePickerField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(aeDateProvider);
    final activeDateFormat = ref.watch(dateFormatProvider);
    final dateStr = AppDateFormatter.format(selectedDate, activeDateFormat);

    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.onboardingViolet,
                  onPrimary: Colors.white,
                  surface: AppColors.backgroundDark,
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          ref.read(aeDateProvider.notifier).state = date;
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.cardDarkSecondary,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                color: AppColors.white.withValues(alpha: 0.5), size: 20.sp),
            SizedBox(width: 12.w),
            AppText(
              dateStr,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class NotesField extends ConsumerWidget {
  const NotesField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(aeNotesControllerProvider);
    return AppTextField(
      controller: controller,
      hint: 'Notes (optional)',
      prefix: Padding(
        padding: EdgeInsets.only(bottom: 24.h),
        child:
            const Icon(Icons.notes_rounded, color: AppColors.onboardingViolet),
      ),
      keyboardType: TextInputType.multiline,
      maxLines: 2,
    );
  }
}

class ReceiptAttachmentPicker extends ConsumerWidget {
  const ReceiptAttachmentPicker({super.key});

  void _showImageViewer(BuildContext context, File? file, String? url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: file != null
                      ? Image.file(file)
                      : (url != null
                          ? Image.network(url)
                          : const SizedBox.shrink()),
                ),
              ),
            ),
            Positioned(
              top: 40.h,
              right: 16.w,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 26),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(aeReceiptFileProvider);
    final url = ref.watch(aeReceiptUrlProvider);
    final hasReceipt = file != null || url != null;

    return GestureDetector(
      onTap: () async {
        if (hasReceipt) {
          _showImageViewer(context, file, url);
        } else {
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(
              source: ImageSource.gallery, imageQuality: 70);
          if (image != null) {
            ref.read(aeReceiptFileProvider.notifier).state = File(image.path);
          }
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.cardDarkSecondary,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (hasReceipt)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  width: 44.w,
                  height: 44.w,
                  child: file != null
                      ? Image.file(file, fit: BoxFit.cover)
                      : Image.network(url!, fit: BoxFit.cover),
                ),
              )
            else
              Icon(Icons.receipt_long_rounded,
                  color: AppColors.white.withValues(alpha: 0.5), size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Receipt Attachment',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    file != null
                        ? 'Image selected • Tap to view'
                        : url != null
                            ? 'Receipt attached • Tap to view'
                            : 'Tap to upload (optional)',
                    fontSize: 13,
                    color: AppColors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
            if (hasReceipt)
              GestureDetector(
                onTap: () {
                  ref.read(aeReceiptFileProvider.notifier).state = null;
                  ref.read(aeReceiptUrlProvider.notifier).state = null;
                },
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded,
                      color: AppColors.error, size: 16.sp),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
