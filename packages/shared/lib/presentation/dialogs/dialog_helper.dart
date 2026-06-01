import 'package:awesome_dialog/awesome_dialog.dart';
export 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';

/// ✅ كلاس موحد لإدارة الحوارات في المشروع
class DialogHelper {
  /// 🟢 حوار تأكيد / تنبيه عام
  static void show(
    BuildContext context, {
    required DialogType dialogType,
    String? title,
    String? desc,
    String? okText,
    String? cancelText,
    VoidCallback? onOkPress,
    VoidCallback? onCancelPress,
    bool barrierDismissible = true,
    Function(DismissType type)? onDismiss,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final customHeader = _buildCustomHeaderForWeb(dialogType);
    final resolvedDialogType = kIsWeb ? DialogType.noHeader : dialogType;

    AwesomeDialog(
      context: context,
      dialogType: resolvedDialogType,
      customHeader: customHeader,
      animType: AnimType.rightSlide,
      title: title,
      desc: desc,
      btnOkOnPress: onOkPress ?? () {},
      btnOkText: okText ?? l10n.general_confirm,
      btnCancelOnPress: onCancelPress,
      btnCancelText: cancelText ?? l10n.general_cancel,
      dismissOnTouchOutside: barrierDismissible,
      onDismissCallback: onDismiss,
    ).show();
  }

  static Widget? _buildCustomHeaderForWeb(DialogType dialogType) {
    if (!kIsWeb) return null;

    Color color;
    IconData iconData;

    switch (dialogType) {
      case DialogType.success:
        color = Colors.green;
        iconData = Icons.check_circle_rounded;
        break;
      case DialogType.error:
        color = Colors.red;
        iconData = Icons.error_rounded;
        break;
      case DialogType.warning:
        color = Colors.orange;
        iconData = Icons.warning_rounded;
        break;
      case DialogType.info:
        color = Colors.blue;
        iconData = Icons.info_rounded;
        break;
      case DialogType.question:
        color = Colors.teal;
        iconData = Icons.help_rounded;
        break;
      default:
        return null;
    }

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            size: 40,
            color: color,
          ),
        ),
      ),
    );
  }

  /// 🟡 حوار خطأ ثابت
  static void showError(
    BuildContext context, {
    String? message,
    VoidCallback? onOkPress,
    Function(DismissType type)? onDismiss,
  }) {
    final l10n = AppLocalizations.of(context)!;
    // استخدم دالة show العامة مع نوع الحوار المناسب
    show(
      context,
      dialogType: DialogType.error,
      title: l10n.general_error,
      desc: message ?? l10n.general_something_wrong,
      onOkPress: onOkPress ?? () {},
      onDismiss: onDismiss,
    );
  }

  /// 🔵 حوار نجاح ثابت
  static void showSuccess(
    BuildContext context, {
    String? message,
    VoidCallback? onOkPress,
    Function(DismissType type)? onDismiss,
  }) {
    final l10n = AppLocalizations.of(context)!;
    // استخدم دالة show العامة مع نوع الحوار المناسب
    show(
      context,
      dialogType: DialogType.success,
      title: l10n.general_success,
      desc: message ?? l10n.general_operation_success,
      onOkPress: onOkPress ?? () {},
      onDismiss: onDismiss,
    );
  }

  /// 🟠 حوار تأكيد العملية
  static void showConfirmation(
    BuildContext context, {
    String? title,
    String? desc,
    String? okText,
    String? cancelText,
    required VoidCallback onConfirm,
  }) {
    final l10n = AppLocalizations.of(context)!;
    // استخدم دالة show العامة مع نوع الحوار المناسب
    show(
      context,
      dialogType: DialogType.warning,
      title: title ?? l10n.general_confirm,
      desc: desc ?? l10n.general_confirm,
      okText: okText,
      cancelText: cancelText,
      onOkPress: onConfirm,
      onCancelPress: () {},
    );
  }

  /// ⏳ حوار جاري التحميل
  static void showLoading(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  l10n.general_loading,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ❌ إغلاق حوار التحميل
  static void dismissLoading(BuildContext context) {
    try {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    } catch (e) {
      debugPrint('⚠️ [DialogHelper] dismissLoading failed: $e');
    }
  }
}
