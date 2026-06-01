import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/notification_campaign.dart';
import '../cubit/notification_management_cubit.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _deepLinkController = TextEditingController();
  
  TargetType _selectedTargetType = TargetType.all;
  NotificationPriority _selectedPriority = NotificationPriority.normal;
  DateTime? _scheduledDateTime;
  
  // Custom Filter State
  final _filterValueController = TextEditingController();
  
  // Custom JSON Payload Builder
  final List<Map<String, TextEditingController>> _payloadMapList = [];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _deepLinkController.dispose();
    _filterValueController.dispose();
    for (var m in _payloadMapList) {
      m['key']?.dispose();
      m['value']?.dispose();
    }
    super.dispose();
  }

  void _addPayloadRow() {
    setState(() {
      _payloadMapList.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null && mounted) {
      final file = File(pickedFile.path);
      final url = await context.read<NotificationManagementCubit>().uploadImage(file);
      if (url != null) {
        _imageUrlController.text = url;
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفع الصورة بنجاح'), backgroundColor: Colors.green));
        }
      }
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    setState(() {
      _scheduledDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    // Build Target Filter JSON if needed
    final Map<String, dynamic> targetFilter = {};
    if (_selectedTargetType == TargetType.singleUser) {
      targetFilter['user_id'] = _filterValueController.text.trim();
    } else if (_selectedTargetType == TargetType.city) {
      targetFilter['city'] = _filterValueController.text.trim();
    } else if (_selectedTargetType == TargetType.service) {
      targetFilter['service_id'] = _filterValueController.text.trim();
    } else if (_selectedTargetType == TargetType.topic) {
      targetFilter['topic'] = _filterValueController.text.trim();
    }

    // Build Payload JSON
    final Map<String, dynamic> customPayload = {};
    for (var map in _payloadMapList) {
      final k = map['key']!.text.trim();
      final v = map['value']!.text.trim();
      if (k.isNotEmpty && v.isNotEmpty) {
        customPayload[k] = v;
      }
    }

    final campaign = NotificationCampaign.create(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : null,
      targetType: _selectedTargetType,
      targetFilter: targetFilter,
      priority: _selectedPriority,
      deepLink: _deepLinkController.text.trim().isNotEmpty ? _deepLinkController.text.trim() : null,
      payload: customPayload,
      scheduledAt: _scheduledDateTime,
    );

    context.read<NotificationManagementCubit>().submitCampaign(campaign);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إطلاق حملة إشعارات')),
      body: BlocListener<NotificationManagementCubit, NotificationManagementState>(
        listener: (context, state) {
          if (state is NotificationCampaignActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
            Navigator.pop(context); // Go back to dashboard on success
          } else if (state is NotificationManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('محتوى الرسالة (Message Content)'),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'عنوان الإشعار (Title)', border: OutlineInputBorder()),
                  controller: _titleController,
                  validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'محتوى الإشعار (Body)', border: OutlineInputBorder()),
                  controller: _bodyController,
                  maxLines: 3,
                  validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'رابط الصورة - اختياري (Image URL)', border: OutlineInputBorder()),
                        controller: _imageUrlController,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cloud_upload),
                      tooltip: 'رفع صورة',
                      onPressed: _pickImage,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('الاستهداف (Targeting)'),
                DropdownButtonFormField<TargetType>(
                  decoration: const InputDecoration(labelText: 'الفئة المستهدفة (Target Audience)'),
                // ignore: deprecated_member_use
                value: _selectedTargetType,
                  items: TargetType.values.map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(v.name.toUpperCase()),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedTargetType = v;
                        _filterValueController.clear();
                      });
                    }
                  },
                ),
                if (_selectedTargetType != TargetType.all && 
                    _selectedTargetType != TargetType.customers && 
                    _selectedTargetType != TargetType.technicians)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'معرف الاستهداف (Target Value ID / Name)', border: OutlineInputBorder()),
                      controller: _filterValueController,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'يرجى إدخال القيمة المطلوبة للفلتر';
                        return null;
                      },
                    ),
                  ),

                const SizedBox(height: 24),
                _buildSectionHeader('الإعدادات المتقدمة (Advanced Settings)'),
                DropdownButtonFormField<NotificationPriority>(
                  decoration: const InputDecoration(labelText: 'أولوية الإرسال (Priority)'),
                // ignore: deprecated_member_use
                value: _selectedPriority,
                  items: NotificationPriority.values.map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(v.name.toUpperCase()),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPriority = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'رابط التوجيه المباشر بالواتس/التطبيق (Deep Link)', border: OutlineInputBorder()),
                  controller: _deepLinkController,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('جدولة الإشعار (Schedule - Optional)'),
                  subtitle: Text(_scheduledDateTime == null 
                      ? 'إرسال فوراً' 
                      : 'سيرسل في: ${_scheduledDateTime.toString()}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: _pickDateTime,
                  ),
                ),
                if (_scheduledDateTime != null)
                  TextButton(
                    onPressed: () => setState(() => _scheduledDateTime = null),
                    child: const Text('إلغاء الجدولة وإرسال فوراً'),
                  ),

                const SizedBox(height: 24),
                _buildSectionHeader('بيانات إضافية برمجية (Custom JSON Payload)'),
                ..._payloadMapList.map((map) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Key', border: OutlineInputBorder()), controller: map['key'])),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()), controller: map['value'])),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => _payloadMapList.remove(map));
                        },
                      )
                    ],
                  ),
                )),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة حقل بيانات (Add Payload Field)'),
                  onPressed: _addPayloadRow,
                ),

                const SizedBox(height: 32),
                BlocBuilder<NotificationManagementCubit, NotificationManagementState>(
                  builder: (context, state) {
                    if (state is NotificationCampaignSending || state is NotificationImageUploading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _submit,
                      child: Text(_scheduledDateTime == null ? 'إطلاق الحملة الآن 🚀' : 'حفظ كحملة مجدولة ⏰', style: const TextStyle(fontSize: 16)),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }
}
