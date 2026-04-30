import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;

  const AddExpenseScreen({super.key, required this.groupId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addExpense() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter expense title')),
      );
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully!')),
      );
      context.go('${AppRouter.groupDetail}?groupId=${widget.groupId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const AppText(
            'Add Expense',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context
                .go('${AppRouter.groupDetail}?groupId=${widget.groupId}'),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Group ID: ${widget.groupId}',
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              SizedBox(height: 24.h),
              AppText(
                'Add New Expense',
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 24.h),
              AppTextField(
                label: 'Expense Title',
                hint: 'Enter expense title',
                controller: _titleController,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: 'Amount',
                hint: 'Enter amount',
                controller: _amountController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: 'Description',
                hint: 'Enter expense description',
                controller: _descriptionController,
                maxLines: 3,
              ),
              SizedBox(height: 24.h),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Paid By',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 16.h),
                    AppText(
                      'Paid by selection will be implemented here',
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Split Between',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 16.h),
                    AppText(
                      'Split options will be implemented here',
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              AppButton(
                label: 'Add Expense',
                onTap: _addExpense,
                isLoading: _isLoading,
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}
