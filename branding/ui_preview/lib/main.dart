// Browser preview of the DigitalRViewer desktop screens with the mockups' sample data.
import 'package:flutter/material.dart';

import 'dr/theme.dart';
import 'dr/widgets.dart' show DrNotice, DrButton, DrButtonKind;
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
  String _pw = 'click';
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
        const sections = ['Basics', 'Remote access', 'Your sessions', 'Recording', 'Your account', 'Advanced', 'App info'];
        return DrSettingsShell(
          sections: sections,
          selected: _settingsSection,
          onSelect: (i) => setState(() => _settingsSection = i),
          content: _settingsSection == 5 ? _advanced() : (_settingsSection == 0 ? _basics() : _remoteAccess()),
        );
    }
  }

  Widget _basics() => DrSettingsPage(
        title: 'Basics',
        subtitle: 'How the app looks, which language it speaks, and when it runs.',
        children: [
          DrSettingsGroup(title: 'Look and language', children: [
            DrSettingRow(
              title: 'Appearance',
              trailing: DrChoicePills<String>(
                options: const [('light', 'Light'), ('dark', 'Dark'), ('system', 'Match system')],
                value: _dark ? 'dark' : 'light',
                onChanged: (v) => setState(() => _dark = v == 'dark'),
              ),
            ),
            DrSettingRow(
              title: 'Language',
              trailing: DrSelect<String>(
                options: const [('default', 'Same as my computer'), ('en', 'English'), ('hi', 'हिन्दी')],
                value: 'default',
                onChanged: (_) {},
              ),
            ),
          ]),
          DrSettingsGroup(title: 'Availability', children: [
            DrSettingRow(
              title: 'Remote access is on',
              description: 'Other people can connect to this computer with your ID and password.',
              trailing: DrButton('Pause', kind: DrButtonKind.secondary, height: 38, fontSize: 13, onPressed: () {}),
            ),
          ]),
          DrSettingsGroup(title: 'Stay awake', children: [
            DrToggleRow(title: 'While someone is connected to this computer', description: 'Stops this computer going to sleep in the middle of a session.', value: true, onChanged: (_) {}),
            DrToggleRow(title: 'While I’m connected to another computer', value: false, onChanged: (_) {}),
          ]),
        ],
      );

  Widget _remoteAccess() => DrSettingsPage(
        title: 'Remote access',
        subtitle: 'Decide how people get into this computer and what they’re allowed to do once they’re in.',
        children: [
          DrUnlockBanner(message: 'Remote access can only be changed by an administrator of this computer.', onUnlock: () {}),
          DrSettingsGroup(title: 'How people get in', children: [
            DrRadioCards<String>(
              options: const [
                DrRadioOption('click', 'Ask me every time', 'A request pops up and you choose Allow or Decline.'),
                DrRadioOption('password', 'Password only', 'Anyone with the right password gets in without asking.'),
                DrRadioOption('both', 'Either way', 'A password lets them straight in; without one, you’re asked.'),
              ],
              selected: _pw,
              onSelect: (v) => setState(() => _pw = v),
            ),
          ]),
          DrSettingsGroup(title: 'Passwords', children: [
            DrSettingRow(
              title: 'Fresh password length',
              trailing: DrChoicePills<String>(options: const [('6', '6'), ('8', '8'), ('10', '10')], value: '6', onChanged: (_) {}),
            ),
            DrToggleRow(title: 'Numbers only', description: 'Easier to read out over the phone.', value: _toggles['clip']!, onChanged: (v) => setState(() => _toggles['clip'] = v)),
            DrSettingRow(
              title: 'Fixed password',
              description: 'Set or change the password for unattended access.',
              trailing: DrButton('Set password…', kind: DrButtonKind.secondary, height: 38, fontSize: 13, onPressed: () {}),
            ),
          ]),
          DrSettingsGroup(title: 'What they can do', children: [
            DrSettingRow(
              title: 'Access level',
              description: 'Choose each permission below.',
              trailing: DrChoicePills<String>(
                options: const [('full', 'Full control'), ('view', 'View only'), ('custom', 'Choose…')],
                value: 'custom',
                onChanged: (_) {},
              ),
            ),
            DrToggleRow(title: 'Use my mouse and keyboard', value: _toggles['in']!, onChanged: (v) => setState(() => _toggles['in'] = v)),
            DrToggleRow(title: 'Send and receive files', value: _toggles['file']!, onChanged: (v) => setState(() => _toggles['file'] = v)),
            const DrToggleRow(title: 'Change my settings', value: false, badge: 'Set by your organisation'),
          ]),
          DrSettingsGroup(title: 'Protection', children: [
            DrToggleRow(title: 'End idle sessions automatically', description: 'Disconnects people who haven’t done anything for a while.', value: true, onChanged: (_) {}),
            DrSubRows(children: [
              DrSettingRow(title: 'After', trailing: DrInputApply(value: '10', hint: '10', suffix: 'minutes', onApply: (_) async {})),
            ]),
          ]),
        ],
      );

  Widget _advanced() => DrSettingsPage(
        title: 'Advanced',
        subtitle: 'Technical options. The defaults work well for almost everyone — only change these if you know you need to.',
        children: [
          DrCollapsibleGroup(title: 'Performance', subtitle: 'Video encoding and how the picture is drawn', initiallyOpen: true, children: [
            DrToggleRow(title: 'Use the graphics card for video', description: 'Smoother and lighter on the processor when supported.', value: true, onChanged: (_) {}),
            DrSettingRow(
              title: 'Preferred video format',
              trailing: DrSelect<String>(width: 160, options: const [('auto', 'Automatic'), ('vp9', 'VP9'), ('av1', 'AV1')], value: 'auto', onChanged: (_) {}),
            ),
          ]),
          const DrCollapsibleGroup(title: 'Connection', subtitle: 'Direct links, proxies and network fallbacks', children: []),
          const DrCollapsibleGroup(title: 'Session window', subtitle: 'The bar and screen controls during a session', children: []),
        ],
      );
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
