// Devices screen ("2 · Devices" mockup). Pure view.
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';
import 'home_view.dart';
import 'shell.dart';

enum DrDeviceFilter { all, online, offline }

class DrDevicesView extends StatefulWidget {
  final List<DrDeviceItem> devices;
  final ValueChanged<String> onConnect;
  final ValueChanged<String> onFiles;
  final VoidCallback onAddDevice;

  /// Optional per-row context menu (rename, favourite, remove …) supplied by the app.
  final Widget Function(DrDeviceItem item)? menuBuilder;

  /// Header of the 4th column; the app has no "last connected" time, so it shows the list.
  final String lastSeenHeader;

  /// Account state: when [onSignIn] is set and not signed in, a banner offers to sign in.
  final bool signedIn;
  final VoidCallback? onSignIn;

  /// Search text is an ID that isn't in the list: offer to check and save it.
  final ValueChanged<String>? onAddId;

  const DrDevicesView(
      {super.key,
      required this.devices,
      required this.onConnect,
      required this.onFiles,
      required this.onAddDevice,
      this.menuBuilder,
      this.lastSeenHeader = 'Last connected',
      this.signedIn = true,
      this.onSignIn,
      this.onAddId});

  @override
  State<DrDevicesView> createState() => _DrDevicesViewState();
}

class _DrDevicesViewState extends State<DrDevicesView> {
  DrDeviceFilter _filter = DrDeviceFilter.all;
  String _query = '';

  // Column flex from the mockup grid (2.2fr 1.3fr 1fr 1.2fr 1fr); the actions column is a
  // fixed width so its buttons never get squeezed.
  static const _flex = [22, 13, 10, 12, 10];
  static const _actionsWidth = 250.0;
  bool _narrow = false; // hide System and Last connected below ~860 px of table width

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    final all = widget.devices;
    final online = all.where((d) => d.online).length;
    final q = _query.trim().toLowerCase().replaceAll(' ', '');
    final rows = all.where((d) {
      if (_filter == DrDeviceFilter.online && !d.online) return false;
      if (_filter == DrDeviceFilter.offline && d.online) return false;
      if (q.isEmpty) return true;
      return d.name.toLowerCase().replaceAll(' ', '').contains(q) ||
          d.id.replaceAll(' ', '').contains(q) ||
          d.note.toLowerCase().replaceAll(' ', '').contains(q);
    }).toList();
    // A full ID that isn't listed yet: offer to check and save it.
    final unknownId = widget.onAddId != null &&
            RegExp(r'^\d{6,}$').hasMatch(q) &&
            !all.any((d) => d.id == q)
        ? q
        : null;

    return DrPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: DrPageHeading('Your devices',
                    subtitle: 'Machines you have connected to or saved.'),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 280,
                child: DrPillField(
                  hint: 'Search by name or ID',
                  height: 44,
                  fontSize: 14,
                  sunk: false,
                  semanticLabel: 'Search devices',
                  leading: Icon(Icons.search, size: 17, color: c.textMuted),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 10),
              DrButton('Add device',
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  icon: const Icon(Icons.add),
                  onPressed: widget.onAddDevice),
            ],
          ),
          if (!widget.signedIn && widget.onSignIn != null) ...[
            const SizedBox(height: 18),
            _signInBanner(c),
          ],
          const SizedBox(height: 22),
          Wrap(spacing: 8, children: [
            DrChip('All · ${all.length}',
                selected: _filter == DrDeviceFilter.all,
                onTap: () => setState(() => _filter = DrDeviceFilter.all)),
            DrChip('Online · $online',
                selected: _filter == DrDeviceFilter.online,
                onTap: () => setState(() => _filter = DrDeviceFilter.online)),
            DrChip('Offline · ${all.length - online}',
                selected: _filter == DrDeviceFilter.offline,
                onTap: () => setState(() => _filter = DrDeviceFilter.offline)),
          ]),
          const SizedBox(height: 22),
          LayoutBuilder(builder: (context, box) {
            _narrow = box.maxWidth < 860;
            return DrCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _header(c),
              if (unknownId != null) _unknownIdRow(c, unknownId, last: rows.isEmpty),
              if (rows.isEmpty && unknownId == null)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                      all.isEmpty
                          ? 'No devices yet. Add one with its ID, or connect from Home and save it.'
                          : 'No devices match.',
                      style: DrText.sans(14, c.textSubtle)),
                ),
              for (var i = 0; i < rows.length; i++)
                _row(c, rows[i], last: i == rows.length - 1),
            ]),
          );
          }),
        ],
      ),
    );
  }

  Widget _listTag(DrColors c, DrDeviceItem d) {
    if (d.lastSeen.isEmpty) return Text('—', style: DrText.sans(14, c.textMuted));
    final strong = d.saved;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: strong ? c.accent : Colors.transparent,
        border: Border.all(color: strong ? c.accentBorder : c.border),
        borderRadius: BorderRadius.circular(DrRadius.pill),
      ),
      child: Text(d.lastSeen,
          style: DrText.sans(12, strong ? c.accentText : c.textMuted,
              weight: FontWeight.w600)),
    );
  }

  Widget _signInBanner(DrColors c) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(DrRadius.tile),
          border: Border.all(color: c.accentBorder),
        ),
        child: Row(children: [
          Icon(Icons.cloud_outlined, size: 20, color: c.accentText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                'Sign in to keep your devices in your account and see them on any computer.',
                style: DrText.sans(13.5, c.accentText, height: 1.4)),
          ),
          const SizedBox(width: 12),
          DrButton('Sign in',
              height: 38, fontSize: 13, onPressed: widget.onSignIn),
        ]),
      );

  Widget _unknownIdRow(DrColors c, String id, {required bool last}) => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
            color: c.surfaceSunk,
            border: last ? null : Border(bottom: BorderSide(color: c.divider))),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: c.accent, shape: BoxShape.circle),
            child: Icon(Icons.search, size: 17, color: c.accentText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: drFormatId(id),
                    style: DrText.sans(14, c.text,
                        weight: FontWeight.w600, tabular: true)),
                TextSpan(
                    text: '  isn’t in your list yet',
                    style: DrText.sans(14, c.textMuted)),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DrButton('Check & add',
              kind: DrButtonKind.secondary,
              height: 36,
              fontSize: 13,
              onPressed: () => widget.onAddId!(id)),
          const SizedBox(width: 8),
          DrButton('Connect',
              height: 36,
              fontSize: 13,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: () => widget.onConnect(id)),
        ]),
      );

  /// cells: name, id, system, last connected, status, actions.
  Widget _cells(List<Widget> cells) {
    final shown = [0, 1, if (!_narrow) 2, if (!_narrow) 3, 4];
    return Row(children: [
      for (final i in shown) Expanded(flex: _flex[i], child: cells[i]),
      SizedBox(width: _actionsWidth, child: cells[5]),
    ]);
  }

  Widget _header(DrColors c) {
    final s = DrText.sans(12, c.textSubtle, weight: FontWeight.w600);
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: c.divider))),
      child: _cells([
        Text('Name', style: s),
        Text('ID', style: s),
        Text('System', style: s),
        Text(widget.lastSeenHeader, style: s),
        Text('Status', style: s),
        const SizedBox(),
      ]),
    );
  }

  Widget _row(DrColors c, DrDeviceItem d, {required bool last}) {
    final muted = DrText.sans(14, c.textMuted, tabular: true);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: c.divider))),
      child: _cells([
        Row(children: [
          DrInitials(d.name),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DrText.sans(14, c.text, weight: FontWeight.w600)),
                if (d.note.isNotEmpty)
                  Text(d.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DrText.sans(12, c.textSubtle)),
              ],
            ),
          ),
        ]),
        Text(drFormatId(d.id), style: muted),
        Text(d.platform.isEmpty ? '—' : d.platform, style: muted),
        Align(alignment: Alignment.centerLeft, child: _listTag(c, d)),
        DrStatusDot(online: d.online, fontSize: 13),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          DrButton('Files',
              kind: DrButtonKind.secondary,
              height: 36,
              fontSize: 13,
              onPressed: () => widget.onFiles(d.id)),
          const SizedBox(width: 8),
          DrButton('Connect',
              height: 36,
              fontSize: 13,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: d.online ? () => widget.onConnect(d.id) : null),
          if (widget.menuBuilder != null) ...[
            const SizedBox(width: 4),
            widget.menuBuilder!(d),
          ],
        ]),
      ]),
    );
  }
}
