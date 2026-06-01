import 'package:flutter/widgets.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';

typedef LocGetter = String Function(AppLocalizations loc);

final Map<String, LocGetter> localizationMap = {
  "invalid_email": (loc) => loc.invalid_email,
  "user_disabled": (loc) => loc.user_disabled,
  "wrong_password": (loc) => loc.wrong_password,
  "user_not_found": (loc) => loc.user_not_found,
  "unknown_error": (loc) => loc.unknown_error,
  "email_already_in_use": (loc) => loc.email_already_in_use,
    'verification_email_sent': (loc) => loc.verification_email_sent,
    'resend_verification': (loc) => loc.resend_verification,
    'please_verify_email_desc': (loc) => loc.please_verify_email_desc,
    'email_not_verified': (loc) => loc.email_not_verified,
  "operation_not_allowed": (loc) => loc.operation_not_allowed,
  "weak_password": (loc) => loc.weak_password,
  "network_request_failed": (loc) => loc.network_request_failed,
  "too_many_requests": (loc) => loc.too_many_requests,
  "internal_error": (loc) => loc.internal_error,
  "invalid_credential": (loc) => loc.invalid_credential,
  "invalid_verification_code": (loc) => loc.invalid_verification_code,
  "invalid_verification_id": (loc) => loc.invalid_verification_id,
  "captcha_check_failed": (loc) => loc.captcha_check_failed,
  "session_expired": (loc) => loc.session_expired,
  "quota_exceeded": (loc) => loc.quota_exceeded,
  "missing_email": (loc) => loc.missing_email,
};
// network-request-failed
// permission-denied
// unavailable
extension TranslateString on String {
  String tr(BuildContext context) {
    final loc = AppLocalizations.of(context)!;


    final normalizedKey = replaceAll('-', '_');

    if (localizationMap.containsKey(normalizedKey)) {
      return localizationMap[normalizedKey]!(loc);
    }

    // Fallback: If it contains spaces, return as is (it might be a raw message)
    if (contains(' ')) {
      return this;
    }

    return loc.unknown_error;
  }
}
