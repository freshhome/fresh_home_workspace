import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import '../cubit/whatsapp_settings_cubit.dart';

class WhatsAppSettingsPage extends StatefulWidget {
  const WhatsAppSettingsPage({super.key});

  @override
  State<WhatsAppSettingsPage> createState() => _WhatsAppSettingsPageState();
}

class _WhatsAppSettingsPageState extends State<WhatsAppSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  void _populateFields(Map<String, dynamic> settings) {
    _numberController.text = settings['business_number']?.toString() ?? '';
    _expiryController.text = (settings['expiry_minutes'] ?? 60).toString();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: const Text(
          'إعدادات تأكيد واتساب',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: themeColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocConsumer<WhatsAppSettingsCubit, WhatsAppSettingsState>(
          listener: (context, state) {
            if (state is WhatsAppSettingsSaveSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'تم حفظ إعدادات واتساب بنجاح وتفعيلها تلقائياً!',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (state is WhatsAppSettingsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'فشل الإجراء: ${state.message}',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is WhatsAppSettingsInitial) {
              context.read<WhatsAppSettingsCubit>().loadSettings();
            }

            if (state is WhatsAppSettingsLoading) {
              return Center(
                child: CircularProgressIndicator(color: themeColor.primary),
              );
            }

            Map<String, dynamic> currentSettings = {};
            bool isSaving = state is WhatsAppSettingsSaving;

            if (state is WhatsAppSettingsLoaded) {
              currentSettings = state.settings;
              if (_numberController.text.isEmpty && _expiryController.text.isEmpty) {
                _populateFields(currentSettings);
              }
            } else if (state is WhatsAppSettingsSaving) {
              currentSettings = state.settings;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          shadowColor: themeColor.primary.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          color: themeColor.cardBackground,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: Colors.green.shade600,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'إعدادات تأكيد حجز الضيوف',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'تتيح لك هذه الإعدادات التحكم في رقم الواتساب الخاص بالشركة لاستلام رسائل تأكيد الحجز الجاهزة من العملاء، وكذلك تحديد المهلة الزمنية قبل إلغاء الحجز غير المؤكد تلقائياً.',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: themeColor.secondaryText,
                                    height: 1.5,
                                  ),
                                ),
                                const Divider(height: 32),
                                
                                // Number field
                                _buildTextField(
                                  controller: _numberController,
                                  label: 'رقم واتساب الإدارة لتلقي التأكيدات (بصيغة دولية مثل 2010...)',
                                  hint: 'أدخل رقم الواتساب بدون علامة + (مثال: 201012345678)',
                                  icon: Icons.phone_android_rounded,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'يرجى إدخال الرقم';
                                    if (val.startsWith('+')) return 'يرجى إدخال الرقم بدون علامة +';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Expiry minutes
                                _buildTextField(
                                  controller: _expiryController,
                                  label: 'مهلة تأكيد طلب الزائر قبل الإلغاء التلقائي (بالدقائق)',
                                  hint: 'أدخل المهلة بالدقائق (مثلاً: 60)',
                                  icon: Icons.timer_rounded,
                                  keyboardType: TextInputType.number,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'يرجى إدخال المهلة بالدقائق';
                                    if (int.tryParse(val) == null) return 'يرجى إدخال رقم صحيح';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : () {
                              if (_formKey.currentState!.validate()) {
                                final settings = {
                                  'business_number': _numberController.text.trim(),
                                  'expiry_minutes': int.parse(_expiryController.text.trim()),
                                  'enabled_for_guests': true,
                                };
                                context.read<WhatsAppSettingsCubit>().saveSettings(settings);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 2,
                            ),
                            icon: isSaving 
                              ? const SizedBox(
                                  width: 20, 
                                  height: 20, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.save_rounded),
                            label: const Text(
                              'حفظ وتطبيق الإعدادات',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 14, fontFamily: 'Cairo'),
        ),
      ],
    );
  }
}
