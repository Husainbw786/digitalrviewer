// File transfers screen ("3 · File transfers" mockup), adapted to how the app works:
// files move inside a file-transfer session, so this page picks a device and opens one.
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';
import 'home_view.dart';
import 'shell.dart';

class DrTransfersView extends StatefulWidget {
  final List<DrDeviceItem> devices;
  final ValueChanged<String> onOpen;
  const DrTransfersView(
      {super.key, required this.devices, required this.onOpen});

  @override
  State<DrTransfersView> createState() => _DrTransfersViewState();
}

class _DrTransfersViewState extends State<DrTransfersView> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    final online = widget.devices.where((d) => d.online).toList();
    final selected = widget.devices
            .where((d) => d.id == _selected)
            .firstOrNull ??
        (online.isNotEmpty ? online.first : widget.devices.firstOrNull);

    return DrPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DrPageHeading('File transfers',
              subtitle: 'Send files to any of your devices, or get files from them.'),
          const SizedBox(height: 22),
          SizedBox(
            height: 420,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 92,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(DrRadius.hero)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Send files',
                            style: DrText.sans(13, c.accentTextMuted,
                                weight: FontWeight.w600)),
                        const SizedBox(height: 14),
                        Text('To', style: DrText.sans(13, c.accentTextMuted)),
                        const SizedBox(height: 6),
                        _devicePicker(c, selected),
                        const SizedBox(height: 14),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: c.surface.withOpacity(0.55),
                              borderRadius:
                                  BorderRadius.circular(DrRadius.tile),
                              border: Border.all(color: c.accentBorder),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                      color: c.surface, shape: BoxShape.circle),
                                  child: Icon(Icons.upload_rounded,
                                      color: c.text, size: 20),
                                ),
                                const SizedBox(height: 14),
                                Text('Open a file transfer',
                                    style: DrText.serif(22, c.text)),
                                const SizedBox(height: 6),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                      'Browse both computers side by side and drag files across.',
                                      textAlign: TextAlign.center,
                                      style: DrText.sans(13, c.accentTextMuted)),
                                ),
                                const SizedBox(height: 16),
                                DrButton('Choose files',
                                    height: 40,
                                    onPressed: selected == null
                                        ? null
                                        : () => widget.onOpen(selected.id)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 108,
                  child: DrCard(
                    radius: DrRadius.hero,
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Your devices',
                            style: DrText.sans(15, c.text,
                                weight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: widget.devices.isEmpty
                              ? Center(
                                  child: Text(
                                      'Connect to a device from Home first.',
                                      style: DrText.sans(13, c.textSubtle)))
                              : ListView.separated(
                                  itemCount: widget.devices.length,
                                  separatorBuilder: (_, __) =>
                                      Divider(color: c.divider),
                                  itemBuilder: (_, i) {
                                    final d = widget.devices[i];
                                    return SizedBox(
                                      height: 56,
                                      child: Row(children: [
                                        DrInitials(d.name, size: 34),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(d.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: DrText.sans(
                                                      14, c.text,
                                                      weight: FontWeight.w600)),
                                              Text(drFormatId(d.id),
                                                  style: DrText.sans(
                                                      12, c.textSubtle,
                                                      tabular: true)),
                                            ],
                                          ),
                                        ),
                                        DrStatusDot(online: d.online),
                                        const SizedBox(width: 14),
                                        DrButton('Files',
                                            kind: DrButtonKind.secondary,
                                            height: 34,
                                            fontSize: 13,
                                            onPressed: d.online
                                                ? () => widget.onOpen(d.id)
                                                : null),
                                      ]),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _devicePicker(DrColors c, DrDeviceItem? selected) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: c.surface, borderRadius: BorderRadius.circular(DrRadius.pill)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected?.id,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          hint: Text('No devices yet', style: DrText.sans(14, c.textSubtle)),
          icon: Icon(Icons.keyboard_arrow_down, color: c.textMuted),
          items: [
            for (final d in widget.devices)
              DropdownMenuItem(
                value: d.id,
                child: Row(children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: d.online ? c.online : c.offline,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(d.name,
                        overflow: TextOverflow.ellipsis,
                        style:
                            DrText.sans(14, c.text, weight: FontWeight.w600)),
                  ),
                ]),
              ),
          ],
          onChanged: (v) => setState(() => _selected = v),
        ),
      ),
    );
  }
}
