// Home screen ("1 · Home" mockup). Pure view: all data and actions come from the caller.
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';
import 'shell.dart';

class DrDeviceItem {
  final String id;
  final String name;
  final bool online;
  final String platform; // "macOS", "Windows", "Linux", "Android", ""
  final String lastSeen; // human text, may be empty
  const DrDeviceItem(
      {required this.id,
      required this.name,
      required this.online,
      this.platform = '',
      this.lastSeen = ''});
}

class DrHomeData {
  final String myId;

  /// null when no temporary password is in use (permanent-only or approve-by-click).
  final String? password;
  final bool canRefreshPassword;

  /// Shown under the hero heading when the service isn't ready (e.g. "Connecting to server…").
  final String? statusWarning;
  final List<DrDeviceItem> recent;
  const DrHomeData(
      {required this.myId,
      required this.password,
      this.canRefreshPassword = true,
      this.statusWarning,
      this.recent = const []});
}

class DrHomeView extends StatelessWidget {
  final DrHomeData data;
  final TextEditingController idController;
  final FocusNode? idFocus;
  final VoidCallback onCopyCredentials;
  final VoidCallback onNewPassword;
  final ValueChanged<String> onConnect;
  final ValueChanged<String> onConnectDevice;
  final VoidCallback onSeeAll;
  final Widget? idFieldOverride; // lets the app keep its own autocomplete field

  const DrHomeView(
      {super.key,
      required this.data,
      required this.idController,
      this.idFocus,
      required this.onCopyCredentials,
      required this.onNewPassword,
      required this.onConnect,
      required this.onConnectDevice,
      required this.onSeeAll,
      this.idFieldOverride});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return DrPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 340,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 108, child: _shareCard(context, c)),
                const SizedBox(width: 20),
                Expanded(flex: 100, child: _connectCard(context, c)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Recent devices',
                  style: DrText.sans(15, c.text, weight: FontWeight.w600)),
              const Spacer(),
              DrLink('See all',
                  onTap: onSeeAll, weight: FontWeight.w500, color: c.textMuted),
            ],
          ),
          const SizedBox(height: 14),
          data.recent.isEmpty
              ? DrCard(
                  radius: DrRadius.tile,
                  padding: const EdgeInsets.all(22),
                  child: Text(
                      'Devices you connect to will show up here.',
                      style: DrText.sans(13, c.textSubtle)),
                )
              : _recentGrid(c),
        ],
      ),
    );
  }

  Widget _shareCard(BuildContext context, DrColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 30),
      decoration: BoxDecoration(
          color: c.accent, borderRadius: BorderRadius.circular(DrRadius.hero)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Share this device',
              style: DrText.sans(13, c.accentTextMuted, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Let someone help you', style: DrText.serif(32, c.text)),
          if (data.statusWarning != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: c.danger, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(data.statusWarning!,
                    style: DrText.sans(13, c.accentTextMuted,
                        weight: FontWeight.w500)),
              ),
            ]),
          ],
          const Spacer(),
          Wrap(
            spacing: 40,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _labelled(c, 'Your ID',
                  SelectableText(drFormatId(data.myId),
                      style: DrText.sans(46, c.text,
                          weight: FontWeight.w600,
                          letterSpacing: -0.46,
                          height: 1.05,
                          tabular: true))),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _labelled(
                    c,
                    'Password',
                    SelectableText(data.password ?? '—',
                        style: DrText.sans(24, c.text,
                            weight: FontWeight.w500, letterSpacing: 2.4))),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Wrap(spacing: 10, runSpacing: 10, children: [
            DrButton(
                data.password == null ? 'Copy ID' : 'Copy ID and password',
                onPressed: onCopyCredentials),
            if (data.password != null)
              DrButton('New password',
                  kind: DrButtonKind.ghostOnAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  onPressed: data.canRefreshPassword ? onNewPassword : null),
          ]),
        ],
      ),
    );
  }

  Widget _labelled(DrColors c, String label, Widget value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: DrText.sans(13, c.accentTextMuted)),
          const SizedBox(height: 4),
          value,
        ],
      );

  Widget _connectCard(BuildContext context, DrColors c) {
    return DrCard(
      radius: DrRadius.hero,
      shadow: true,
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Connect',
              style: DrText.sans(13, c.textMuted, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Reach another device', style: DrText.serif(32, c.text)),
          const Spacer(),
          Text('Device ID', style: DrText.sans(13, c.textMuted)),
          const SizedBox(height: 8),
          idFieldOverride ??
              DrPillField(
                controller: idController,
                focusNode: idFocus,
                hint: '000 000 000',
                letterSpacing: 0.72,
                semanticLabel: 'Device ID',
                onSubmitted: onConnect,
              ),
          const SizedBox(height: 12),
          DrButton('Connect',
              height: 50,
              fontSize: 15,
              expand: true,
              onPressed: () => onConnect(idController.text)),
        ],
      ),
    );
  }

  Widget _recentGrid(DrColors c) {
    final items = data.recent.take(4).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(
              child: i < items.length
                  ? _DeviceTile(
                      item: items[i],
                      onConnect: () => onConnectDevice(items[i].id))
                  : const SizedBox()),
        ]
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final DrDeviceItem item;
  final VoidCallback onConnect;
  const _DeviceTile({required this.item, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return DrCard(
      radius: DrRadius.tile,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DrText.sans(15, c.text, weight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(drFormatId(item.id),
              style: DrText.sans(13, c.textSubtle, tabular: true)),
          const SizedBox(height: 14),
          Row(children: [
            DrStatusDot(online: item.online),
            const Spacer(),
            if (item.online) DrLink('Connect →', onTap: onConnect),
          ]),
        ],
      ),
    );
  }
}
