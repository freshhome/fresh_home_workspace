import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared/shared.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/pricing_discount_entity.dart';
import '../../domain/use_cases/upsert_pricing_discount_usecase.dart';

class DiscountCampaignBuilderPage extends StatefulWidget {
  final String subServiceId;
  final PricingDiscountEntity? discount;

  const DiscountCampaignBuilderPage({
    super.key,
    required this.subServiceId,
    this.discount,
  });

  @override
  State<DiscountCampaignBuilderPage> createState() => _DiscountCampaignBuilderPageState();
}

class _DiscountCampaignBuilderPageState extends State<DiscountCampaignBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // اسم الحملة
  final _codeController = TextEditingController();
  final _valueController = TextEditingController();
  final _limitController = TextEditingController();

  String _campaignType = 'coupon'; // نوع الحملة
  String _discountType = 'percentage';
  bool _isStackable = false;
  final int _priority = 1;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.discount != null) {
      _nameController.text = widget.discount!.name;
      _codeController.text = widget.discount!.code;
      _valueController.text = widget.discount!.discountValue.toString();
      _limitController.text = widget.discount!.usageLimit?.toString() ?? '';
      _campaignType = widget.discount!.campaignType;
      _discountType = widget.discount!.discountType;
      _isStackable = widget.discount!.isStackable;
      _startDate = widget.discount!.startDate;
      _endDate = widget.discount!.endDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _valueController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _saveDiscount() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final double val = double.parse(_valueController.text);
      
      // Safety Check: Percentage discount cap warning (30% rule)
      if (_discountType == 'percentage' && val > 30.0) {
        bool? proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ تجاوز حد الخصم الآمن للمؤسسة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            content: const Text(
              'إن قيمة الخصم المدخلة تتجاوز الحد الأقصى للمؤسسة (30%). سيقوم محرك الحسابات السحابي بتقييد الخصم تلقائياً عند الدفع. هل ترغب في المتابعة والحفظ على أي حال؟',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء التعديل', style: TextStyle(fontFamily: 'Cairo')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('نعم، احفظ الكود', style: TextStyle(fontFamily: 'Cairo')),
              )
            ],
          ),
        );
        if (proceed != true) return;
      }

      final discount = PricingDiscountEntity(
        id: widget.discount?.id ?? const Uuid().v4(),
        subServiceId: widget.discount?.subServiceId ?? widget.subServiceId,
        name: _nameController.text.trim(),
        code: _codeController.text.toUpperCase().trim(),
        campaignType: _campaignType,
        discountType: _discountType,
        discountValue: val,
        isStackable: _isStackable,
        priority: widget.discount?.priority ?? _priority,
        startDate: _startDate,
        endDate: _endDate,
        usageLimit: _limitController.text.isNotEmpty ? int.tryParse(_limitController.text) : null,
        usageCount: widget.discount?.usageCount ?? 0,
        isActive: widget.discount?.isActive ?? true,
      );

      await getIt<UpsertPricingDiscountUseCase>().call(discount);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [DiscountCampaignBuilderPage Error]: $e\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red.shade900, content: Text('فشل حفظ حملة الخصم: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).extension<ThemeColorExtension>()!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text(widget.discount != null ? 'تعديل حملة الخصم' : 'تصميم حملة الخصومات والتخفيضات', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم الحملة الترويجية (مثال: خصم الصيف)',
                          labelStyle: TextStyle(fontFamily: 'Cairo'),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'حقل إلزامي' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'رمز كود الخصم (كود ترويجي - مثال: FRESH30)',
                          labelStyle: TextStyle(fontFamily: 'Cairo'),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'حقل إلزامي' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _campaignType,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'نوع الحملة الترويجية', labelStyle: TextStyle(fontFamily: 'Cairo')),
                        items: const [
                          DropdownMenuItem(value: 'coupon', child: Text('كوبون ترويجي (Coupon)', style: TextStyle(fontFamily: 'Cairo'))),
                          DropdownMenuItem(value: 'first_order', child: Text('لأول طلب (First Order)', style: TextStyle(fontFamily: 'Cairo'))),
                          DropdownMenuItem(value: 'vip', child: Text('عملاء VIP', style: TextStyle(fontFamily: 'Cairo'))),
                          DropdownMenuItem(value: 'bulk_orders', child: Text('طلبات الجملة (Bulk)', style: TextStyle(fontFamily: 'Cairo'))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _campaignType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _discountType,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'نوع الاحتساب المالي', labelStyle: TextStyle(fontFamily: 'Cairo')),
                        items: const [
                          DropdownMenuItem(value: 'percentage', child: Text('نسبة مئوية من السلة (%)', style: TextStyle(fontFamily: 'Cairo'))),
                          DropdownMenuItem(value: 'fixed', child: Text('مبلغ خصم ثابت بالجنيه (ج.م)', style: TextStyle(fontFamily: 'Cairo'))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _discountType = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _valueController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: _discountType == 'percentage' ? 'نسبة الخصم (مثال: 15 للخصم 15%)' : 'قيمة الخصم الثابتة (مثال: 50 ج.م)',
                          labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        validator: (value) => double.tryParse(value ?? '') == null ? 'قيمة غير صالحة' : null,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('قابل للتراكم والدمج (Stackable)', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                        subtitle: const Text('يسمح بدمج كود الخصم مع العروض والتخفيضات الأخرى النشطة في نفس الفاتورة.', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                        value: _isStackable,
                        onChanged: (val) => setState(() => _isStackable = val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date limits & limit parameters block
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('صلاحية الحملة وحدود الاستخدام', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const Divider(),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.date_range_rounded),
                        title: const Text('تاريخ بدء الحملة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                        subtitle: Text(_startDate != null ? _startDate.toString().substring(0, 10) : 'غير محدد (فوري)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: OutlinedButton(
                          onPressed: _selectStartDate,
                          child: const Text('تعديل', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.date_range_rounded),
                        title: const Text('تاريخ انتهاء الحملة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                        subtitle: Text(_endDate != null ? _endDate.toString().substring(0, 10) : 'غير محدد (مستمر)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: OutlinedButton(
                          onPressed: _selectEndDate,
                          child: const Text('تعديل', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _limitController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الحد الأقصى لعدد الاستخدامات الكلي (اترك فارغاً لعدد غير محدود)',
                          labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveDiscount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(widget.discount != null ? 'حفظ التعديلات' : 'حفظ ونشر حملة الخصم الجديدة', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
