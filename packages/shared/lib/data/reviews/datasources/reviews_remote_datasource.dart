import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';

abstract class ReviewsRemoteDataSource {
  Future<String> submitReview({
    required String bookingId,
    required int ratingValue,
    String? feedbackText,
  });

  Future<bool> isBookingReviewed({
    required String bookingId,
  });

  Future<List<ReviewModel>> fetchServiceReviews({
    required String serviceId,
    int? limit,
    int? offset,
  });

  Future<List<ReviewModel>> fetchTechnicianReviews({
    required String technicianId,
    int? limit,
    int? offset,
  });

  Future<List<ReviewModel>> fetchAllReviews({
    String? status,
    int? limit,
    int? offset,
  });

  Future<void> approveReview({
    required String reviewId,
  });
}

class ReviewsRemoteDataSourceImpl implements ReviewsRemoteDataSource {
  final SupabaseClient _supabase;

  ReviewsRemoteDataSourceImpl({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<String> submitReview({
    required String bookingId,
    required int ratingValue,
    String? feedbackText,
  }) async {
    final response = await _supabase.rpc('submit_review', params: {
      'p_booking_id': bookingId,
      'p_rating_value': ratingValue,
      'p_feedback_text': feedbackText,
    });
    return response as String;
  }

  @override
  Future<bool> isBookingReviewed({required String bookingId}) async {
    final response = await _supabase
        .from('reviews')
        .select('id')
        .eq('booking_id', bookingId)
        .maybeSingle();
    return response != null;
  }

  @override
  Future<List<ReviewModel>> fetchServiceReviews({
    required String serviceId,
    int? limit,
    int? offset,
  }) async {
    var query = _supabase
        .from('view_reviews_with_details')
        .select()
        .eq('service_id', serviceId)
        .eq('status', 'published')
        .order('created_at', ascending: false);

    if (limit != null && offset != null) {
      query = query.range(offset, offset + limit - 1);
    }

    final response = await query;
    final list = List<Map<String, dynamic>>.from(response as List);
    return list.map((json) => ReviewModel.fromJson(json)).toList();
  }

  @override
  Future<List<ReviewModel>> fetchTechnicianReviews({
    required String technicianId,
    int? limit,
    int? offset,
  }) async {
    var query = _supabase
        .from('view_reviews_with_details')
        .select()
        .eq('technician_id', technicianId)
        .eq('status', 'published')
        .order('created_at', ascending: false);

    if (limit != null && offset != null) {
      query = query.range(offset, offset + limit - 1);
    }

    final response = await query;
    final list = List<Map<String, dynamic>>.from(response as List);
    return list.map((json) => ReviewModel.fromJson(json)).toList();
  }

  @override
  Future<List<ReviewModel>> fetchAllReviews({
    String? status,
    int? limit,
    int? offset,
  }) async {
    var query = _supabase.from('view_reviews_with_details').select();
    if (status != null) {
      query = query.eq('status', status);
    }
    
    var orderedQuery = query.order('created_at', ascending: false);
    if (limit != null && offset != null) {
      orderedQuery = orderedQuery.range(offset, offset + limit - 1);
    }
    final response = await orderedQuery;
    final list = List<Map<String, dynamic>>.from(response as List);
    return list.map((json) => ReviewModel.fromJson(json)).toList();
  }

  @override
  Future<void> approveReview({required String reviewId}) async {
    await _supabase.rpc('approve_review', params: {
      'p_review_id': reviewId,
    });
  }
}



