import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// SAFE NAVIGATION & MESSAGING UTILITIES
/// ─────────────────────────────────────────────────────────────────────────────
/// Helpers to safely use Navigator and ScaffoldMessenger while checking mounted state.
/// Prevents '_dependents.isEmpty' and other lifecycle-related errors.
/// ═══════════════════════════════════════════════════════════════════════════════

/// ──────────────────────────────────────────────────────────────────────────────
/// SafeNavigator
/// ──────────────────────────────────────────────────────────────────────────────
/// Extension on State to safely perform navigation operations.
extension SafeNavigator on State {
  /// Safely push a new route only if the widget is mounted.
  Future<T?> safePush<T extends Object?>(
    BuildContext context,
    Route<T> route,
  ) async {
    if (!mounted) return null;
    return Navigator.of(context).push(route);
  }

  /// Safely push replacement route only if the widget is mounted.
  Future<T?> safePushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Route<T> newRoute, {
    TO? result,
  }) async {
    if (!mounted) return null;
    return Navigator.of(context).pushReplacement(newRoute, result: result);
  }

  /// Safely pop the current route only if the widget is mounted.
  void safePop<T extends Object?>(BuildContext context, [T? result]) {
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  /// Safely push and remove until a predicate is met.
  Future<T?> safePushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Route<T> newRoute,
    bool Function(Route<dynamic>) predicate,
  ) async {
    if (!mounted) return null;
    return Navigator.of(context).pushAndRemoveUntil(newRoute, predicate);
  }

  /// Safely check if navigator can pop.
  bool canSafePop(BuildContext context) {
    if (!mounted) return false;
    return Navigator.of(context).canPop();
  }
}

/// ──────────────────────────────────────────────────────────────────────────────
/// SafeMessenger
/// ──────────────────────────────────────────────────────────────────────────────
/// Extension on State to safely show snackbars and messages.
extension SafeMessenger on State {
  /// Safely show a snackbar only if the widget is mounted.
  void safeShowSnackBar(
    BuildContext context,
    SnackBar snackBar,
  ) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Safely show a snackbar with a message.
  void safeShowMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    TextStyle? textStyle,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: textStyle),
        duration: duration,
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Safely show a success message.
  void safeShowSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  /// Safely show an error message.
  void safeShowError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration,
      ),
    );
  }

  /// Safely clear all snackbars.
  void safeClearSnackBars(BuildContext context) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}

/// ──────────────────────────────────────────────────────────────────────────────
/// SafeDialogHelper
/// ──────────────────────────────────────────────────────────────────────────────
/// Helper for showing dialogs safely.
extension SafeDialogHelper on State {
  /// Safely show a dialog only if the widget is mounted.
  Future<T?> safeShowDialog<T>(
    BuildContext context,
    WidgetBuilder builder, {
    bool barrierDismissible = true,
    Color? barrierColor,
  }) async {
    if (!mounted) return null;
    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
    );
  }

  /// Safely pop a dialog only if the widget is mounted.
  void safePopDialog<T>(BuildContext context, [T? result]) {
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }
}

/// ──────────────────────────────────────────────────────────────────────────────
/// Usage Examples:
/// ──────────────────────────────────────────────────────────────────────────────
/// 
/// // Instead of:
/// Navigator.pop(context);
/// 
/// // Use:
/// safePop(context);
/// 
/// // Instead of:
/// ScaffoldMessenger.of(context).showSnackBar(SnackBar(...));
/// 
/// // Use:
/// safeShowMessage(context, 'Success!');
/// 
/// // Instead of:
/// Navigator.push(context, MaterialPageRoute(...));
/// 
/// // Use:
/// safePush(context, MaterialPageRoute(...));
