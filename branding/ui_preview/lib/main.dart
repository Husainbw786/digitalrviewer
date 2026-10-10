// Browser preview of the DigitalRViewer desktop screens with the mockups' sample data.
import 'package:flutter/material.dart';

import 'dr/theme.dart';
import 'dr/screens/shell.dart';
import 'dr/screens/home_view.dart';
import 'dr/screens/devices_view.dart';
import 'dr/screens/incoming_view.dart';
import 'dr/screens/settings_view.dart';
import 'dr/screens/transfers_view.dart';

void main() => runApp(const PreviewApp());

const _recent = [
  DrDeviceItem(id: '482913557', name: 'Design MacBook', online: true, platform: 'macOS', lastSeen: 'Today, 10:42'),
  DrDeviceItem(id: '129004381', name: 'Office PC', online: true, platform: 'Windows', lastSeen: 'Today, 09:15'),
  DrDeviceItem(id: '771320916', name: "Ravi's Laptop", online: false, platform: 'Windows', lastSeen: 'Yesterday'),
  DrDeviceItem(id: '305118642', name: 'Render Server', online: true, platform: 'Linux', lastSeen: '2 days ago'),
  DrDeviceItem(id: '640227019', name: 'Front Desk', online: true, platform: 'Windows', lastSeen: 'Last week'),
  DrDeviceItem(id: '918450332', name: 'Home iMac', online: false, platform: 'macOS', lastSeen: 'Last month'),
];

class PreviewApp extends StatefulWidget {
  const PreviewApp({super.key});
  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  late DrTab _tab;
  late bool _dark;
  late bool _incoming;
  late bool _cm;
  final _id = TextEditingController();
  int _settingsSection = 1;
  final Map<String, bool> _toggles = {
    'in': true, 'ask': true, 'file': true, 'clip': false,
  };
  String _pw = 'one';
  final Map<String, bool> _perms = {'screen': true, 'input': true, 'files': true, 'clip': false};

  @override
  void initState() {
    super.initState();
    final q = Uri.base.queryParameters;
    _tab = switch (q['screen']) {
      'devices' => DrTab.devices,
      'settings' => DrTab.settings,
      'transfers' => DrTab.transfers,
      _ => DrTab.home,
    };
    _incoming = q['screen'] == 'incoming';
    _cm = q['screen'] == 'cm';
    _dark = q['dark'] == '1';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: drThemeData(Brightness.light),
      darkTheme: drThemeData(Brightness.dark),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: Builder(builder: (context) {
        final c = DrColors.of(context);
        return Scaffold(
          backgroundColor: const Color(0xFF2B2A28),
          body: _cm ? Center(child: Container(
            width: 300, height: 490, clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(DrRadius.window)),
            child: SingleChildScrollView(child: DrIncomingRequestCard(
              compact: true, name: "Ravi's Laptop", peerId: '771320916',
              note: 'They will see your screen. You can end the session at any time.',
              permissions: [
                DrPermission('Use your mouse and keyboard', _perms['input']!, (v) => setState(() => _perms['input'] = v)),
                DrPermission('Use your clipboard', _perms['clip']!, (v) => setState(() => _perms['clip'] = v)),
                DrPermission('Send and receive files', _perms['files']!, (v) => setState(() => _perms['files'] = v)),
                DrPermission('Hear your audio', _perms['screen']!, (v) => setState(() => _perms['screen'] = v)),
              ],
              onAllow: () {}, onDecline: () {})),
          )) : Center(
            child: Container(
              width: 1200,
              height: 760,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(DrRadius.window),
                border: Border.all(color: c.border),
              ),
              child: Stack(children: [
                Column(children: [
                  DrTopBar(
                    tab: _tab,
                    leadingInset: 60, // where macOS draws the traffic lights
                    onTab: (t) => setState(() => _tab = t),
                  ),
                  Expanded(child: _body(context)),
                ]),
                const Positioned(left: 24, top: 26, child: _TrafficLights()),
                if (_incoming)
                  Positioned.fill(
                    child: Container(
                      color: c.scrim,
                      alignment: Alignment.center,
                      child: DrIncomingRequestCard(
                        name: "Ravi's Laptop",
                        peerId: '771320916',
                        permissions: [
                          DrPermission('See your screen', _perms['screen']!, (v) => setState(() => _perms['screen'] = v)),
                          DrPermission('Use your mouse and keyboard', _perms['input']!, (v) => setState(() => _perms['input'] = v)),
                          DrPermission('Send and receive files', _perms['files']!, (v) => setState(() => _perms['files'] = v)),
                          DrPermission('Use your clipboard', _perms['clip']!, (v) => setState(() => _perms['clip'] = v)),
                        ],
                        onAllow: () => setState(() => _incoming = false),
                        onDecline: () => setState(() => _incoming = false),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          floatingActionButton: FloatingActionButton.small(
            backgroundColor: Colors.white,
            onPressed: () => setState(() => _dark = !_dark),
            child: Icon(_dark ? Icons.light_mode : Icons.dark_mode, color: Colors.black),
          ),
        );
      }),
    );
  }

  Widget _body(BuildContext context) {
    switch (_tab) {
      case DrTab.home:
        return DrHomeView(
          data: const DrHomeData(myId: '318552904', password: 'k7mq2x', recent: _recent),
          idController: _id,
          onCopyCredentials: () {},
          onNewPassword: () {},
          onConnect: (_) {},
          onConnectDevice: (_) {},
          onSeeAll: () => setState(() => _tab = DrTab.devices),
        );
      case DrTab.devices:
        return DrDevicesView(
          devices: _recent,
          onConnect: (_) {},
          onFiles: (_) {},
          onAddDevice: () {},
        );
      case DrTab.transfers:
        return DrTransfersView(devices: _recent, onOpen: (_) {});
      case DrTab.settings:
        return DrSettingsShell(
          sections: const ['General', 'Security', 'Display', 'Audio', 'Network', 'About'],
          selected: _settingsSection,
          onSelect: (i) => setState(() => _settingsSection = i),
          content: DrSettingsPage(
            title: 'Security',
            subtitle: 'Control who can reach this device and what they can do.',
            children: [
              DrSettingsGroup(children: [
                DrToggleRow(title: 'Allow incoming connections', description: 'People with your ID and password can ask to connect.', value: _toggles['in']!, onChanged: (v) => setState(() => _toggles['in'] = v)),
                DrToggleRow(title: 'Ask me before each connection', description: 'Show a prompt you approve before anyone sees your screen.', value: _toggles['ask']!, onChanged: (v) => setState(() => _toggles['ask'] = v)),
                DrToggleRow(title: 'Allow file transfer', description: 'Let connected devices send and receive files.', value: _toggles['file']!, onChanged: (v) => setState(() => _toggles['file'] = v)),
                DrToggleRow(title: 'Share clipboard', description: 'Copy on one device, paste on the other.', value: _toggles['clip']!, onChanged: (v) => setState(() => _toggles['clip'] = v)),
              ]),
              DrSettingsGroup(title: 'Password', children: [
                DrRadioCards<String>(
                  options: const [
                    DrRadioOption('one', 'One-time password', 'A new password for every session.'),
                    DrRadioOption('perm', 'Permanent password', 'For your own unattended devices.'),
                  ],
                  selected: _pw,
                  onSelect: (v) => setState(() => _pw = v),
                ),
              ]),
            ],
          ),
        );
    }
  }
}

class _TrafficLights extends StatelessWidget {
  const _TrafficLights();
  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    Widget dot() => Container(width: 12, height: 12, decoration: BoxDecoration(color: c.borderStrong, shape: BoxShape.circle));
    return Row(children: [dot(), const SizedBox(width: 8), dot(), const SizedBox(width: 8), dot()]);
  }
}
