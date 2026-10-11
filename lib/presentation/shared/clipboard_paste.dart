import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketcrm/presentation/shared/snackbar_helper.dart';

/// Extracts a numeric verification code from a clipboard payload.
///
/// Strategy (kept intentionally simple and testable):
/// 1. keep only the digits contained in [text];
/// 2. return all of them when there are at most [length] digits;
/// 3. otherwise return the **last** [length] digits, because one-time codes
///    are usually placed at the end of the message
///    (e.g. `"Your code is 123456"`, `"Il codice è 123456. Non condividerlo."`).
///
/// Returns `null` when the payload contains no digits at all.
String? extractOtpCode(String? text, {int length = 6}) {
  final digits = (text ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  if (digits.length <= length) return digits;
  return digits.substring(digits.length - length);
}

/// Builds the text selection toolbar entries for an editable field, replacing
/// the platform "paste" action with [onPaste].
///
/// The default platform buttons (cut/copy/select all/…) are preserved, so users
/// keep the standard editing actions; only the paste entry is swapped, allowing
/// the caller to sanitize the clipboard payload (e.g. digits only for OTP).
///
/// The toolbar is dismissed before [onPaste] runs, mirroring the framework's
/// `pasteText` behaviour.
List<ContextMenuButtonItem> pasteContextMenuButtonItems(
  EditableTextState editableTextState, {
  required String pasteLabel,
  required VoidCallback onPaste,
}) {
  ContextMenuButtonItem pasteItem() => ContextMenuButtonItem(
    type: ContextMenuButtonType.paste,
    label: pasteLabel,
    onPressed: () {
      editableTextState.hideToolbar();
      onPaste();
    },
  );

  final items = <ContextMenuButtonItem>[];
  var replaced = false;
  for (final item in editableTextState.contextMenuButtonItems) {
    if (item.type == ContextMenuButtonType.paste) {
      items.add(pasteItem());
      replaced = true;
    } else {
      items.add(item);
    }
  }
  if (!replaced) {
    items.insert(0, pasteItem());
  }
  return items;
}

/// Pastes the system clipboard content into [controller].
///
/// When [otpMode] is `true` the payload is sanitized with [extractOtpCode], so
/// the field only receives digits (at most [otpLength]). Otherwise the payload
/// is trimmed and inserted as-is.
///
/// Shows a confirmation (or an information message when the clipboard has no
/// usable content) and returns `true` only when something was actually pasted.
///
/// The caller must have requested user interaction before calling this helper:
/// reading the clipboard programmatically can show a system prompt on iOS 16+.
Future<bool> pasteFromClipboard(
  BuildContext context,
  TextEditingController controller, {
  required String successMessage,
  required String emptyMessage,
  bool otpMode = false,
  int otpLength = 6,
}) async {
  String rawText;
  try {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    rawText = data?.text?.trim() ?? '';
  } catch (_) {
    // Clipboard unavailable (missing plugin, platform error): treated as empty.
    rawText = '';
  }

  // The widget may be gone while the clipboard request was in flight.
  if (!context.mounted) return false;

  final value = otpMode ? extractOtpCode(rawText, length: otpLength) : rawText;
  if (value == null || value.isEmpty) {
    SnackbarHelper.showInfo(context, emptyMessage);
    return false;
  }

  HapticFeedback.mediumImpact();
  controller.value = TextEditingValue(
    text: value,
    selection: TextSelection.collapsed(offset: value.length),
  );
  SnackbarHelper.showSuccess(context, successMessage);
  return true;
}
