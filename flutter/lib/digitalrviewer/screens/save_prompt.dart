// "Save this device?" card shown in the main window after a session to an unsaved device starts.
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

class DrSavePromptCard extends StatelessWidget {
  final String id;
  final String name;
  final String platform;
  final bool signedIn;
  final VoidCallback onSave;
  final VoidCallback onEdit; // save with a different name / a note
  final VoidCallback onNotNow;
  const DrSavePromptCard(
      {super.key,
      required this.id,
      required this.name,
      this.platform = '',
      this.signedIn = false,
      required this.onSave,
      required this.onEdit,
      required this.onNotNow});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    final detail = [drFormatId(id), if (platform.isNotEmpty) platform].join(' · ');
    return Container(
      width: 380,
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(DrRadius.tile),
        border: Border.all(color: c.accentBorder),
        boxShadow: DrShadow.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DrInitials(name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Save $name to your devices?',
                      style: DrText.sans(14, c.text, weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(detail,
                      style: DrText.sans(13, c.textMuted, tabular: true)),
                ],
              ),
            ),
            IconButton(
                tooltip: 'Close',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, size: 17, color: c.textMuted),
                onPressed: onNotNow),
          ]),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 46, right: 6),
            child: Text(
                signedIn
                    ? 'It will be listed on every computer where you sign in.'
                    : 'It will be listed on this computer.',
                style: DrText.sans(12.5, c.textSubtle, height: 1.4)),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Row(children: [
              DrButton('Save', height: 36, fontSize: 13, onPressed: onSave),
              const SizedBox(width: 8),
              DrButton('Edit & save',
                  kind: DrButtonKind.secondary,
                  height: 36,
                  fontSize: 13,
                  onPressed: onEdit),
              const Spacer(),
              DrLink('Not now', fontSize: 13, onTap: onNotNow),
              const SizedBox(width: 6),
            ]),
          ),
        ],
      ),
    );
  }
}
