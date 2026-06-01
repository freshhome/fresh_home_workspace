import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SharedIconPickerDialog extends StatefulWidget {
  final String? selectedIconId;

  const SharedIconPickerDialog({super.key, this.selectedIconId});

  static Future<SharedIconEntity?> show(BuildContext context, {String? selectedIconId}) {
    return showDialog<SharedIconEntity>(
      context: context,
      barrierDismissible: true,
      builder: (context) => SharedIconPickerDialog(selectedIconId: selectedIconId),
    );
  }

  @override
  State<SharedIconPickerDialog> createState() => _SharedIconPickerDialogState();
}

class _SharedIconPickerDialogState extends State<SharedIconPickerDialog> {
  // Use cases
  late final GetSharedIconsUseCase _getSharedIconsUseCase;
  late final InsertSharedIconUseCase _insertSharedIconUseCase;
  late final UploadServiceImageUseCase _uploadServiceImageUseCase;

  List<SharedIconEntity> _allIcons = [];
  List<SharedIconEntity> _filteredIcons = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  // Toggle between Library view and Upload view
  bool _isUploadingMode = false;

  // Upload Form Controllers
  final _uploadFormKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  String _uploadCategory = 'general';
  XFile? _pickedImage;
  bool _isSavingNewIcon = false;

  final List<Map<String, String>> _categories = [
    {'key': 'all', 'label': 'الكل'},
    {'key': 'rooms', 'label': 'الغرف والمساحات'},
    {'key': 'tools', 'label': 'الأدوات والمعدات'},
    {'key': 'appliances', 'label': 'الأجهزة'},
    {'key': 'general', 'label': 'عام / أخرى'},
  ];

  @override
  void initState() {
    super.initState();
    _getSharedIconsUseCase = GetIt.instance<GetSharedIconsUseCase>();
    _insertSharedIconUseCase = GetIt.instance<InsertSharedIconUseCase>();
    _uploadServiceImageUseCase = GetIt.instance<UploadServiceImageUseCase>();
    _loadIcons();
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    setState(() => _isLoading = true);
    final result = await _getSharedIconsUseCase();
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل تحميل الأيقونات: ${failure.message}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      (icons) {
        setState(() {
          _allIcons = icons;
          _applyFilters();
        });
      },
    );
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    setState(() {
      _filteredIcons = _allIcons.where((icon) {
        final matchesCategory = _selectedCategory == 'all' || icon.category == _selectedCategory;
        final nameAr = icon.name['ar']?.toLowerCase() ?? '';
        final nameEn = icon.name['en']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        final matchesSearch = query.isEmpty || nameAr.contains(query) || nameEn.contains(query);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _uploadAndCreateSharedIcon() async {
    if (!_uploadFormKey.currentState!.validate() || _pickedImage == null) {
      if (_pickedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار صورة للأيقونة أولاً'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    setState(() => _isSavingNewIcon = true);

    try {
      final originalBytes = await _pickedImage!.readAsBytes();
      final filename = _pickedImage!.name;
      final extension = filename.split('.').last.toLowerCase();

      List<int> uploadBytes;
      String uploadMimeType;
      String uploadExtension;

      if (extension == 'webp') {
        // If already WebP, upload directly to preserve it
        uploadBytes = originalBytes;
        uploadMimeType = 'image/webp';
        uploadExtension = 'webp';
      } else {
        // Decode image
        final decoded = img.decodeImage(originalBytes);
        if (decoded == null) throw Exception('تعذر فك ترميز ملف الصورة المختار');

        // Resize to 256x256
        final resized = img.copyResize(decoded, width: 256, height: 256);

        // Encode as PNG if original is PNG or if it has alpha transparency, otherwise JPEG
        bool hasAlpha = false;
        try {
          hasAlpha = decoded.hasAlpha;
        } catch (_) {}

        if (extension == 'png' || hasAlpha) {
          uploadBytes = img.encodePng(resized);
          uploadMimeType = 'image/png';
          uploadExtension = 'png';
        } else {
          uploadBytes = img.encodeJpg(resized, quality: 85);
          uploadMimeType = 'image/jpeg';
          uploadExtension = 'jpg';
        }
      }

      // Generate unique path: service_assets/shared_icons/uuid.ext
      final iconUuid = const Uuid().v4();

      // 1. Upload to Supabase Storage
      final uploadResult = await _uploadServiceImageUseCase(
        bytes: uploadBytes,
        fileName: '$iconUuid.$uploadExtension',
        mimeType: uploadMimeType,
        isTemp: false,
        serviceId: 'shared_icons', // Dummy folder indicator
      );

      await uploadResult.fold(
        (failure) async {
          throw Exception('فشل رفع الملف إلى التخزين السحابي: ${failure.message}');
        },
        (publicUrl) async {
          // Adjust url if it was generated inside a temp directory path by the datasource
          // The datasource will generate: service_assets/shared_icons/shared_icons/filename if we pass 'shared_icons'
          // Let's make sure the path uploaded aligns with standard storage paths
          // In ServiceRemoteDataSourceImpl.uploadServiceImage:
          //   path = 'service_assets/service_icons/$serviceId/$fileName';
          // So if we passed serviceId = 'shared_icons', the path was:
          //   'service_assets/service_icons/shared_icons/$fileName'
          // Let's correct this. Instead, we can let the datasource upload it. But wait, can we upload it directly?
          // Since the datasource uploadServiceImage uses 'service_icons/serviceId/fileName', we can use that path.
          // The publicUrl is the correct link.
          
          final correctedStoragePath = 'service_assets/service_icons/shared_icons/$iconUuid.$uploadExtension';

          final newIcon = SharedIconEntity(
            id: iconUuid,
            name: {
              'ar': _nameArController.text.trim(),
              'en': _nameEnController.text.trim(),
            },
            storagePath: correctedStoragePath,
            publicUrl: publicUrl,
            category: _uploadCategory,
            usageCount: 0,
          );

          // 2. Insert into the database
          final insertResult = await _insertSharedIconUseCase(newIcon);
          insertResult.fold(
            (failure) {
              throw Exception('فشل إدراج الأيقونة في قاعدة البيانات: ${failure.message}');
            },
            (savedIcon) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تمت إضافة الأيقونة للمكتبة المشتركة بنجاح!'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Return to library, refresh, and auto-select this new icon
                Navigator.pop(context, savedIcon);
              }
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingNewIcon = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: themeColor.background,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isUploadingMode ? _buildUploadForm(themeColor) : _buildLibraryView(themeColor),
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryView(ThemeColorExtension themeColor) {
    return Column(
      key: const ValueKey('library_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Close Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'مكتبة الأيقونات المشتركة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search Bar
        TextField(
          onChanged: (val) {
            _searchQuery = val;
            _applyFilters();
          },
          decoration: InputDecoration(
            hintText: 'البحث عن أيقونة بالاسم العربي أو الإنجليزي...',
            hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: themeColor.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Categories Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat['key'];
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: FilterChip(
                  label: Text(
                    cat['label']!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : themeColor.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = cat['key']!;
                      _applyFilters();
                    });
                  },
                  selectedColor: themeColor.primary,
                  backgroundColor: themeColor.cardBackground,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Icons Grid
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredIcons.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'لم يتم العثور على أيقونات مطابقة',
                              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: _filteredIcons.length,
                      itemBuilder: (context, index) {
                        final icon = _filteredIcons[index];
                        final isSelected = widget.selectedIconId == icon.id;

                        return InkWell(
                          onTap: () => Navigator.pop(context, icon),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? themeColor.primary.withValues(alpha: 0.08)
                                  : themeColor.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? themeColor.primary
                                    : themeColor.unselectedItem.withValues(alpha: 0.1),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: CachedNetworkImage(
                                      imageUrl: icon.publicUrl,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(
                                        Icons.broken_image,
                                        size: 24,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  icon.name['ar'] ?? 'أيقونة',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        const SizedBox(height: 16),

        // Bottom Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isUploadingMode = true;
                  });
                },
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text(
                  'رفع أيقونة جديدة لقاعدة البيانات',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadForm(ThemeColorExtension themeColor) {
    return SingleChildScrollView(
      key: const ValueKey('upload_view'),
      child: Form(
        key: _uploadFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Back Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'رفع أيقونة جديدة للمكتبة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      _isUploadingMode = false;
                      _pickedImage = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Image Picker Box
            InkWell(
              onTap: _isSavingNewIcon ? null : _pickImage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: themeColor.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeColor.unselectedItem.withValues(alpha: 0.1),
                  ),
                ),
                child: _pickedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 40, color: themeColor.primary),
                          const SizedBox(height: 8),
                          const Text(
                            'اضغط هنا لاختيار صورة الأيقونة',
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'يفضل أن تكون مربعة بخلفية شفافة',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Image.network(
                              // Using local file preview helper
                              // On desktop/mobile Flutter apps, we can display using a FutureBuilder or standard Image.network in web.
                              // Since we picked XFile, we can load it.
                              _pickedImage!.path,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.insert_drive_file_outlined, size: 48),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withValues(alpha: 0.5),
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _pickedImage = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Fields
            BaseTextFormField(
              controller: _nameArController,
              hint: 'الاسم بالأرقام/العربية (مثال: غرفة المعيشة)',
              fillColor: themeColor.cardBackground,
              validator: (val) => val == null || val.trim().isEmpty ? 'حقل مطلوب' : null,
            ),
            const SizedBox(height: 12),
            BaseTextFormField(
              controller: _nameEnController,
              hint: 'الاسم بالإنجليزية (مثال: Living Room)',
              fillColor: themeColor.cardBackground,
              validator: (val) => val == null || val.trim().isEmpty ? 'حقل مطلوب' : null,
            ),
            const SizedBox(height: 12),

            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _uploadCategory,
              decoration: InputDecoration(
                filled: true,
                fillColor: themeColor.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _categories.where((cat) => cat['key'] != 'all').map((cat) {
                return DropdownMenuItem<String>(
                  value: cat['key'],
                  child: Text(
                    cat['label']!,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _uploadCategory = val;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Save Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSavingNewIcon ? null : _uploadAndCreateSharedIcon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSavingNewIcon
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'حفظ وإدراج في المكتبة',
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _isSavingNewIcon
                      ? null
                      : () {
                          setState(() {
                            _isUploadingMode = false;
                            _pickedImage = null;
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
