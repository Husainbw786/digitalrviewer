// Which network an ID belongs to: ours (Digital R Viewer) or RustDesk's public network.
// RustDesk-network IDs are stored and dialled as "<id>@public", which the engine routes through
// RustDesk's public server. Pure view + helpers.
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

enum DrNetwork { ours, rustdesk }

const String kDrPublicSuffix = '@public';

bool drIsRustDeskId(String id) => id.endsWith(kDrPublicSuffix);

/// The ID without any "@server" part.
String drBareId(String id) => id.split('@').first;

String drIdOnNetwork(String id, DrNetwork network) {
  final bare = drBareId(id.replaceAll(RegExp(r'\s'), ''));
  return network == DrNetwork.rustdesk ? '$bare$kDrPublicSuffix' : bare;
}

DrNetwork drNetworkOf(String id) =>
    drIsRustDeskId(id) ? DrNetwork.rustdesk : DrNetwork.ours;

/// ID as shown to people: grouped digits, without the "@public" suffix (see [DrNetworkChip]).
String drDisplayId(String id) => drFormatId(drBareId(id));

class DrNetworkSwitch extends StatelessWidget {
  final DrNetwork value;
  final ValueChanged<DrNetwork> onChanged;
  const DrNetworkSwitch(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Network',
        child: DrSegmentedNav(
          labels: const ['Digital R Viewer', 'RustDesk app'],
          selected: value == DrNetwork.ours ? 0 : 1,
          onSelect: (i) =>
              onChanged(i == 0 ? DrNetwork.ours : DrNetwork.rustdesk),
        ),
      );
}

/// Small "RustDesk" tag next to IDs that live on RustDesk's network.
class DrNetworkChip extends StatelessWidget {
  const DrNetworkChip({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Tooltip(
      message: 'Uses the RustDesk app (connects through RustDesk’s public servers)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: c.borderStrong),
          borderRadius: BorderRadius.circular(DrRadius.pill),
        ),
        child: Text('RustDesk',
            style: DrText.sans(11, c.textMuted, weight: FontWeight.w600)),
      ),
    );
  }
}

/// An ID with its network tag, for tables and tiles.
class DrIdLabel extends StatelessWidget {
  final String id;
  final TextStyle style;

  /// Put the tag under the ID (narrow table columns).
  final bool stacked;
  const DrIdLabel(this.id,
      {super.key, required this.style, this.stacked = false});

  @override
  Widget build(BuildContext context) => stacked && drIsRustDeskId(id)
      ? Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(drDisplayId(id),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
            const SizedBox(height: 3),
            const DrNetworkChip(),
          ],
        )
      : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(drDisplayId(id),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
          ),
          if (drIsRustDeskId(id)) ...[
            const SizedBox(width: 6),
            const DrNetworkChip(),
          ],
        ],
      );
}
