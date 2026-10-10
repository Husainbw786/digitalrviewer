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

  const DrDevicesView(
      {super.key,
      required this.devices,
      required this.onConnect,
      required this.onFiles,
      required this.onAddDevice,
      this.menuBuilder,
      this.lastSeenHeader = 'Last connected'});

  @override
  State<DrDevicesView> createState() => _DrDevicesViewState();
}

class _DrDevicesViewState extends State<DrDevicesView> {
  DrDeviceFilter _filter = DrDeviceFilter.all;
  String _query = '';

  // Column flex from the mockup grid: 2.2fr 1.3fr 1fr 1.2fr 1fr 1.7fr.
  static const _flex = [22, 13, 10, 12, 10, 17];

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
          d.id.replaceAll(' ', '').contains(q);
    }).toList();

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
          DrCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _header(c),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                      all.isEmpty
                          ? 'No devices yet. Connect to one from Home and it will be listed here.'
                          : 'No devices match.',
                      style: DrText.sans(14, c.textSubtle)),
                ),
              for (var i = 0; i < rows.length; i++)
                _row(c, rows[i], last: i == rows.length - 1),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _cells(List<Widget> cells) => Row(children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(flex: _flex[i], child: cells[i]),
      ]);

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
              child: Text(d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DrText.sans(14, c.text, weight: FontWeight.w600))),
        ]),
        Text(drFormatId(d.id), style: muted),
        Text(d.platform.isEmpty ? '—' : d.platform, style: muted),
        Text(d.lastSeen.isEmpty ? '—' : d.lastSeen, style: muted),
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
