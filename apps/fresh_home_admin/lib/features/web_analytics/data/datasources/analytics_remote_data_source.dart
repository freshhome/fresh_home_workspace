import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared/shared.dart';
import '../models/web_analytics_model.dart';

abstract class AnalyticsRemoteDataSource {
  Future<WebAnalyticsModel> getTodayAnalytics();
  void setBaseUrl(String url);
  String get baseUrl;
}

class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  final http.Client client;
  String _baseUrl;

  AnalyticsRemoteDataSourceImpl({
    required this.client,
    String? baseUrl,
  }) : _baseUrl = baseUrl ?? 'https://www.freshhomeeg.com';

  @override
  String get baseUrl => _baseUrl;

  @override
  void setBaseUrl(String url) {
    _baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  @override
  Future<WebAnalyticsModel> getTodayAnalytics() async {
    final sanitizedBase = _baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$sanitizedBase/api/analytics');

    debugPrint('\n🌐 ========================================================');
    debugPrint('🌐 [AnalyticsRemoteDataSource] SENDING REQUEST');
    debugPrint('🌐 Target URL: $uri');
    debugPrint('🌐 Timestamp : ${DateTime.now().toIso8601String()}');
    debugPrint('🌐 ========================================================');

    try {
      final response = await client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('\n📥 ========================================================');
      debugPrint('📥 [AnalyticsRemoteDataSource] RESPONSE RECEIVED');
      debugPrint('📥 Status Code : ${response.statusCode}');
      debugPrint('📥 Content-Type: ${response.headers['content-type']}');
      debugPrint('📥 Body Length : ${response.body.length} chars');
      debugPrint('📥 Raw Body    : ${response.body}');
      debugPrint('📥 ========================================================');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          debugPrint('✅ [AnalyticsRemoteDataSource] Successfully parsed analytics data.');
          return WebAnalyticsModel.fromJson(decoded);
        } else {
          final errorMsg = decoded['error'] as String? ?? 'فشل جلب بيانات التحليلات من الخادم';
          debugPrint('🚨 [AnalyticsRemoteDataSource] API logical failure: $errorMsg');
          throw ServerException(errorMsg);
        }
      } else {
        String errorMsg = 'فشل الاتصال بالخادم (${response.statusCode})';
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          if (decoded['error'] != null) {
            errorMsg = decoded['error'].toString();
          }
        } catch (_) {
          if (response.body.isNotEmpty) {
            errorMsg += ': ${response.body}';
          }
        }
        debugPrint('🚨 [AnalyticsRemoteDataSource] HTTP Error ${response.statusCode}: $errorMsg');
        throw ServerException(errorMsg);
      }
    } on AppException catch (e) {
      debugPrint('❌ [AnalyticsRemoteDataSource] Handled AppException: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('💥 [AnalyticsRemoteDataSource] Unexpected Exception: $e');
      debugPrint('💥 [AnalyticsRemoteDataSource] StackTrace:\n$stackTrace');
      throw NetworkException('تعذر الاتصال بالخادم: $e');
    }
  }
}
