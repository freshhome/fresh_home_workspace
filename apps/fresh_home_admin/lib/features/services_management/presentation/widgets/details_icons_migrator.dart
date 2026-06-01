import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

class MigrationResult {
  final int totalServicesScanned;
  final int totalIconsFound;
  final int totalIconsMigrated;
  final int totalServicesUpdated;
  final List<String> errors;

  MigrationResult({
    required this.totalServicesScanned,
    required this.totalIconsFound,
    required this.totalIconsMigrated,
    required this.totalServicesUpdated,
    required this.errors,
  });
}

class DetailsIconsMigrator {
  static Future<MigrationResult> runMigration(
    BuildContext context, {
    required Function(String status) onProgress,
  }) async {
    final List<String> errors = [];
    int totalServicesScanned = 0;
    int totalIconsFound = 0;
    int totalIconsMigrated = 0;
    int totalServicesUpdated = 0;

    final supabase = Supabase.instance.client;

    try {
      onProgress("جاري جلب الخدمات من قاعدة البيانات...");
      // 1. Fetch all services
      final servicesResponse = await supabase.from('services').select('*');
      final List<dynamic> services = servicesResponse as List<dynamic>;
      totalServicesScanned = services.length;

      // Map to keep track of unique icons: URL -> Map of metadata
      final Map<String, Map<String, dynamic>> uniqueIcons = {};

      onProgress("جاري فحص الخدمات لاستخراج الأيقونات...");
      // 2. Scan services for legacy icons
      for (final service in services) {
        final details = service['details'] as List<dynamic>? ?? [];
        final notIncluded = service['not_included'] as Map<String, dynamic>? ?? {};

        // Scan details
        for (final detail in details) {
          final arContent = detail['ar'] as Map<String, dynamic>? ?? {};
          final enContent = detail['en'] as Map<String, dynamic>? ?? {};

          final arIcon = arContent['icon'] as String?;
          final enIcon = enContent['icon'] as String?;
          
          final arTitle = arContent['title'] as String? ?? 'أيقونة تفصيلية';
          final enTitle = enContent['title'] as String? ?? 'Detail Icon';

          // If icon URL is present but icon_id is empty, it needs migration
          if (arIcon != null && arIcon.isNotEmpty && (arContent['icon_id'] == null || arContent['icon_id'].toString().isEmpty)) {
            uniqueIcons.putIfAbsent(arIcon, () => {
              'url': arIcon,
              'name_ar': arTitle,
              'name_en': enTitle,
              'category': 'general',
            });
          }
          if (enIcon != null && enIcon.isNotEmpty && (enContent['icon_id'] == null || enContent['icon_id'].toString().isEmpty)) {
            uniqueIcons.putIfAbsent(enIcon, () => {
              'url': enIcon,
              'name_ar': arTitle,
              'name_en': enTitle,
              'category': 'general',
            });
          }
        }

        // Scan notIncluded
        final arNotInc = notIncluded['ar'] as Map<String, dynamic>? ?? {};
        final enNotInc = notIncluded['en'] as Map<String, dynamic>? ?? {};

        final arNotIncIcon = arNotInc['icon'] as String?;
        final enNotIncIcon = enNotInc['icon'] as String?;

        if (arNotIncIcon != null && arNotIncIcon.isNotEmpty && (arNotInc['icon_id'] == null || arNotInc['icon_id'].toString().isEmpty)) {
          uniqueIcons.putIfAbsent(arNotIncIcon, () => {
            'url': arNotIncIcon,
            'name_ar': arNotInc['title'] ?? 'استثناء',
            'name_en': enNotInc['title'] ?? 'Exclusion',
            'category': 'general',
          });
        }
        if (enNotIncIcon != null && enNotIncIcon.isNotEmpty && (enNotInc['icon_id'] == null || enNotInc['icon_id'].toString().isEmpty)) {
          uniqueIcons.putIfAbsent(enNotIncIcon, () => {
            'url': enNotIncIcon,
            'name_ar': arNotInc['title'] ?? 'استثناء',
            'name_en': enNotInc['title'] ?? 'Exclusion',
            'category': 'general',
          });
        }
      }

      totalIconsFound = uniqueIcons.length;
      if (totalIconsFound == 0) {
        return MigrationResult(
          totalServicesScanned: totalServicesScanned,
          totalIconsFound: 0,
          totalIconsMigrated: 0,
          totalServicesUpdated: 0,
          errors: errors,
        );
      }

      // Map to match URL -> Shared Icon data
      final Map<String, Map<String, dynamic>> migratedIconsMap = {};

      // 3. Process and upload each icon
      int processedCount = 0;
      final httpClient = HttpClient();

      for (final iconUrl in uniqueIcons.keys) {
        processedCount++;
        onProgress("جاري معالجة ورفع الأيقونة $processedCount من $totalIconsFound...");

        final meta = uniqueIcons[iconUrl]!;
        final nameAr = meta['name_ar'];
        final nameEn = meta['name_en'];
        final category = meta['category'];

        try {
          // Check if already exists in shared_icons db to prevent duplicate uploads
          final checkResponse = await supabase
              .from('shared_icons')
              .select('*')
              .eq('public_url', iconUrl);

          if (checkResponse.isNotEmpty) {
            final existingIcon = checkResponse.first;
            migratedIconsMap[iconUrl] = {
              'id': existingIcon['id'],
              'public_url': existingIcon['public_url'],
              'storage_path': existingIcon['storage_path'],
            };
            continue;
          }

          // Download image bytes
          final uri = Uri.parse(iconUrl);
          final request = await httpClient.getUrl(uri);
          final response = await request.close();
          if (response.statusCode != 200) {
            throw Exception('فشل تحميل الصورة: رمز الاستجابة ${response.statusCode}');
          }

          final bytes = await response.expand((chunk) => chunk).toList();
          final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'icon.png';
          final extension = filename.split('.').last.toLowerCase();

          List<int> uploadBytes;
          String uploadMimeType;
          String uploadExtension;

          if (extension == 'webp') {
            uploadBytes = bytes;
            uploadMimeType = 'image/webp';
            uploadExtension = 'webp';
          } else {
            // Resize using package:image
            final decoded = img.decodeImage(Uint8List.fromList(bytes));
            if (decoded == null) {
              throw Exception('فشل فك ترميز الصورة لمعالجة الحجم');
            }

            final resized = img.copyResize(decoded, width: 256, height: 256);
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

          // Upload to storage bucket
          final iconUuid = const Uuid().v4();
          final storagePath = 'service_assets/service_icons/shared_icons/$iconUuid.$uploadExtension';

          await supabase.storage
              .from('service_images')
              .uploadBinary(
                storagePath,
                Uint8List.fromList(uploadBytes),
                fileOptions: FileOptions(contentType: uploadMimeType, upsert: true),
              );

          final publicUrl = supabase.storage.from('service_images').getPublicUrl(storagePath);

          // Insert shared_icon db record
          final insertResponse = await supabase
              .from('shared_icons')
              .insert({
                'id': iconUuid,
                'name': {'ar': nameAr, 'en': nameEn},
                'storage_path': storagePath,
                'public_url': publicUrl,
                'category': category,
                'usage_count': 0,
              })
              .select()
              .single();

          migratedIconsMap[iconUrl] = {
            'id': insertResponse['id'],
            'public_url': insertResponse['public_url'],
            'storage_path': insertResponse['storage_path'],
          };

          totalIconsMigrated++;
        } catch (e) {
          errors.add("فشل ترحيل الأيقونة ($iconUrl): $e");
        }
      }

      // 4. Update services with new JSONB structures
      int serviceUpdateIndex = 0;
      for (final service in services) {
        serviceUpdateIndex++;
        onProgress("جاري تحديث بيانات الخدمة $serviceUpdateIndex من $totalServicesScanned...");

        final serviceId = service['id'];
        final details = service['details'] as List<dynamic>?;
        final notIncluded = service['not_included'] as Map<String, dynamic>?;

        bool isServiceModified = false;
        List<dynamic>? updatedDetails;
        Map<String, dynamic>? updatedNotIncluded;

        if (details != null) {
          updatedDetails = [];
          for (final detail in details) {
            final arContent = Map<String, dynamic>.from(detail['ar'] as Map? ?? {});
            final enContent = Map<String, dynamic>.from(detail['en'] as Map? ?? {});

            final arIcon = arContent['icon'] as String?;
            final enIcon = enContent['icon'] as String?;

            if (arIcon != null && migratedIconsMap.containsKey(arIcon)) {
              final migrated = migratedIconsMap[arIcon]!;
              arContent['icon_id'] = migrated['id'];
              arContent['icon_path'] = migrated['storage_path'];
              arContent['icon'] = migrated['public_url'];
              isServiceModified = true;
            }
            if (enIcon != null && migratedIconsMap.containsKey(enIcon)) {
              final migrated = migratedIconsMap[enIcon]!;
              enContent['icon_id'] = migrated['id'];
              enContent['icon_path'] = migrated['storage_path'];
              enContent['icon'] = migrated['public_url'];
              isServiceModified = true;
            }

            updatedDetails.add({
              'id': detail['id'],
              'ar': arContent,
              'en': enContent,
            });
          }
        }

        if (notIncluded != null) {
          updatedNotIncluded = {
            'ar': Map<String, dynamic>.from(notIncluded['ar'] as Map? ?? {}),
            'en': Map<String, dynamic>.from(notIncluded['en'] as Map? ?? {}),
          };

          final arIcon = updatedNotIncluded['ar']?['icon'] as String?;
          final enIcon = updatedNotIncluded['en']?['icon'] as String?;

          if (arIcon != null && migratedIconsMap.containsKey(arIcon)) {
            final migrated = migratedIconsMap[arIcon]!;
            updatedNotIncluded['ar']!['icon_id'] = migrated['id'];
            updatedNotIncluded['ar']!['icon_path'] = migrated['storage_path'];
            updatedNotIncluded['ar']!['icon'] = migrated['public_url'];
            isServiceModified = true;
          }
          if (enIcon != null && migratedIconsMap.containsKey(enIcon)) {
            final migrated = migratedIconsMap[enIcon]!;
            updatedNotIncluded['en']!['icon_id'] = migrated['id'];
            updatedNotIncluded['en']!['icon_path'] = migrated['storage_path'];
            updatedNotIncluded['en']!['icon'] = migrated['public_url'];
            isServiceModified = true;
          }
        }

        if (isServiceModified) {
          final Map<String, dynamic> updateData = {};
          if (updatedDetails != null) updateData['details'] = updatedDetails;
          if (updatedNotIncluded != null) updateData['not_included'] = updatedNotIncluded;

          await supabase
              .from('services')
              .update(updateData)
              .eq('id', serviceId);

          // Update usage counts in shared_icons
          if (updatedDetails != null) {
            for (final detail in updatedDetails) {
              final arIconId = detail['ar']?['icon_id'];
              final enIconId = detail['en']?['icon_id'];
              if (arIconId != null) {
                await supabase.rpc('increment_shared_icon_usage', params: {'p_icon_id': arIconId});
              }
              if (enIconId != null) {
                await supabase.rpc('increment_shared_icon_usage', params: {'p_icon_id': enIconId});
              }
            }
          }
          if (updatedNotIncluded != null) {
            final arIconId = updatedNotIncluded['ar']?['icon_id'];
            final enIconId = updatedNotIncluded['en']?['icon_id'];
            if (arIconId != null) {
              await supabase.rpc('increment_shared_icon_usage', params: {'p_icon_id': arIconId});
            }
            if (enIconId != null) {
              await supabase.rpc('increment_shared_icon_usage', params: {'p_icon_id': enIconId});
            }
          }

          totalServicesUpdated++;
        }
      }

      httpClient.close();
    } catch (e) {
      errors.add("حدث خطأ عام أثناء الترحيل: $e");
    }

    return MigrationResult(
      totalServicesScanned: totalServicesScanned,
      totalIconsFound: totalIconsFound,
      totalIconsMigrated: totalIconsMigrated,
      totalServicesUpdated: totalServicesUpdated,
      errors: errors,
    );
  }
}
