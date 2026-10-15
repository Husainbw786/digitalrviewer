// App-side adapters: connect the DigitalRViewer screens (../screens, Flutter-only) to
// RustDesk's models. Existing RustDesk pages call into this file through one-line hooks
// guarded by [kDrUi]; with kDrUi = false the stock RustDesk UI is used unchanged.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/common/widgets/login.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/widgets/tabbar_widget.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../screens/add_device_dialog.dart';
import '../screens/devices_view.dart';
import '../screens/home_view.dart';
import '../screens/network_switch.dart';
import '../screens/rustdesk_invite_dialog.dart';
import '../screens/save_prompt.dart';
import '../screens/shell.dart';
import '../screens/transfers_view.dart';
import '../theme.dart';
import '../widgets.dart' show drFormatId, DrInitials, DrButton;
import 'dr_devices.dart';
import 'dr_update.dart';

/// Master switch for the DigitalRViewer UI.
const bool kDrUi = true;

/// Fallbacks for the RustDesk-user invite code; keep in step with src/branding.rs
/// (normally the locked options supply these).
const String kDrIdServer = '163.128.34.42';
const String kDrServerKey = 'ihG8O4mHHiAvvNjVbt02xFUm3umqBfgQFQlyIlyosLQ=';
const String _kNetworkKey = 'dr-connect-network';

/// Wraps one of RustDesk's ThemeData so stock widgets pick up the design system.
/// Desktop only: the mobile UI has not been redesigned.
ThemeData drAppTheme(ThemeData base) =>
    kDrUi && isDesktop ? drThemeData(base.brightness, base: base) : base;

final Rx<DrTab> _drTab = DrTab.home.obs;
final Rx<SettingsTabKey?> _drSettingsInitial = Rx<SettingsTabKey?>(null);

/// Replacement for DesktopTabPage.onAddSetting: shows the Settings tab of the main window.
void drShowSettings(SettingsTabKey initialPage) {
  _drSettingsInitial.value ??= initialPage;
  _drTab.value = DrTab.settings;
}

void drShowTab(DrTab tab) => _drTab.value = tab;

/// The new layout needs more room than the stock UI: enforce a minimum main-window size,
/// and grow a window restored at a smaller size (e.g. saved by an older build).
const Size kDrMinMainWindowSize = Size(960, 660);
const Size kDrDefaultMainWindowSize = Size(1180, 760);

Future<void> drEnsureMainWindowSize() async {
  if (!kDrUi || !isDesktop || bind.isIncomingOnly()) return;
  try {
    await windowManager.setMinimumSize(kDrMinMainWindowSize);
    final s = await windowManager.getSize();
    if (s.width < kDrMinMainWindowSize.width ||
        s.height < kDrMinMainWindowSize.height) {
      await windowManager.setSize(Size(
          s.width < kDrDefaultMainWindowSize.width
              ? kDrDefaultMainWindowSize.width
              : s.width,
          s.height < kDrDefaultMainWindowSize.height
              ? kDrDefaultMainWindowSize.height
              : s.height));
      await windowManager.center();
    }
  } catch (e) {
    debugPrint('drEnsureMainWindowSize: $e');
  }
}

/// The main window: draggable top bar (brand, nav, settings, window buttons) + pages.
class DrMainWindow extends StatelessWidget {
  final DesktopTabController tabController;

  /// The stock DesktopHomePage. It renders the DigitalRViewer home (see [DrHomePane]) but
  /// stays mounted for its background duties (multi-window events, permission checks).
  final Widget homePage;

  const DrMainWindow(
      {super.key, required this.tabController, required this.homePage});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    DrUpdater.instance.start();
    DrDevicesStore.instance.start();
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        _pages(context),
        const Positioned(right: 24, bottom: 56, child: _DrSavePromptHost()),
      ]),
    );
  }

  Widget _pages(BuildContext context) {
    return Obx(() {
        final tab = _drTab.value;
        final initialSettings = _drSettingsInitial.value;
        return Column(children: [
          _titleBar(context, tab),
          Expanded(
            child: IndexedStack(
              index: DrTab.values.indexOf(tab),
              children: [
                homePage,
                const DrDevicesPane(),
                const DrTransfersPane(),
                initialSettings == null
                    ? const SizedBox()
                    : DesktopSettingPage(
                        key: const ValueKey(kTabLabelSettingPage),
                        initialTabkey: initialSettings),
              ],
            ),
          ),
        ]);
      });
  }

  Widget _titleBar(BuildContext context, DrTab tab) {
    final hideSettings = bind.isIncomingOnly() || bind.isDisableSettings();
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => startDragging(true),
      onPanCancel: () {
        if (isMacOS) setMovable(true, false);
      },
      onPanEnd: (_) {
        if (isMacOS) setMovable(true, false);
      },
      onDoubleTap: () =>
          toggleMaximize(true).then((v) => stateGlobal.setMaximized(v)),
      child: DrTopBar(
        tab: tab,
        // macOS draws the traffic lights at the top-left of the window.
        leadingInset: isMacOS ? 62 : 0,
        actions: const Row(mainAxisSize: MainAxisSize.min, children: [
          DrUpdatePill(),
          _DrAccountChip(),
        ]),
        onTab: (t) {
          if (t == DrTab.settings) {
            if (hideSettings) return;
            drShowSettings(SettingsTabKey.general);
          } else {
            _drTab.value = t;
          }
        },
        trailing: isMacOS || kUseCompatibleUiMode
            ? null
            : WindowActionPanel(
                isMainWindow: true,
                state: tabController.state,
                tabController: tabController,
                invisibleTabKeys: RxList<String>(),
              ),
      ),
    );
  }
}

/// Home tab content, built inside DesktopHomePage.build().
class DrHomePane extends StatefulWidget {
  /// Warnings DesktopHomePage computes (permissions, install, preset password, errors).
  final Widget banners;
  const DrHomePane({super.key, required this.banners});

  @override
  State<DrHomePane> createState() => _DrHomePaneState();
}

class _DrHomePaneState extends State<DrHomePane> {
  final _idController = IDTextEditingController();
  final _idFocus = FocusNode();
  final _store = DrDevicesStore.instance;
  DrNetwork _network = DrNetwork.ours;

  /// Set when an ID wasn't found on our network but is online on RustDesk's.
  String? _hintId;
  bool _checking = false;

  void _changed() {
    if (mounted) setState(() {});
  }

  void _setNetwork(DrNetwork n) {
    setState(() {
      _network = n;
      _hintId = null;
    });
    bind.mainSetLocalOption(
        key: _kNetworkKey, value: n == DrNetwork.rustdesk ? 'rustdesk' : '');
  }

  /// connect() writes the dialled ID ("123@public") back into the field: show the bare ID and
  /// move the switch instead.
  void _onIdChanged() {
    final text = _idController.text.replaceAll(' ', '');
    if (drIsRustDeskId(text)) {
      _idController.id = drBareId(text);
      if (_network != DrNetwork.rustdesk) _setNetwork(DrNetwork.rustdesk);
    } else if (_hintId != null && drBareId(_hintId!) != text) {
      setState(() => _hintId = null);
    }
  }

  Future<void> _connect() async {
    final typed = _idController.id.replaceAll(' ', '');
    if (typed.isEmpty || _checking) return;
    // A full "id@server" typed by hand is dialled as is.
    final id = typed.contains('@') ? typed : drIdOnNetwork(typed, _network);
    // Unknown plain ID on our network: make sure it's here before opening a session window,
    // and point to the RustDesk network when that's where it is.
    if (!id.contains('@') && _store.find(id) == null) {
      setState(() => _checking = true);
      final here = await _store.check(id);
      var elsewhere = DrIdStatus.offline;
      if (here == DrIdStatus.offline) {
        elsewhere = await _store.check(drIdOnNetwork(id, DrNetwork.rustdesk));
      }
      if (!mounted) return;
      setState(() => _checking = false);
      if (here == DrIdStatus.offline && elsewhere == DrIdStatus.online) {
        setState(() => _hintId = id);
        return;
      }
    }
    if (mounted) connect(context, id);
  }

  Widget? _connectHint(DrColors c) {
    if (_checking) {
      return Text('Looking for the device…', style: DrText.sans(13, c.textSubtle));
    }
    final id = _hintId;
    if (id == null) return null;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: c.accent,
        border: Border.all(color: c.accentBorder),
        borderRadius: BorderRadius.circular(DrRadius.tile),
      ),
      child: Row(children: [
        Expanded(
          child: Text(
              '${drFormatId(id)} isn’t on Digital R Viewer, but a RustDesk app with this ID is online.',
              style: DrText.sans(13, c.accentText, height: 1.4)),
        ),
        const SizedBox(width: 10),
        DrButton('Connect via RustDesk',
            height: 36,
            fontSize: 13,
            onPressed: () {
              _setNetwork(DrNetwork.rustdesk);
              connect(context, drIdOnNetwork(id, DrNetwork.rustdesk));
            }),
      ]),
    );
  }

  void _showInvite(String myId, String? password) {
    var server = bind.mainGetOptionSync(key: 'custom-rendezvous-server').trim();
    var key = bind.mainGetOptionSync(key: 'key').trim();
    if (server.isEmpty) server = kDrIdServer;
    if (key.isEmpty) key = kDrServerKey;
    drShowRustDeskInviteDialog(context,
        code: drRustDeskInviteCode(myId, server, key),
        password: password,
        onCopied: () => showToast(translate('Copied')));
  }

  @override
  void initState() {
    super.initState();
    // connect() writes the dialled ID back into the registered controller.
    if (!Get.isRegistered<IDTextEditingController>()) {
      Get.put<IDTextEditingController>(_idController);
    }
    if (bind.mainGetLocalOption(key: _kNetworkKey) == 'rustdesk') {
      _network = DrNetwork.rustdesk;
    }
    _idController.addListener(_onIdChanged);
    bind.mainGetLastRemoteId().then((id) {
      if (mounted && _idController.text.isEmpty) _idController.id = id;
    });
    _store.start();
    _store.addListener(_changed);
  }

  @override
  void dispose() {
    _store.removeListener(_changed);
    _idController.removeListener(_onIdChanged);
    if (Get.isRegistered<IDTextEditingController>() &&
        Get.find<IDTextEditingController>() == _idController) {
      Get.delete<IDTextEditingController>();
    }
    _idFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Consumer<ServerModel>(builder: (context, model, _) {
        final outgoingOnly = bind.isOutgoingOnly();
        final showOneTime = model.approveMode != 'click' &&
            model.verificationMethod != kUsePermanentPassword;
        final myId = model.serverId.text.replaceAll(' ', '');
        final password = showOneTime ? model.serverPasswd.text : null;
        return Column(children: [
          Expanded(
            child: DrHomeView(
              banner: widget.banners,
              data: DrHomeData(
                myId: outgoingOnly ? '' : myId,
                password: outgoingOnly ? null : password,
                recent: _store.items,
              ),
              idController: _idController,
              idFocus: _idFocus,
              onCopyCredentials: () {
                final text = password == null
                    ? 'ID: ${drFormatId(myId)}'
                    : 'ID: ${drFormatId(myId)}\nPassword: $password';
                Clipboard.setData(ClipboardData(text: text));
                showToast(translate('Copied'));
              },
              onNewPassword: () => bind.mainUpdateTemporaryPassword(),
              onConnect: (_) => _connect(),
              onConnectDevice: (id) => connect(context, id),
              onSeeAll: () => drShowTab(DrTab.devices),
              network: _network,
              onNetwork: _setNetwork,
              connectHint: _connectHint(c),
              onRustDeskInvite: outgoingOnly || myId.isEmpty
                  ? null
                  : () => _showInvite(myId, password),
            ),
          ),
          Container(
            decoration:
                BoxDecoration(border: Border(top: BorderSide(color: c.divider))),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              const Expanded(child: OnlineStatusWidget()),
              Text('Powered by RustDesk',
                  style: DrText.sans(12, c.textSubtle)),
            ]),
          ),
        ]);
      }),
    );
  }
}

/// Rebuilds a widget when the device list changes.
mixin _DrStoreListener<T extends StatefulWidget> on State<T> {
  DrDevicesStore get store => DrDevicesStore.instance;
  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    store.start();
    store.addListener(_changed);
  }

  @override
  void dispose() {
    store.removeListener(_changed);
    super.dispose();
  }
}

bool get _drAccountsEnabled => !bind.isDisableAccount();

Future<void> drSignIn() async {
  if (!_drAccountsEnabled) return;
  await loginDialog();
}

Future<void> drAddDevice(BuildContext context,
    {String id = '', DrDeviceItem? edit}) {
  final store = DrDevicesStore.instance;
  return drShowAddDeviceDialog(
    context,
    signedIn: store.signedIn,
    id: edit?.id ?? id,
    name: edit == null || edit.name == drDisplayId(edit.id) ? '' : edit.name,
    note: edit?.note ?? '',
    editing: edit != null,
    onCheck: store.check,
    onConnect: (id) => connect(context, id),
    onSave: (id, name, note) async {
      final err = await store.save(id, name: name, note: note);
      if (err == null) showToast(edit == null ? 'Device saved' : 'Device updated');
      return err;
    },
  );
}

class DrDevicesPane extends StatefulWidget {
  const DrDevicesPane({super.key});
  @override
  State<DrDevicesPane> createState() => _DrDevicesPaneState();
}

class _DrDevicesPaneState extends State<DrDevicesPane>
    with _DrStoreListener<DrDevicesPane> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Rebuild when the account changes (the banner depends on it).
      gFFI.userModel.userName.value;
      return DrDevicesView(
        devices: store.items,
        lastSeenHeader: 'List',
        signedIn: store.signedIn,
        onSignIn: _drAccountsEnabled ? drSignIn : null,
        onConnect: (id) => connect(context, id),
        onFiles: (id) => connect(context, id, isFileTransfer: true),
        onAddDevice: () => drAddDevice(context),
        onAddId: (id) => drAddDevice(context, id: id),
        menuBuilder: (item) => _menu(context, item),
      );
    });
  }

  Widget _menu(BuildContext context, DrDeviceItem item) {
    final c = DrColors.of(context);
    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: Icon(Icons.more_horiz, size: 18, color: c.textMuted),
      onSelected: (v) async {
        switch (v) {
          case 'save':
            await store.save(item.id,
                name: item.name == drDisplayId(item.id) ? '' : item.name);
            showToast('Device saved');
            break;
          case 'edit':
            await drAddDevice(context, edit: item);
            break;
          case 'fav':
            await store.setFavourite(item.id, !item.favourite);
            break;
          case 'unsave':
            await store.remove(item.id);
            break;
          case 'forget':
            await store.remove(item.id, alsoForget: true);
            break;
        }
      },
      itemBuilder: (_) => [
        if (!item.saved)
          const PopupMenuItem(value: 'save', child: Text('Save to my devices')),
        PopupMenuItem(
            value: 'edit',
            child: Text(item.saved ? 'Rename or add a note' : 'Save with a name or note')),
        PopupMenuItem(
            value: 'fav',
            child: Text(item.favourite
                ? 'Remove from favourites'
                : 'Add to favourites')),
        if (item.saved)
          const PopupMenuItem(
              value: 'unsave', child: Text('Remove from my devices')),
        if (item.recent)
          const PopupMenuItem(
              value: 'forget', child: Text('Remove and forget history')),
      ],
    );
  }
}

/// Floating "Save this device?" card (see [DrDevicesStore.onConnected]).
class _DrSavePromptHost extends StatelessWidget {
  const _DrSavePromptHost();

  @override
  Widget build(BuildContext context) {
    final store = DrDevicesStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = store.prompt;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: p == null
              ? const SizedBox.shrink()
              : DrSavePromptCard(
                  key: ValueKey(p.id),
                  id: p.id,
                  name: p.name,
                  platform: p.platform,
                  signedIn: store.signedIn,
                  onSave: () async {
                    store.dismissPrompt(forever: false);
                    final err = await store.save(p.id, name: p.name);
                    showToast(err ?? 'Device saved');
                  },
                  onEdit: () {
                    store.dismissPrompt(forever: false);
                    drAddDevice(context,
                        edit: DrDeviceItem(id: p.id, name: p.name, online: true));
                  },
                  onNotNow: () => store.dismissPrompt(),
                ),
        );
      },
    );
  }
}

/// Signed-in user's initials in the top bar, with a sign-out menu.
class _DrAccountChip extends StatelessWidget {
  const _DrAccountChip();

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Obx(() {
      final name = gFFI.userModel.userName.value;
      if (!_drAccountsEnabled || name.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(left: 10),
        child: PopupMenuButton<String>(
          tooltip: 'Signed in as $name',
          offset: const Offset(0, 44),
          onSelected: (v) {
            if (v == 'devices') drShowTab(DrTab.devices);
            if (v == 'out') logOutConfirmDialog();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
                enabled: false,
                child: Text('Signed in as $name',
                    style: DrText.sans(13, c.textMuted))),
            const PopupMenuItem(value: 'devices', child: Text('My devices')),
            const PopupMenuItem(value: 'out', child: Text('Sign out')),
          ],
          child: DrInitials(name, size: 36),
        ),
      );
    });
  }
}

class DrTransfersPane extends StatefulWidget {
  const DrTransfersPane({super.key});
  @override
  State<DrTransfersPane> createState() => _DrTransfersPaneState();
}

class _DrTransfersPaneState extends State<DrTransfersPane>
    with _DrStoreListener<DrTransfersPane> {
  @override
  Widget build(BuildContext context) => DrTransfersView(
        devices: store.items,
        onOpen: (id) => connect(context, id, isFileTransfer: true),
      );
}
