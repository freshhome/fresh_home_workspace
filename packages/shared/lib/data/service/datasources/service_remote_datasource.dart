import 'dart:typed_data';
import 'package:shared/data/service/models/remote/service_remote_model.dart';
import 'package:shared/data/service/models/remote/sub_models/shared_icon_remote_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/service/entities/service.dart';
import '../../../domain/technician/entities/technician.dart';

abstract class ServiceRemoteDataSource {
  Future<List<ServiceRemoteModel>> getServices();
  Future<List<ServiceRemoteModel>> getServicesUpdatedSince(DateTime timestamp);
  Future<ServiceRemoteModel> getServiceById(String id);
  Future<ServiceRemoteModel> insertService(ServiceRemoteModel service);
  Future<ServiceRemoteModel> updateService(ServiceRemoteModel service);
  Future<List<ServiceRemoteModel>> getMainServices();
  Future<List<ServiceRemoteModel>> getSubServices({
    required String mainServiceId,
  });
  Future<List<ServiceAvailability>> getAvailability(String subServiceId);
  Future<List<Technician>> getTechnicians();
  Future<List<Technician>> getTechniciansForService(String subServiceId);
  Future<List<String>> getActiveServiceIds();
  Future<double> calculatePrice({
    required String subServiceId,
    required Map<String, dynamic> formValues,
    required List<String> selectedOptions,
  });
  Future<String> uploadServiceImage({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String? serviceId,
    bool isTemp = false,
  });
  Future<void> deleteServiceImage(String imageUrl);
  Future<List<SharedIconRemoteModel>> getSharedIcons();
  Future<SharedIconRemoteModel> insertSharedIcon(SharedIconRemoteModel icon);
  Future<void> deleteSharedIcon(String id);
}

class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  final SupabaseClient _supabase;

  ServiceRemoteDataSourceImpl(this._supabase);

  @override
  Future<ServiceRemoteModel> insertService(ServiceRemoteModel service) async {
    String? imageUrl = service.image;
    if (imageUrl != null && imageUrl.contains('/temp/service_icons/')) {
      try {
        final Uri uri = Uri.parse(imageUrl);
        final String tempPrefix = '/storage/v1/object/public/service_images/';
        if (uri.path.contains(tempPrefix)) {
          final String tempPath = uri.path.substring(
            uri.path.indexOf(tempPrefix) + tempPrefix.length,
          );
          final decodedTempPath = Uri.decodeComponent(tempPath);
          final fileName = decodedTempPath.split('/').last;

          final finalPath = 'service_assets/service_icons/${service.id}/$fileName';

          // Copy from temp to final destination
          await _supabase.storage
              .from('service_images')
              .copy(decodedTempPath, finalPath);

          // Delete temp in background
          _supabase.storage
              .from('service_images')
              .remove([decodedTempPath])
              .catchError((e) {
                print('⚠️ Error deleting temp image: $e');
                return <FileObject>[];
              });

          final newImageUrl = _supabase.storage
              .from('service_images')
              .getPublicUrl(finalPath);
          service = service.copyWith(image: newImageUrl);
        }
      } catch (e) {
        print('⚠️ Error moving temp image to final folder: $e');
      }
    }

    final response = await _supabase
        .from('services')
        .insert(service.toJson())
        .select()
        .single();
    final inserted = ServiceRemoteModel.fromJson(Map<String, dynamic>.from(response));

    // Update usage count for referenced icons
    try {
      final newIds = _extractIconIds(inserted);
      if (newIds.isNotEmpty) {
        await _updateIconUsages(oldIds: {}, newIds: newIds);
      }
    } catch (e) {
      print('⚠️ Error updating icon usage counts for new service: $e');
    }

    return inserted;
  }

  @override
  Future<ServiceRemoteModel> updateService(ServiceRemoteModel service) async {
    Set<String> oldIds = {};
    try {
      final oldService = await getServiceById(service.id);
      oldIds = _extractIconIds(oldService);
      final oldImageUrl = oldService.image;
      final newImageUrl = service.image;

      if (oldImageUrl != null && oldImageUrl != newImageUrl) {
        deleteServiceImage(oldImageUrl).catchError((e) {
          print('⚠️ Error deleting old image on update: $e');
        });
      }
    } catch (e) {
      print('⚠️ Failed to check/delete old image on update: $e');
    }

    final response = await _supabase
        .from('services')
        .update(service.toJson())
        .eq('id', service.id)
        .select()
        .single();
    final updated = ServiceRemoteModel.fromJson(Map<String, dynamic>.from(response));

    // Update usage count for referenced icons
    try {
      final newIds = _extractIconIds(updated);
      await _updateIconUsages(oldIds: oldIds, newIds: newIds);
    } catch (e) {
      print('⚠️ Error updating icon usage counts on service update: $e');
    }

    return updated;
  }

  @override
  Future<List<ServiceRemoteModel>> getMainServices() async {
    final response = await _supabase
        .from('services')
        .select('*')
        .isFilter('parent_id', null)
        .order('sort_order', ascending: true);
    return (response as List).map((json) {
      return ServiceRemoteModel.fromJson(Map<String, dynamic>.from(json));
    }).toList();
  }

  @override
  Future<List<ServiceRemoteModel>> getSubServices({
    required String mainServiceId,
  }) async {
    final response = await _supabase
        .from('services')
        .select('*')
        .eq('parent_id', mainServiceId)
        .order('sort_order', ascending: true);
    return (response as List).map((json) {
      return ServiceRemoteModel.fromJson(Map<String, dynamic>.from(json));
    }).toList();
  }

  // ! جلب كل الخدمات
  @override
  Future<List<ServiceRemoteModel>> getServices() async {
    print(
      "#################  getServices في ملف ال remote dataSource #################",
    );
    final response = await _supabase
        .from('services')
        .select('*')
        .order('sort_order', ascending: true);
    print("========================= 🚀🚀🚀🚀response ${response.length}");
    print(
      "===========================================================================",
    );

    print("========================= 🚀🚀🚀🚀response $response");
    print(
      "===========================================================================",
    );

    return (response as List).map((json) {
      return ServiceRemoteModel.fromJson(Map<String, dynamic>.from(json));
    }).toList();
  }

  @override
  Future<List<ServiceRemoteModel>> getServicesUpdatedSince(
    DateTime timestamp,
  ) async {
    final response = await _supabase
        .from('services')
        .select('*')
        .gt('updated_at', timestamp.toUtc().toIso8601String())
        .order('sort_order', ascending: true);

    return (response as List).map((json) {
      return ServiceRemoteModel.fromJson(Map<String, dynamic>.from(json));
    }).toList();
  }

  @override
  Future<String> uploadServiceImage({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String? serviceId,
    bool isTemp = false,
  }) async {
    final String path;
    if (isTemp || serviceId == null) {
      path = 'service_assets/temp/service_icons/$fileName';
    } else {
      path = 'service_assets/service_icons/$serviceId/$fileName';
    }

    await _supabase.storage
        .from('service_images')
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    return _supabase.storage.from('service_images').getPublicUrl(path);
  }

  @override
  Future<List<SharedIconRemoteModel>> getSharedIcons() async {
    final response = await _supabase
        .from('shared_icons')
        .select('*')
        .order('category', ascending: true);
    return (response as List).map((json) {
      return SharedIconRemoteModel.fromJson(Map<String, dynamic>.from(json));
    }).toList();
  }

  @override
  Future<SharedIconRemoteModel> insertSharedIcon(SharedIconRemoteModel icon) async {
    final response = await _supabase
        .from('shared_icons')
        .insert(icon.toJson())
        .select()
        .single();
    return SharedIconRemoteModel.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<void> deleteSharedIcon(String id) async {
    final iconResponse = await _supabase
        .from('shared_icons')
        .select('usage_count, storage_path')
        .eq('id', id)
        .single();
    
    final usageCount = iconResponse['usage_count'] as int? ?? 0;
    final storagePath = iconResponse['storage_path'] as String?;

    if (usageCount > 0) {
      throw Exception('Cannot delete icon because it is currently in use.');
    }

    await _supabase
        .from('shared_icons')
        .delete()
        .eq('id', id);

    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        await _supabase.storage.from('service_images').remove([storagePath]);
      } catch (e) {
        print('⚠️ Error deleting shared icon from storage: $e');
      }
    }
  }

  Set<String> _extractIconIds(ServiceRemoteModel service) {
    final Set<String> ids = {};
    if (service.details != null) {
      for (final detail in service.details!) {
        if (detail.ar.iconId != null && detail.ar.iconId!.isNotEmpty) {
          ids.add(detail.ar.iconId!);
        }
        if (detail.en.iconId != null && detail.en.iconId!.isNotEmpty) {
          ids.add(detail.en.iconId!);
        }
      }
    }
    if (service.notIncluded != null) {
      if (service.notIncluded!.ar?.iconId != null &&
          service.notIncluded!.ar!.iconId!.isNotEmpty) {
        ids.add(service.notIncluded!.ar!.iconId!);
      }
      if (service.notIncluded!.en?.iconId != null &&
          service.notIncluded!.en!.iconId!.isNotEmpty) {
        ids.add(service.notIncluded!.en!.iconId!);
      }
    }
    return ids;
  }

  Future<void> _updateIconUsages({
    required Set<String> oldIds,
    required Set<String> newIds,
  }) async {
    final added = newIds.difference(oldIds);
    final removed = oldIds.difference(newIds);

    for (final id in added) {
      try {
        await _supabase.rpc('increment_shared_icon_usage', params: {'p_icon_id': id});
      } catch (e) {
        print('⚠️ Error incrementing icon usage for $id: $e');
      }
    }

    for (final id in removed) {
      try {
        await _supabase.rpc('decrement_shared_icon_usage', params: {'p_icon_id': id});
      } catch (e) {
        print('⚠️ Error decrementing icon usage for $id: $e');
      }
    }
  }

  @override
  Future<void> deleteServiceImage(String imageUrl) async {
    try {
      final Uri uri = Uri.parse(imageUrl);
      final String pathPrefix = '/storage/v1/object/public/service_images/';
      if (uri.path.contains(pathPrefix)) {
        final String path = uri.path.substring(
          uri.path.indexOf(pathPrefix) + pathPrefix.length,
        );
        final decodedPath = Uri.decodeComponent(path);
        await _supabase.storage.from('service_images').remove([decodedPath]);
      }
    } catch (e) {
      print('⚠️ Error deleting old image from Supabase Storage: $e');
    }
  }

  @override
  Future<List<String>> getActiveServiceIds() async {
    final response = await _supabase
        .from('services')
        .select('id')
        .inFilter('status', ['active', 'paused']);
    return (response as List).map((json) => json['id'] as String).toList();
  }

  @override
  Future<ServiceRemoteModel> getServiceById(String id) async {
    final response = await _supabase
        .from('services')
        .select('*')
        .eq('id', id)
        .single();

    return ServiceRemoteModel.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<List<ServiceAvailability>> getAvailability(String subServiceId) async {
    final response = await _supabase.rpc(
      'get_available_technicians',
      params: {
        'p_sub_service_id': subServiceId,
        'p_start_date': DateTime.now().toIso8601String(),
        'p_end_date': DateTime.now()
            .add(const Duration(days: 10))
            .toIso8601String(),
      },
    );

    if (response is List) {
      return _groupAvailability(response);
    }

    return [];
  }

  @override
  Future<List<Technician>> getTechnicians() async {
    final response = await _supabase
        .from('technician_profiles')
        .select('*, profiles(*)');

    return (response as List).map((json) => _mapToTechnician(json)).toList();
  }

  @override
  Future<List<Technician>> getTechniciansForService(String subServiceId) async {
    final response = await _supabase
        .from('technician_skills')
        .select('*, technician_profiles(*, profiles(*))')
        .eq('sub_service_id', subServiceId)
        .eq('is_active', true);

    return (response as List).map((json) {
      final techData = json['technician_profiles'];
      return _mapToTechnician(techData);
    }).toList();
  }

  @override
  Future<double> calculatePrice({
    required String subServiceId,
    required Map<String, dynamic> formValues,
    required List<String> selectedOptions,
  }) async {
    try {
      final response = await _supabase.rpc(
        'calculate_service_price',
        params: {
          'p_sub_service_id': subServiceId,
          'p_form_values': formValues,
          'p_selected_options': selectedOptions,
        },
      );

      return (response as num).toDouble();
    } catch (e) {
      print('Pricing Error: $e');
      throw Exception('Failed to calculate price on backend: $e');
    }
  }

  Technician _mapToTechnician(Map<String, dynamic> json) {
    final profile = json['profiles'] ?? {};
    return Technician(
      id: json['user_id'],
      firstName: profile['first_name'] ?? '',
      lastName: profile['last_name'] ?? '',
      email: profile['email'] ?? '',
      phone: profile['phone_number'],
      avatarUrl: profile['avatar_url'],
      rating: (json['rating'] ?? 5.0).toDouble(),
      completedJobs: json['completed_jobs'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      isAvailable: json['is_available'] ?? false,
      bio: json['bio'],
      mainServiceId:
          null, // Unified model does not have category-specific mainServiceId mapping on root
    );
  }

  List<ServiceAvailability> _groupAvailability(List<dynamic> raw) {
    return []; // Placeholder for now
  }
}
