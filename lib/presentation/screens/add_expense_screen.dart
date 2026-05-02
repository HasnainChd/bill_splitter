import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/group.dart';
import '../../core/models/expense.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/utils/app_snackbar.dart';

class AddExpenseScreen extends StatefulWidget {
  final Group group;

  const AddExpenseScreen({super.key, required this.group});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  bool _equalSplit = true;
  String _selectedPaidBy = '';
  String _selectedCurrency = 'PKR';
  List<String> _selectedMembers = [];
  final Map<String, TextEditingController> _customAmountControllers = {};

  @override
  void initState() {
    super.initState();
    _selectedPaidBy = widget.group.members.first;
    _selectedCurrency = widget.group.currency;
    _selectedMembers = List.from(widget.group.members);

    // Initialize custom amount controllers
    for (final member in widget.group.members) {
      _customAmountControllers[member] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (final controller in _customAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMembers.isEmpty) {
      AppSnackBar.showError(
          context, 'Please select at least one member to split with');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Create split amounts map
    final Map<String, double> splitAmong = {};
    final totalAmount = double.tryParse(_amountController.text) ?? 0;

    if (_equalSplit) {
      final perPerson = totalAmount / _selectedMembers.length;
      for (final member in _selectedMembers) {
        splitAmong[member] = perPerson;
      }
    } else {
      for (final member in _selectedMembers) {
        splitAmong[member] =
            double.tryParse(_customAmountControllers[member]!.text) ?? 0;
      }
    }

    // Create expense object
    // ignore: unused_local_variable
    final expense = Expense(
      expenseId: const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: totalAmount,
      currency: _selectedCurrency,
      paidBy: _selectedPaidBy,
      splitAmong: splitAmong,
      date: DateTime.now(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      groupId: widget.group.groupId,
      categoryIcon: Icons.receipt_outlined,
    );

    // TODO: Save to provider - expensesProvider.addExpense(expense)

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      AppSnackBar.showSuccess(context, 'Expense added successfully');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const AppText(
            'Add Expense',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnPrimary,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      AppTextField(
                        hint: 'e.g. Hotel Stay, Dinner, Petrol',
                        label: 'Expense Title',
                        prefixIcon: Icons.receipt_outlined,
                        controller: _titleController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title cannot be empty';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Amount and Currency row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              hint: '0.00',
                              label: 'Amount',
                              prefixIcon: Icons.attach_money,
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (value) {
                                final amount = double.tryParse(value ?? '');
                                if (value == null || value.trim().isEmpty) {
                                  return 'Amount is required';
                                }
                                if (amount == null || amount <= 0) {
                                  return 'Enter valid positive number';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: _selectedCurrency,
                              decoration: InputDecoration(
                                labelText: 'Currency',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide:
                                      BorderSide(color: AppColors.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide:
                                      BorderSide(color: AppColors.divider),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                      color: AppColors.primary, width: 2),
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 12.h),
                              ),
                              items: const [
                                'PKR',
                                'USD',
                                'EUR',
                                'GBP',
                                'AED',
                                'SAR'
                              ].map((currency) {
                                return DropdownMenuItem(
                                  value: currency,
                                  child: Text(currency),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCurrency = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Who Paid section
                      AppText(
                        'WHO PAID?',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 8.h),
                      DropdownButtonFormField<String>(
                        value: _selectedPaidBy,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide:
                                BorderSide(color: AppColors.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select who paid';
                          }
                          return null;
                        },
                        items: widget.group.members.map((member) {
                          return DropdownMenuItem(
                            value: member,
                            child: Text(member),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPaidBy = value!;
                          });
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Split Among section
                      AppText(
                        'SPLIT AMONG',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: widget.group.members.map((member) {
                          final isSelected = _selectedMembers.contains(member);
                          return FilterChip(
                            label: Text(member),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedMembers.add(member);
                                } else {
                                  _selectedMembers.remove(member);
                                }
                              });
                            },
                            backgroundColor: AppColors.white,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                            ),
                            side: BorderSide(color: AppColors.border),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16.h),

                      // Equal Split toggle
                      Row(
                        children: [
                          const AppText(
                            'Equal Split',
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          const Spacer(),
                          Switch(
                            value: _equalSplit,
                            onChanged: (value) {
                              setState(() {
                                _equalSplit = value;
                              });
                            },
                            activeColor: AppColors.accent,
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Split details
                      if (_equalSplit)
                        AppCard(
                          color: AppColors.primaryLight,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: AppColors.accent,
                                  width: 3,
                                ),
                              ),
                            ),
                            padding: EdgeInsets.only(left: 12.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppText(
                                  'Each person pays:',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                SizedBox(height: 8.h),
                                ..._selectedMembers.map((member) {
                                  final amount =
                                      double.tryParse(_amountController.text) ??
                                          0;
                                  final perPerson =
                                      amount / _selectedMembers.length;
                                  return Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 2.h),
                                    child: Row(
                                      children: [
                                        AppText(member),
                                        const Spacer(),
                                        AppText(
                                          '$_selectedCurrency ${perPerson.toStringAsFixed(2)}',
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            ..._selectedMembers.map((member) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                child: AppTextField(
                                  hint: '0.00',
                                  label: member,
                                  controller: _customAmountControllers[member]!,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (value) {
                                    final amount = double.tryParse(value ?? '');
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter amount';
                                    }
                                    if (amount == null || amount < 0) {
                                      return 'Enter valid number';
                                    }
                                    return null;
                                  },
                                ),
                              );
                            }),
                            SizedBox(height: 8.h),
                            // Remaining amount indicator
                            Builder(
                              builder: (context) {
                                final totalAllocated =
                                    _selectedMembers.fold<double>(
                                  0,
                                  (sum, member) {
                                    final amount = double.tryParse(
                                            _customAmountControllers[member]!
                                                .text) ??
                                        0;
                                    return sum + amount;
                                  },
                                );
                                final totalAmount =
                                    double.tryParse(_amountController.text) ??
                                        0;
                                final remaining = totalAmount - totalAllocated;

                                return AppText(
                                  'Remaining: $_selectedCurrency ${remaining.abs().toStringAsFixed(2)}',
                                  color: remaining.abs() < 0.01
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontSize: 14,
                                );
                              },
                            ),
                          ],
                        ),
                      SizedBox(height: 16.h),

                      // Notes field
                      AppTextField(
                        hint: 'Add a note about this expense',
                        label: 'Notes (Optional)',
                        prefixIcon: Icons.note_outlined,
                        controller: _notesController,
                        maxLines: 2,
                      ),
                      SizedBox(height: 100.h), // Space for bottom bar
                    ],
                  ),
                ),
              ),
              // Fixed bottom bar
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, -2.h),
                    ),
                  ],
                ),
                child: AppButton(
                  label: 'Save Expense',
                  onTap: _saveExpense,
                  isLoading: _isLoading,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
