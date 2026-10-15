// Browser preview of the DigitalRViewer desktop screens with the mockups' sample data.
import 'package:flutter/material.dart';

import 'dr/theme.dart';
import 'dr/widgets.dart' show DrNotice, DrButton;
import 'dr/screens/shell.dart';
import 'dr/screens/home_view.dart';
import 'dr/screens/add_device_dialog.dart';
import 'dr/screens/devices_view.dart';
import 'dr/screens/network_switch.dart';
import 'dr/screens/rustdesk_invite_dialog.dart';
import 'dr/screens/save_prompt.dart';
import 'dr/screens/incoming_view.dart';
import 'dr/screens/settings_view.dart';
import 'dr/screens/transfers_view.dart';

void main() => runApp(const PreviewApp());

const _recent = [
  DrDeviceItem(id: '482913557', name: 'Design MacBook', online: true, platform: 'macOS', lastSeen: 'Saved', saved: true, recent: true, note: 'Studio, 2nd floor'),
  DrDeviceItem(id: '129004381', name: 'Office PC', online: true, platform: 'Windows', lastSeen: 'Saved', saved: true, favourite: true, recent: true),
  DrDeviceItem(id: '771320916', name: "Ravi's Laptop", online: false, platform: 'Windows', lastSeen: 'Recent', recent: true),
  DrDeviceItem(id: '305118642', name: 'Render Server', online: true, platform: 'Linux', lastSeen: 'Favourite', favourite: true, recent: true),
  DrDeviceItem(id: '640227019', name: 'Front Desk', online: true, platform: '', lastSeen: 'Saved', saved: true, note: 'Reception — ask Priya'),
  DrDeviceItem(id: '918450332', name: 'Home iMac', online: false, platform: 'macOS', lastSeen: 'Recent', recent: true),
  DrDeviceItem(id: '1402567788@public', name: 'Client laptop', online: true, platform: 'Windows', lastSeen: 'Saved', saved: true, recent: true, note: 'Uses the RustDesk app'),
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
  late double _w, _h;
  late bool _notice;
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
    _w = double.tryParse(q['w'] ?? '') ?? 1200;
    _h = double.tryParse(q['h'] ?? '') ?? 760;
    _notice = q['notice'] == '1';
    _signedIn = q['signedin'] == '1';
    _prompt = q['prompt'] == '1';
    _network = q['net'] == 'rustdesk' ? DrNetwork.rustdesk : DrNetwork.ours;
    _hint = q['hint'] == '1';
    if (q['invite'] == '1') {
      WidgetsBinding.instance.addPostFrameCallback((_) => drShowRustDeskInviteDialog(
          _navKey.currentState!.overlay!.context,
          code: drRustDeskInviteCode('318552904', '163.128.34.42', 'ihG8O4mHHiAvvNjVbt02xFUm3umqBfgQFQlyIlyosLQ='),
          password: 'k7mq2x'));
    }
    if (q['dialog'] == '1') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _addDevice(id: q['id'] ?? ''));
    }
  }

  late bool _signedIn;
  late bool _prompt;
  late DrNetwork _network;
  late bool _hint;
  final _navKey = GlobalKey<NavigatorState>();

  Future<void> _addDevice({String id = ''}) => drShowAddDeviceDialog(
        _navKey.currentState!.overlay!.context,
        id: id,
        signedIn: _signedIn,
        onConnect: (_) {},
        onCheck: (id) async {
          await Future.delayed(const Duration(milliseconds: 600));
          if (!RegExp(r'^\d{6,}$').hasMatch(id)) return DrIdStatus.invalid;
          return id.endsWith('0') ? DrIdStatus.offline : DrIdStatus.online;
        },
        onSave: (id, name, note) async => null,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
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
              width: _w,
              height: _h,
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
                if (_prompt)
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: DrSavePromptCard(
                      id: '771320916',
                      name: "Ravi's Laptop",
                      platform: 'Windows',
                      signedIn: _signedIn,
                      onSave: () => setState(() => _prompt = false),
                      onEdit: () => _addDevice(id: '771320916'),
                      onNotNow: () => setState(() => _prompt = false),
                    ),
                  ),
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
          banner: _notice
              ? const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: DrNotice(
                      title: 'Permissions',
                      message: 'In order to access your Desktop remotely, you need to grant DigitalRViewer "Screen Recording" permissions.',
                      actionLabel: 'Configure',
                      onAction: _noop),
                )
              : null,
          idController: _id,
          onCopyCredentials: () {},
          onNewPassword: () {},
          onConnect: (_) {},
          onConnectDevice: (_) {},
          onSeeAll: () => setState(() => _tab = DrTab.devices),
          network: _network,
          onNetwork: (n) => setState(() => _network = n),
          onRustDeskInvite: () => drShowRustDeskInviteDialog(context,
              code: drRustDeskInviteCode('318552904', '163.128.34.42', 'ihG8O4mHHiAvvNjVbt02xFUm3umqBfgQFQlyIlyosLQ='),
              password: 'k7mq2x'),
          connectHint: _hint ? _HintPreview(onTap: () => setState(() => _hint = false)) : null,
        );
      case DrTab.devices:
        return DrDevicesView(
          devices: _recent,
          lastSeenHeader: 'List',
          signedIn: _signedIn,
          onSignIn: () => setState(() => _signedIn = true),
          onConnect: (_) {},
          onFiles: (_) {},
          onAddDevice: () => _addDevice(),
          onAddId: (id) => _addDevice(id: id),
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

void _noop() {}

class _HintPreview extends StatelessWidget {
  final VoidCallback onTap;
  const _HintPreview({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: c.accent,
        border: Border.all(color: c.accentBorder),
        borderRadius: BorderRadius.circular(DrRadius.tile),
      ),
      child: Row(children: [
        Expanded(
          child: Text('140 256 778 8 isn’t on Digital R Viewer, but a RustDesk app with this ID is online.',
              style: DrText.sans(13, c.accentText, height: 1.4)),
        ),
        const SizedBox(width: 10),
        DrButton('Connect via RustDesk', height: 36, fontSize: 13, onPressed: onTap),
      ]),
    );
  }
}
