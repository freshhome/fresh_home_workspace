import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared/shared.dart';
import '../cubit/technician_finance_cubit.dart';
import '../cubit/technician_finance_state.dart';

class SettlementRequestBottomSheet extends StatefulWidget {
  const SettlementRequestBottomSheet({super.key});

  static Future<void> show(BuildContext context, {required TechnicianFinanceCubit cubit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: cubit,
        child: const SettlementRequestBottomSheet(),
      ),
    );
  }

  @override
  State<SettlementRequestBottomSheet> createState() =>
      _SettlementRequestBottomSheetState();
}

class _SettlementRequestBottomSheetState extends State<SettlementRequestBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedType = 'withdrawal'; // 'withdrawal' or 'payment'
  String? _selectedMethod;
  File? _selectedImage;
  final _picker = ImagePicker();

  final List<Map<String, dynamic>> _methods = [
    {
      'id': 'vodafone_cash',
      'icon': Icons.phone_android_rounded,
    },
    {
      'id': 'instapay',
      'icon': Icons.swap_horizontal_circle_outlined,
    },
    {
      'id': 'bank_transfer',
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'cash_handover',
      'icon': Icons.handshake_rounded,
    },
    {
      'id': 'other',
      'icon': Icons.more_horiz_rounded,
    },
  ];

  String _getMethodLabel(String id, AppLocalizations l10n) {
    switch (id) {
      case 'vodafone_cash':
        return l10n.finance_settlement_method_vodafone_cash;
      case 'instapay':
        return l10n.finance_settlement_method_instapay;
      case 'bank_transfer':
        return l10n.finance_settlement_method_bank_transfer;
      case 'cash_handover':
        return l10n.finance_settlement_method_cash_handover;
      case 'other':
      default:
        return l10n.finance_settlement_method_other;
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedMethod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.finance_error_method_required),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedType == 'payment' && _selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.finance_error_proof_required),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.finance_error_amount_positive),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      context.read<TechnicianFinanceCubit>().submitSettlement(
            amount: amount,
            method: _selectedMethod!,
            requestType: _selectedType,
            proofImage: _selectedImage,
          );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<TechnicianFinanceCubit, TechnicianFinanceState>(
      listener: (context, state) {
        if (state is TechnicianFinanceActionSuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.finance_settlement_submit_success),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is TechnicianFinanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
        decoration: BoxDecoration(
          color: themeColor.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.finance_settlement_request_title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Transaction Type Selector
                Text(
                  l10n.finance_settlement_type_label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedType = 'withdrawal';
                            _selectedImage = null; // Clear image for withdrawal
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedType == 'withdrawal'
                                ? themeColor.primary.withValues(alpha: 0.08)
                                : themeColor.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedType == 'withdrawal'
                                  ? themeColor.primary
                                  : Colors.grey.shade200,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.call_made_rounded,
                                color: _selectedType == 'withdrawal'
                                    ? themeColor.primary
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.finance_settlement_type_withdrawal,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  fontWeight: _selectedType == 'withdrawal'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _selectedType == 'withdrawal'
                                      ? themeColor.primary
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedType = 'payment';
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedType == 'payment'
                                ? themeColor.primary.withValues(alpha: 0.08)
                                : themeColor.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedType == 'payment'
                                  ? themeColor.primary
                                  : Colors.grey.shade200,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.call_received_rounded,
                                color: _selectedType == 'payment'
                                    ? themeColor.primary
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.finance_settlement_type_payment,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  fontWeight: _selectedType == 'payment'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _selectedType == 'payment'
                                      ? themeColor.primary
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Method selection heading
                Text(
                  l10n.finance_settlement_method,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Grid of methods
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _methods.map((method) {
                    final bool isSelected = _selectedMethod == method['id'];
                    final label = _getMethodLabel(method['id'] as String, l10n);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMethod = method['id'] as String;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeColor.primary.withValues(alpha: 0.08)
                              : themeColor.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? themeColor.primary
                                : Colors.grey.shade200,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              method['icon'] as IconData,
                              size: 18,
                              color: isSelected
                                  ? themeColor.primary
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? themeColor.primary
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Amount Text Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: l10n.finance_settlement_amount,
                    labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                    hintText: l10n.finance_settlement_amount_hint,
                    hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    prefixIcon: const Icon(Icons.monetization_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: themeColor.primary, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.finance_error_amount_required;
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return l10n.finance_error_amount_positive;
                    }
                    return null;
                  },
                ),
                if (_selectedType == 'payment') ...[
                  const SizedBox(height: 24),

                  // Proof Image Upload
                  Text(
                    l10n.finance_settlement_proof,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: themeColor.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: _selectedImage == null
                              ? BorderStyle.solid
                              : BorderStyle.none,
                        ),
                      ),
                      child: _selectedImage != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    radius: 16,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_rounded,
                                          size: 16, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          _selectedImage = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 36,
                                  color: themeColor.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.finance_settlement_proof_select,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Submit Button
                BlocBuilder<TechnicianFinanceCubit, TechnicianFinanceState>(
                  builder: (context, state) {
                    final bool isLoading = state is TechnicianFinanceActionLoading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.finance_settlement_submit,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
