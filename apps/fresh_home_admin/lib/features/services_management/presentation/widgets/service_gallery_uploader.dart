import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/shared.dart';

class ServiceGalleryUploader extends StatefulWidget {
  final String serviceId;
  final List<ServiceGalleryItemEntity> initialGallery;
  final ValueChanged<List<ServiceGalleryItemEntity>> onGalleryChanged;

  const ServiceGalleryUploader({
    super.key,
    required this.serviceId,
    required this.initialGallery,
    required this.onGalleryChanged,
  });

  @override
  State<ServiceGalleryUploader> createState() => _ServiceGalleryUploaderState();
}

class _UploadTask {
  final String localPath;
  final String fileName;
  final Uint8List bytes;
  final String mimeType;
  double progress;
  bool isUploading;
  bool isFailed;
  String? errorMessage;
  String? uploadedUrl;

  _UploadTask({
    required this.localPath,
    required this.fileName,
    required this.bytes,
    required this.mimeType,
    this.isUploading = false,
  })  : progress = 0.0,
        isFailed = false,
        errorMessage = null,
        uploadedUrl = null;
}

class _ServiceGalleryUploaderState extends State<ServiceGalleryUploader> {
  late List<ServiceGalleryItemEntity> _gallery;
  final List<_UploadTask> _activeUploads = [];
  bool _isBatchUploading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _gallery = List.from(widget.initialGallery);
  }

  @override
  void didUpdateWidget(covariant ServiceGalleryUploader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGallery != widget.initialGallery) {
      setState(() {
        _gallery = List.from(widget.initialGallery);
      });
    }
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (pickedFiles.isEmpty) return;

      final List<_UploadTask> newTasks = [];
      for (final file in pickedFiles) {
        final bytes = await file.readAsBytes();
        final ext = file.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png'
            ? 'image/png'
            : ext == 'webp'
                ? 'image/webp'
                : 'image/jpeg';
        final uniqueName = 'gallery_${const Uuid().v4()}.$ext';

        newTasks.add(_UploadTask(
          localPath: file.path,
          fileName: uniqueName,
          bytes: bytes,
          mimeType: mimeType,
          isUploading: true,
        ));
      }

      setState(() {
        _activeUploads.addAll(newTasks);
        _isBatchUploading = true;
      });

      // Concurrent Uploads using Future.wait
      await Future.wait(
        newTasks.map((task) => _uploadSingleImage(task)),
      );

      setState(() {
        _isBatchUploading = _activeUploads.any((t) => t.isUploading);
      });

      widget.onGalleryChanged(_gallery);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء اختيار الصور: $e',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _uploadSingleImage(_UploadTask task) async {
    final supabase = Supabase.instance.client;
    final cleanServiceId = widget.serviceId.trim().isEmpty ? 'new_services' : widget.serviceId.trim();
    final storagePath = 'gallery/$cleanServiceId/${task.fileName}';

    try {
      setState(() {
        task.isUploading = true;
        task.progress = 0.3;
      });

      await supabase.storage.from('service_images').uploadBinary(
            storagePath,
            task.bytes,
            fileOptions: FileOptions(
              contentType: task.mimeType,
              upsert: true,
            ),
          );

      setState(() {
        task.progress = 0.8;
      });

      final publicUrl = supabase.storage.from('service_images').getPublicUrl(storagePath);

      final newItem = ServiceGalleryItemEntity(
        id: const Uuid().v4(),
        url: publicUrl,
      );

      if (mounted) {
        setState(() {
          task.isUploading = false;
          task.progress = 1.0;
          task.uploadedUrl = publicUrl;
          _gallery.add(newItem);
          _activeUploads.remove(task);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          task.isUploading = false;
          task.isFailed = true;
          task.errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل رفع إحدى الصور: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteImage(int index) async {
    final item = _gallery[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'تأكيد حذف الصورة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه الصورة نهائياً؟ سيتم إزالتها فعلياً من الخادم لتوفير المساحة.',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف نهائي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Physical purge from Supabase storage (Prevent Orphaned Files)
    try {
      final supabase = Supabase.instance.client;
      final uri = Uri.parse(item.url);
      final pathPrefix = '/storage/v1/object/public/service_images/';
      
      String? storagePath;
      if (uri.path.contains(pathPrefix)) {
        storagePath = uri.path.substring(uri.path.indexOf(pathPrefix) + pathPrefix.length);
        storagePath = Uri.decodeComponent(storagePath);
      } else if (!item.url.startsWith('http')) {
        storagePath = item.url;
      }

      if (storagePath != null && storagePath.isNotEmpty) {
        await supabase.storage.from('service_images').remove([storagePath]);
      }
    } catch (e) {
      debugPrint('⚠️ Error removing file physically from storage: $e');
    }

    setState(() {
      _gallery.removeAt(index);
    });

    widget.onGalleryChanged(_gallery);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم حذف الصورة نهائياً من المعرض والخادم',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.black87,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _moveImage(int from, int to) {
    if (to < 0 || to >= _gallery.length) return;
    setState(() {
      final item = _gallery.removeAt(from);
      _gallery.insert(to, item);
    });
    widget.onGalleryChanged(_gallery);
  }

  void _editCaption(int index) {
    final item = _gallery[index];
    final controller = TextEditingController(text: item.caption ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'تعديل وصف الصورة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'مثال: تنظيف عميق بضغط البخار',
            hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              final newCaption = controller.text.trim();
              setState(() {
                _gallery[index] = item.copyWith(caption: newCaption.isEmpty ? null : newCaption);
              });
              widget.onGalleryChanged(_gallery);
              Navigator.pop(ctx);
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row with Add Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.photo_library_rounded, color: themeColor.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      "معرض صور ونماذج الخدمة (${_gallery.length})",
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: themeColor.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "صور حية تظهر للعميل كأمثلة واقعية على جودة تنفيذ الخدمة",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: themeColor.unselectedItem,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _isBatchUploading ? null : _pickAndUploadImages,
              icon: _isBatchUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: Text(
                _isBatchUploading ? "جاري الرفع..." : "إضافة صور",
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Active Uploads Progress Bar
        if (_activeUploads.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: themeColor.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themeColor.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "جاري رفع ${_activeUploads.where((t) => t.isUploading).length} صورة سحابياً...",
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: themeColor.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    backgroundColor: themeColor.primary.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor.primary),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Empty State or Gallery Grid
        if (_gallery.isEmpty && _activeUploads.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: themeColor.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeColor.unselectedItem.withValues(alpha: 0.15),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 48,
                  color: themeColor.unselectedItem.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  "لا توجد صور نماذج مضافة لهذه الخدمة بعد",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: themeColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "اضغط على زر (إضافة صور) بالأعلى لرفع صور حية ونماذج أعمال سابقة",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: themeColor.unselectedItem,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[
          // Grid of Images
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _gallery.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final item = _gallery[index];
              return _buildGalleryCard(item, index, themeColor);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildGalleryCard(
    ServiceGalleryItemEntity item,
    int index,
    ThemeColorExtension themeColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.unselectedItem.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: item.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                    ),
                  ),

                  // Order Badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Delete Button
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Material(
                      color: Colors.redAccent.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _deleteImage(index),
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Controls & Caption Row
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Caption button / indicator
                  Expanded(
                    child: InkWell(
                      onTap: () => _editCaption(index),
                      borderRadius: BorderRadius.circular(6),
                      child: Text(
                        item.caption?.isNotEmpty == true ? item.caption! : "إضافة وصف...",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: item.caption?.isNotEmpty == true ? FontWeight.bold : FontWeight.normal,
                          color: item.caption?.isNotEmpty == true ? themeColor.textPrimary : themeColor.unselectedItem,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Move Left Button
                  if (index > 0)
                    InkWell(
                      onTap: () => _moveImage(index, index - 1),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: themeColor.textPrimary),
                      ),
                    ),

                  // Move Right Button
                  if (index < _gallery.length - 1)
                    InkWell(
                      onTap: () => _moveImage(index, index + 1),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Icon(Icons.arrow_back_ios_rounded, size: 12, color: themeColor.textPrimary),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
