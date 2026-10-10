// Incoming connection request card ("5 · Incoming request" mockup). Pure view.
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

class DrPermission {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged; // null = not changeable
  const DrPermission(this.label, this.value, this.onChanged);
}

class DrIncomingRequestCard extends StatelessWidget {
  final String name;
  final String peerId;
  final List<DrPermission> permissions;

  /// When false the request is already accepted: show "Disconnect" only.
  final bool pending;
  final VoidCallback onAllow;
  final VoidCallback onDecline;
  final String? note;

  /// Overrides "<name> wants to connect".
  final String? headline;

  /// Hide "Allow" when this device only accepts password logins.
  final bool showAllow;

  /// Fit the small connection-manager window (300 px wide) instead of a 480 px dialog.
  final bool compact;

  const DrIncomingRequestCard(
      {super.key,
      required this.name,
      required this.peerId,
      required this.permissions,
      required this.onAllow,
      required this.onDecline,
      this.pending = true,
      this.note,
      this.showAllow = true,
      this.headline,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    final gap = compact ? 16.0 : 22.0;
    return Container(
      width: compact ? null : 480,
      padding: EdgeInsets.all(compact ? 18 : 30),
      decoration: compact
          ? null
          : BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(DrRadius.dialog),
              boxShadow: DrShadow.dialog,
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            DrInitials(name, size: compact ? 44 : 52),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pending ? 'Incoming request' : 'Connected',
                  style: DrText.sans(13, c.accentTextMuted,
                      weight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('ID ${drFormatId(peerId)}',
                  style: DrText.sans(13, c.textSubtle, tabular: true)),
            ]),
          ]),
          SizedBox(height: gap),
          Text(headline ?? (pending ? '$name wants to connect' : '$name is connected'),
              style: DrText.serif(compact ? 24 : 30, c.text)),
          SizedBox(height: gap),
          if (permissions.isNotEmpty) ...[
            DrPermissionList(permissions: permissions),
            SizedBox(height: gap),
          ],
          Row(children: [
            Expanded(
                child: DrButton(pending ? 'Decline' : 'Disconnect',
                    kind: DrButtonKind.secondary,
                    height: 50,
                    fontSize: 15,
                    expand: true,
                    onPressed: onDecline)),
            if (pending && showAllow) ...[
              const SizedBox(width: 10),
              Expanded(
                  child: DrButton('Allow',
                      height: 50,
                      fontSize: 15,
                      expand: true,
                      onPressed: onAllow)),
            ],
          ]),
          const SizedBox(height: 14),
          Text(note ?? 'You can end the session at any time.',
              textAlign: TextAlign.center,
              style: DrText.sans(13, c.textSubtle)),
        ],
      ),
    );
  }
}

/// The sunk rounded list of permission toggles (also used inside the CM window).
class DrPermissionList extends StatelessWidget {
  final List<DrPermission> permissions;
  const DrPermissionList({super.key, required this.permissions});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceSunk,
        borderRadius: BorderRadius.circular(DrRadius.tile),
        border: Border.all(color: c.divider),
      ),
      child: Column(children: [
        for (var i = 0; i < permissions.length; i++)
          Container(
            height: 50,
            decoration: BoxDecoration(
                border: i == permissions.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: c.divider))),
            child: Row(children: [
              Expanded(
                  child: Text(permissions[i].label,
                      style: DrText.sans(14, c.text, weight: FontWeight.w500))),
              DrToggle(
                  small: true,
                  value: permissions[i].value,
                  semanticLabel: permissions[i].label,
                  onChanged: permissions[i].onChanged),
            ]),
          ),
      ]),
    );
  }
}
