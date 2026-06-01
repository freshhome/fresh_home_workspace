import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/tree_helpers.dart';
import '../widgets/shared_icon_picker_dialog.dart';
import '../../../../core/di/injection_container.dart' as di;

class ServiceConfiguratorWizardPage extends StatefulWidget {
  final ServiceEntity? initialData;
  final String? defaultParentId;
  final Future<void> Function(dynamic, BuildContext) onSubmit;

  const ServiceConfiguratorWizardPage({
    super.key,
    this.initialData,
    this.defaultParentId,
    required this.onSubmit,
  });

  @override
  State<ServiceConfiguratorWizardPage> createState() =>
      _ServiceConfiguratorWizardPageState();
}

class _ServiceConfiguratorWizardPageState
    extends State<ServiceConfiguratorWizardPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1: Basic Info Controller
  late TextEditingController _idController;
  late TextEditingController _titleEnController;
  late TextEditingController _titleArController;
  late TextEditingController _descEnController;
  late TextEditingController _descArController;
  late TextEditingController _imageController;
  late TextEditingController _orderController;
  late ServiceStatus _status;
  late bool _isBookable;
  String? _selectedParentId;
  bool _isUploadingImage = false;

  // Tree data for parent selection
  bool _isLoadingTree = true;
  List<ServiceEntity> _categoriesList = [];
  Map<String?, List<ServiceEntity>> _adjacencyList = {};

  // Step 2: Advanced Details State (Inclusions & Exclusions)
  late List<DetailEntity> _details;
  late NotIncludedEntity _notIncluded;

  // Step 3: Instructions State
  late TextEditingController _instructionsArController;
  late TextEditingController _instructionsEnController;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;

    // Basic Info Initialization - Auto generate UUID if new service
    _idController = TextEditingController(
      text: data?.id ?? const Uuid().v4(),
    );
    _titleEnController = TextEditingController(text: data?.title['en'] ?? '');
    _titleArController = TextEditingController(text: data?.title['ar'] ?? '');
    _descEnController = TextEditingController(text: data?.description['en'] ?? '');
    _descArController = TextEditingController(text: data?.description['ar'] ?? '');
    _imageController = TextEditingController(text: data?.image ?? '');
    _orderController = TextEditingController(text: data?.order.toString() ?? '0');
    _status = data?.status ?? ServiceStatus.active;
    _isBookable = data?.isBookable ?? true;
    _selectedParentId = data?.parentId ?? widget.defaultParentId;

    // Advanced Details Initialization
    _details = data?.details != null ? List.from(data!.details!) : [];
    
    const defaultLanguageContent = LanguageContentEntity(title: '', icon: '', points: []);
    _notIncluded = data?.notIncluded ?? 
        const NotIncludedEntity(ar: defaultLanguageContent, en: defaultLanguageContent);

    // Step 3 Instructions Initialization
    _instructionsArController = TextEditingController(
      text: data?.instructions?['ar'] ?? '',
    );
    _instructionsEnController = TextEditingController(
      text: data?.instructions?['en'] ?? '',
    );

    _loadTreeData();
  }

  Future<void> _loadTreeData() async {
    final getRoots = di.getIt<GetRootServicesUseCase>();
    final getChildren = di.getIt<GetChildrenUseCase>();
    final adj = await TreeHelpers.loadFullActiveTree(getRoots, getChildren);

    if (!mounted) return;

    final List<ServiceEntity> categories = [];
    adj.forEach((parent, list) {
      for (final service in list) {
        if (!service.isBookable) {
          categories.add(service);
        }
      }
    });

    final Set<String> excluded = {};
    if (widget.initialData != null) {
      final currentId = widget.initialData!.id;
      excluded.add(currentId);
      excluded.addAll(TreeHelpers.getDescendantIds(currentId, adj));
    }

    setState(() {
      _adjacencyList = adj;
      _categoriesList = categories.where((c) => !excluded.contains(c.id)).toList();
      _isLoadingTree = false;
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleEnController.dispose();
    _titleArController.dispose();
    _descEnController.dispose();
    _descArController.dispose();
    _imageController.dispose();
    _orderController.dispose();
    _instructionsArController.dispose();
    _instructionsEnController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final bytes = await pickedFile.readAsBytes();
      final extension = pickedFile.path.split('.').last.toLowerCase();
      final String mimeType;
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else {
        mimeType = 'image/jpeg';
      }
      final uploadBytes = bytes;

      final fileName = 'icon_${const Uuid().v4()}.$extension';
      final uploadUseCase = di.getIt<UploadServiceImageUseCase>();
      final isNewService = widget.initialData == null;
      
      final result = await uploadUseCase(
        bytes: uploadBytes,
        fileName: fileName,
        mimeType: mimeType,
        serviceId: isNewService ? null : _idController.text,
        isTemp: isNewService,
      );

      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل رفع الصورة: ${failure.message}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        (url) {
          setState(() {
            _imageController.text = url;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفع الصورة بنجاح!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء معالجة الصورة: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isBookable && _selectedParentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يجب اختيار فئة أب (Parent Category) للخدمة القابلة للحجز.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final id = _idController.text.trim();
    final title = {
      'en': _titleEnController.text.trim(),
      'ar': _titleArController.text.trim(),
    };
    final description = {
      'en': _descEnController.text.trim(),
      'ar': _descArController.text.trim(),
    };
    final image = _imageController.text.trim();
    final order = int.tryParse(_orderController.text.trim()) ?? 0;
    final instructions = {
      'ar': _instructionsArController.text.trim(),
      'en': _instructionsEnController.text.trim(),
    };

    if (_isBookable) {
      // SubServiceEntity creation
      const defaultPrice = PriceEntity(
        type: PricingMethod.unknown,
        value: 0,
        unit: '',
        options: [],
      );

      await widget.onSubmit(
        SubServiceEntity(
          id: id,
          parentId: _selectedParentId,
          isBookable: true,
          title: title,
          description: description,
          image: image,
          status: _status,
          order: order,
          updatedAt: DateTime.now(),
          price: widget.initialData?.price ?? defaultPrice,
          details: _details,
          notIncluded: _notIncluded,
          instructions: instructions,
        ),
        context,
      );
    } else {
      // ServiceEntity (Main Category) creation
      await widget.onSubmit(
        ServiceEntity(
          id: id,
          parentId: _selectedParentId,
          isBookable: false,
          title: title,
          description: description,
          image: image,
          status: _status,
          order: order,
          updatedAt: DateTime.now(),
          instructions: instructions,
        ),
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    final totalSteps = _isBookable ? 3 : 1;

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: Text(
          widget.initialData == null
              ? "إضافة خدمة / فئة جديدة"
              : "تعديل إعدادات الخدمة",
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: themeColor.cardBackground,
        elevation: 0,
        foregroundColor: themeColor.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Custom Stepper Header
            if (totalSteps > 1) _buildStepperHeader(themeColor, totalSteps),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_currentStep == 0) _buildBasicInfoStep(themeColor),
                      if (_currentStep == 1 && _isBookable) _buildDetailsStep(themeColor),
                      if (_currentStep == 2 && _isBookable) _buildInstructionsStep(themeColor),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Action Bar
            _buildBottomNavigation(themeColor, totalSteps),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Basic Info UI ---
  Widget _buildBasicInfoStep(ThemeColorExtension themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("البيانات التعريفية والأساسية"),
        BaseTextFormField(
          controller: _idController,
          hint: "معرف الخدمة الفريد (ID)",
          fillColor: themeColor.cardBackground,
          enabled: false,
          prefixIcon: Icon(Icons.fingerprint_rounded, color: themeColor.secondary),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "حقل مطلوب";
            }
            if (value.contains(' ')) {
              return "لا يمكن للمعرف احتواء مسافات فارغة";
            }
            if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(value)) {
              return "يجب أن يحتوي المعرف على أحرف إنجليزية، أرقام، _ أو - فقط";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: BaseTextFormField(
                controller: _titleArController,
                hint: "الاسم بالعربية",
                fillColor: themeColor.cardBackground,
                validator: (value) => value == null || value.trim().isEmpty ? "حقل مطلوب" : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BaseTextFormField(
                controller: _titleEnController,
                hint: "الاسم بالإنجليزية",
                fillColor: themeColor.cardBackground,
                validator: (value) => value == null || value.trim().isEmpty ? "حقل مطلوب" : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BaseTextFormField(
          controller: _descArController,
          hint: "الوصف القصير بالعربية",
          maxLines: 2,
          fillColor: themeColor.cardBackground,
        ),
        const SizedBox(height: 16),
        BaseTextFormField(
          controller: _descEnController,
          hint: "الوصف القصير بالإنجليزية",
          maxLines: 2,
          fillColor: themeColor.cardBackground,
        ),
        const SizedBox(height: 24),

        _buildSectionTitle("الهوية البصرية"),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColor.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeColor.unselectedItem.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: themeColor.serviceIconBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: themeColor.unselectedItem.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: _imageController.text.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _imageController.text,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: themeColor.primary,
                                ),
                              ),
                              errorWidget: (context, url, error) => _buildImagePlaceholder(themeColor),
                            )
                          : _buildImagePlaceholder(themeColor),
                    ),
                  ),
                  if (_isUploadingImage)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text(
                      _imageController.text.isEmpty ? "رفع أيقونة الخدمة" : "تغيير الصورة",
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_imageController.text.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: _isUploadingImage
                          ? null
                          : () {
                              setState(() {
                                _imageController.clear();
                              });
                            },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                      label: const Text(
                        "حذف الصورة",
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "الرجاء اختيار صورة مربعة بنسبة 1:1 بصيغة WebP أو PNG للحصول على أفضل جودة وأداء.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: themeColor.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: BaseTextFormField(
                controller: _orderController,
                hint: "ترتيب الظهور (Sort Order)",
                keyboardType: TextInputType.number,
                prefixIcon: Icon(Icons.sort_rounded, color: themeColor.secondary),
                fillColor: themeColor.cardBackground,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildStatusDropdown(themeColor)),
          ],
        ),
        const SizedBox(height: 24),

        _buildSectionTitle("نوع العنصر وموقعه في الشجرة"),
        _buildBookableToggle(themeColor),
        const SizedBox(height: 16),
        _buildParentCategoryDropdown(themeColor),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- Step 2: Details & Exclusions UI ---
  Widget _buildDetailsStep(ThemeColorExtension themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildSectionTitle("بنود وتفاصيل الخدمة المعروضة للعميل"),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _addDetailSection,
              icon: Icon(Icons.add_circle_outline_rounded, color: themeColor.secondary),
              label: Text(
                "إضافة قسم تفصيلي جديد",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: themeColor.secondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        if (_details.isEmpty) _buildEmptyStateWidget("لا توجد تفاصيل أو بنود مضافة حالياً. يمكنك تقسيم البنود لسهولة القراءة.")
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _details.length,
            itemBuilder: (context, idx) {
              final detail = _details[idx];
              return _buildDetailSectionCard(themeColor, detail, idx);
            },
          ),
        const SizedBox(height: 32),
        _buildSectionTitle("الاستثناءات (ما لا تشمله الخدمة)"),
        _buildNotIncludedSection(themeColor),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- Step 3: Instructions UI ---
  Widget _buildInstructionsStep(ThemeColorExtension themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("تعليمات العميل وإرشادات الحجز"),
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            "تظهر هذه التعليمات للعميل قبل تأكيد الحجز مباشرة، لتوضيح المتطلبات المسبقة أو الشروط.",
            style: TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Cairo'),
          ),
        ),
        BaseTextFormField(
          controller: _instructionsArController,
          hint: "التعليمات بالعربية...",
          maxLines: 5,
          fillColor: themeColor.cardBackground,
        ),
        const SizedBox(height: 16),
        BaseTextFormField(
          controller: _instructionsEnController,
          hint: "التعليمات بالإنجليزية...",
          maxLines: 5,
          fillColor: themeColor.cardBackground,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // Helper Widgets & State modifiers for Step 2 (Details)
  void _addDetailSection() {
    setState(() {
      _details.add(
        const DetailEntity(
          ar: LanguageContentEntity(title: '', icon: '', points: []),
          en: LanguageContentEntity(title: '', icon: '', points: []),
        ),
      );
    });
  }

  void _removeDetailSection(int index) {
    setState(() {
      _details.removeAt(index);
    });
  }

  Widget _buildDetailSectionCard(ThemeColorExtension themeColor, DetailEntity detail, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: themeColor.cardBackground,
      child: ExpansionTile(
        title: Text(
          detail.ar.title?.isNotEmpty == true ? detail.ar.title! : "قسم تفصيلي ${index + 1} (بدون عنوان)",
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: themeColor.textPrimary, fontSize: 14),
        ),
        leading: CircleAvatar(
          backgroundColor: themeColor.secondary.withValues(alpha: 0.1),
          child: Text("${index + 1}", style: TextStyle(color: themeColor.secondary, fontWeight: FontWeight.bold)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          onPressed: () => _removeDetailSection(index),
        ),
        childrenPadding: const EdgeInsets.all(16.0),
        children: [
          _buildLanguageContentFields(
            themeColor: themeColor,
            title: "المحتوى بالعربية",
            content: detail.ar,
            onChanged: (newContent) {
              setState(() {
                _details[index] = DetailEntity(id: detail.id, ar: newContent, en: detail.en);
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildLanguageContentFields(
            themeColor: themeColor,
            title: "المحتوى بالإنجليزية",
            content: detail.en,
            onChanged: (newContent) {
              setState(() {
                _details[index] = DetailEntity(id: detail.id, ar: detail.ar, en: newContent);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotIncludedSection(ThemeColorExtension themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildLanguageContentFields(
            themeColor: themeColor,
            title: "الاستثناءات بالعربية",
            content: _notIncluded.ar,
            onChanged: (newContent) {
              setState(() {
                _notIncluded = NotIncludedEntity(ar: newContent, en: _notIncluded.en);
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _buildLanguageContentFields(
            themeColor: themeColor,
            title: "الاستثناءات بالإنجليزية",
            content: _notIncluded.en,
            onChanged: (newContent) {
              setState(() {
                _notIncluded = NotIncludedEntity(ar: _notIncluded.ar, en: newContent);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageContentFields({
    required ThemeColorExtension themeColor,
    required String title,
    required LanguageContentEntity content,
    required ValueChanged<LanguageContentEntity> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: themeColor.secondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: BaseTextFormField(
                hint: "العنوان الرئيسي (مثال: ماذا تشمل الخدمة؟)",
                initialValue: content.title ?? '',
                fillColor: themeColor.background,
                onChanged: (val) {
                  onChanged(LanguageContentEntity(
                    title: val,
                    icon: content.icon,
                    iconPath: content.iconPath,
                    iconId: content.iconId,
                    points: content.points,
                  ));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final pickedIcon = await SharedIconPickerDialog.show(
                    context,
                    selectedIconId: content.iconId,
                  );
                  if (pickedIcon != null) {
                    onChanged(LanguageContentEntity(
                      title: content.title,
                      icon: pickedIcon.publicUrl,
                      iconPath: pickedIcon.storagePath,
                      iconId: pickedIcon.id,
                      points: content.points,
                    ));
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 52, // Standard height matching BaseTextFormField
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: themeColor.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: themeColor.unselectedItem.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: themeColor.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: themeColor.unselectedItem.withValues(alpha: 0.05),
                          ),
                        ),
                        child: content.icon != null && content.icon!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: content.icon!,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Center(
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 1.5),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.broken_image_outlined,
                                    size: 16,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              )
                            : Icon(Icons.add_photo_alternate_outlined, color: themeColor.primary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              content.icon != null && content.icon!.isNotEmpty
                                  ? "أيقونة مختارة"
                                  : "اختر أيقونة مشتركة",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (content.icon != null && content.icon!.isNotEmpty)
                              Text(
                                content.icon!.split('/').last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 8,
                                  color: Colors.grey.shade500,
                                ),
                              )
                            else
                              Text(
                                "اضغط لفتح المكتبة",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 8,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (content.icon != null && content.icon!.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
                          onPressed: () {
                            onChanged(LanguageContentEntity(
                              title: content.title,
                              icon: '',
                              iconPath: '',
                              iconId: '',
                              points: content.points,
                            ));
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "نقاط القائمة (Bullet Points)",
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
            ),
            TextButton.icon(
              onPressed: () {
                final points = List<String>.from(content.points ?? []);
                points.add('');
                onChanged(LanguageContentEntity(
                  title: content.title,
                  icon: content.icon,
                  iconPath: content.iconPath,
                  iconId: content.iconId,
                  points: points,
                ));
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text("إضافة نقطة", style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        if (content.points == null || content.points!.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("لا توجد نقاط مضافة", style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
          )
        else
          ...content.points!.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: BaseTextFormField(
                      hint: "محتوى النقطة ${entry.key + 1}",
                      initialValue: entry.value,
                      fillColor: themeColor.background,
                      onChanged: (val) {
                        final points = List<String>.from(content.points!);
                        points[entry.key] = val;
                        onChanged(LanguageContentEntity(
                          title: content.title,
                          icon: content.icon,
                          iconPath: content.iconPath,
                          iconId: content.iconId,
                          points: points,
                        ));
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.amber),
                    onPressed: () {
                      final points = List<String>.from(content.points!);
                      points.removeAt(entry.key);
                      onChanged(LanguageContentEntity(
                        title: content.title,
                        icon: content.icon,
                        iconPath: content.iconPath,
                        iconId: content.iconId,
                        points: points,
                      ));
                    },
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // --- Sub-widgets for Step 1 ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.themeColor.primary, context.themeColor.secondary],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: context.themeColor.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeColorExtension themeColor) {
    return Center(
      child: Icon(
        Icons.cleaning_services_rounded,
        size: 24,
        color: themeColor.primary.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildStatusDropdown(ThemeColorExtension themeColor) {
    return DropdownButtonFormField<ServiceStatus>(
      initialValue: _status,
      isExpanded: true,
      dropdownColor: themeColor.cardBackground,
      style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: themeColor.textPrimary),
      decoration: InputDecoration(
        labelText: "حالة الخدمة",
        labelStyle: TextStyle(color: themeColor.unselectedItem, fontSize: 12, fontFamily: 'Cairo'),
        prefixIcon: Icon(Icons.info_outline, color: themeColor.secondary, size: 20),
        filled: true,
        fillColor: themeColor.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
        ),
      ),
      items: ServiceStatus.values.map((status) {
        return DropdownMenuItem<ServiceStatus>(
          value: status,
          child: Text(status.arabicLabel, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _status = value;
          });
        }
      },
    );
  }

  Widget _buildBookableToggle(ThemeColorExtension themeColor) {
    return Container(
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      child: SwitchListTile(
        title: const Text(
          "خدمة نهائية قابلة للحجز (Bookable Service)",
          style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          "تفعيل الخيار يجعل الخدمة قابلة للطلب المباشر من العميل. إلغاء التفعيل يجعلها تصنيفاً رئيسياً أو فرعياً فقط.",
          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
        ),
        value: _isBookable,
        activeThumbColor: themeColor.secondary,
        activeTrackColor: themeColor.secondary.withValues(alpha: 0.2),
        onChanged: (value) {
          if (value && widget.initialData != null) {
            final children = _adjacencyList[widget.initialData!.id] ?? [];
            if (children.isNotEmpty) {
              _showChildrenWarningDialog(children.length);
              return;
            }
          }
          setState(() {
            _isBookable = value;
            if (!_isBookable && _currentStep > 0) {
              _currentStep = 0; // Categories only have step 1
            }
          });
        },
      ),
    );
  }

  Widget _buildParentCategoryDropdown(ThemeColorExtension themeColor) {
    if (_isLoadingTree) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String?>(
      initialValue: _selectedParentId,
      isExpanded: true,
      dropdownColor: themeColor.cardBackground,
      style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: themeColor.textPrimary),
      decoration: InputDecoration(
        labelText: "الفئة الأب (Parent Category)",
        labelStyle: TextStyle(color: themeColor.unselectedItem, fontSize: 12, fontFamily: 'Cairo'),
        prefixIcon: Icon(Icons.folder_open_rounded, color: themeColor.secondary, size: 20),
        filled: true,
        fillColor: themeColor.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: themeColor.unselectedItem.withValues(alpha: 0.1)),
        ),
      ),
      validator: (value) {
        if (_isBookable && value == null) {
          return "يجب اختيار فئة أب للخدمة القابلة للحجز";
        }
        return null;
      },
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text("تصنيف رئيسي (بدون أب)", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        ..._categoriesList.map((cat) {
          final displayTitle = cat.title['ar'] ?? cat.title['en'] ?? 'بدون عنوان';
          return DropdownMenuItem<String?>(
            value: cat.id,
            child: Text(displayTitle, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedParentId = value;
        });
      },
    );
  }

  void _showChildrenWarningDialog(int childrenCount) {
    final themeColor = context.themeColor;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: themeColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "تنبيه: لا يمكن تحويل الفئة",
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Text(
          "هذه الفئة تحتوي على عدد ($childrenCount) من الخدمات/الفئات التابعة. لا يمكنك تحويلها إلى خدمة قابلة للحجز مباشرة إلا بعد نقل أو أرشفة الخدمات التابعة أولاً.",
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 13),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("حسناً", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeColor.unselectedItem.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.layers_clear_outlined, size: 40, color: context.themeColor.unselectedItem.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // --- Custom Stepper Header Widget ---
  Widget _buildStepperHeader(ThemeColorExtension themeColor, int totalSteps) {
    final stepTitles = ["البيانات الأساسية", "تفاصيل البنود", "تعليمات الحجز"];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: themeColor.cardBackground,
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            final int lineIdx = index ~/ 2;
            final isActive = lineIdx < _currentStep;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(colors: [themeColor.secondary, themeColor.secondary])
                      : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          final stepIdx = index ~/ 2;
          final isCurrent = stepIdx == _currentStep;
          final isCompleted = stepIdx < _currentStep;

          return InkWell(
            onTap: () {
              if (isCompleted || stepIdx == 0 || (_formKey.currentState?.validate() ?? false)) {
                setState(() {
                  _currentStep = stepIdx;
                });
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isCurrent || isCompleted
                        ? LinearGradient(colors: [themeColor.primary, themeColor.secondary])
                        : null,
                    color: !isCurrent && !isCompleted ? Colors.grey.shade200 : null,
                    boxShadow: isCurrent
                        ? [BoxShadow(color: themeColor.secondary.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)]
                        : [],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : Text(
                            "${stepIdx + 1}",
                            style: TextStyle(
                              color: isCurrent || isCompleted ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Text(
                    stepTitles[stepIdx],
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: themeColor.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- Bottom Navigation Actions Bar ---
  Widget _buildBottomNavigation(ThemeColorExtension themeColor, int totalSteps) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Next / Save Button
          Expanded(
            child: MyCustomButton(
              text: _currentStep == totalSteps - 1 ? "حفظ التغييرات" : "التالي",
              onPressed: () {
                if (_currentStep == totalSteps - 1) {
                  _submit();
                } else {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _currentStep++;
                    });
                  }
                }
              },
              backgroundColor: themeColor.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white),
            ),
          ),
          
          // Back Button
          if (_currentStep > 0) ...[
            const SizedBox(width: 16),
            Expanded(
              child: MyCustomButton(
                text: "السابق",
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                isOutlined: true,
                borderColor: themeColor.unselectedItem.withValues(alpha: 0.3),
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: themeColor.textPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
