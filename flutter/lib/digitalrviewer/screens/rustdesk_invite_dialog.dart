// "For RustDesk users": the code a person with the normal RustDesk app pastes into its ID box
// to reach this device through our server. Pure view.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets.dart';

/// The text a RustDesk user types: "<our id>@<our ID server>?key=<server key>".
String drRustDeskInviteCode(String myId, String idServer, String key) {
  final id = myId.replaceAll(' ', '');
  final k = key.trim();
  return k.isEmpty ? '$id@$idServer' : '$id@$idServer?key=$k';
}

Future<void> drShowRustDeskInviteDialog(BuildContext context,
        {required String code, String? password, VoidCallback? onCopied}) =>
    showDialog(
        context: context,
        builder: (_) => DrRustDeskInviteDialog(
            code: code, password: password, onCopied: onCopied));

class DrRustDeskInviteDialog extends StatelessWidget {
  final String code;
  final String? password;
  final VoidCallback? onCopied;
  const DrRustDeskInviteDialog(
      {super.key, required this.code, this.password, this.onCopied});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    Widget step(int n, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: c.accent, shape: BoxShape.circle),
              child: Text('$n',
                  style: DrText.sans(12, c.accentText, weight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text,
                    style: DrText.sans(14, c.textMuted, height: 1.45))),
          ]),
        );
    return Dialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DrRadius.dialog)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 30, 32, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('For RustDesk users', style: DrText.serif(28, c.text)),
              const SizedBox(height: 6),
              Text(
                  'Someone using the normal RustDesk app can connect to this device with this code.',
                  style: DrText.sans(14, c.textMuted, height: 1.4)),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
                decoration: BoxDecoration(
                  color: c.surfaceSunk,
                  border: Border.all(color: c.borderStrong),
                  borderRadius: BorderRadius.circular(DrRadius.tile),
                ),
                child: Row(children: [
                  Expanded(
                    child: SelectableText(code,
                        style: DrText.sans(13.5, c.text,
                            weight: FontWeight.w600, height: 1.4)),
                  ),
                  const SizedBox(width: 10),
                  DrButton('Copy',
                      height: 38,
                      fontSize: 13,
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        onCopied?.call();
                      }),
                ]),
              ),
              const SizedBox(height: 22),
              step(1, 'Send them this code. They paste it into the ID box in their RustDesk app.'),
              step(2, 'They click Connect.'),
              step(
                  3,
                  password == null
                      ? 'They enter your password, or you accept the request on this computer.'
                      : 'They enter your password ($password), or you accept the request on this computer.'),
              const SizedBox(height: 6),
              Text(
                  'After the first time, RustDesk remembers it in their recent list.',
                  style: DrText.sans(12.5, c.textSubtle, height: 1.4)),
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.centerRight,
                child: DrButton('Done',
                    kind: DrButtonKind.secondary,
                    height: 44,
                    onPressed: () => Navigator.of(context).pop()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
