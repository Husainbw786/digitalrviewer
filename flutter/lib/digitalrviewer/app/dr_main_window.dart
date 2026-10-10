// App-side adapters: connect the DigitalRViewer screens (../screens, Flutter-only) to
// RustDesk's models. Existing RustDesk pages call into this file through one-line hooks
// guarded by [kDrUi]; with kDrUi = false the stock RustDesk UI is used unchanged.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/widgets/tabbar_widget.dart';
import 'package:flutter_hbb/models/peer_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../screens/devices_view.dart';
import '../screens/home_view.dart';
import '../screens/shell.dart';
import '../screens/transfers_view.dart';
import '../theme.dart';
import '../widgets.dart' show drFormatId;
import 'dr_update.dart';

/// Master switch for the DigitalRViewer UI.
const bool kDrUi = true;

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
    return Scaffold(
      backgroundColor: c.bg,
      body: Obx(() {
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
      }),
    );
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
        actions: const DrUpdatePill(),
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
  final _recent = _PeerFeed();

  @override
  void initState() {
    super.initState();
    // connect() writes the dialled ID back into the registered controller.
    if (!Get.isRegistered<IDTextEditingController>()) {
      Get.put<IDTextEditingController>(_idController);
    }
    bind.mainGetLastRemoteId().then((id) {
      if (mounted && _idController.text.isEmpty) _idController.id = id;
    });
    _recent.start(onChange: () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _recent.stop();
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
          widget.banners,
          Expanded(
            child: DrHomeView(
              data: DrHomeData(
                myId: outgoingOnly ? '' : myId,
                password: outgoingOnly ? null : password,
                recent: _recent.items,
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
              onConnect: (_) => connect(context, _idController.id),
              onConnectDevice: (id) => connect(context, id),
              onSeeAll: () => drShowTab(DrTab.devices),
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

/// Recent + favourite peers with live online status, shared by Home and Devices.
class _PeerFeed {
  List<DrDeviceItem> items = const [];
  VoidCallback? _onChange;
  Timer? _onlineTimer;

  void start({required VoidCallback onChange}) {
    _onChange = onChange;
    gFFI.recentPeersModel.addListener(_rebuild);
    gFFI.favoritePeersModel.addListener(_rebuild);
    bind.mainLoadRecentPeers();
    bind.mainLoadFavPeers();
    _onlineTimer = Timer.periodic(const Duration(seconds: 10), (_) => _query());
    Future.delayed(const Duration(seconds: 1), _query);
    _rebuild();
  }

  void stop() {
    gFFI.recentPeersModel.removeListener(_rebuild);
    gFFI.favoritePeersModel.removeListener(_rebuild);
    _onlineTimer?.cancel();
  }

  void _query() {
    final ids = items.map((e) => e.id).toList();
    if (ids.isNotEmpty) bind.queryOnlines(ids: ids);
  }

  void _rebuild() {
    final favIds = gFFI.favoritePeersModel.peers.map((p) => p.id).toSet();
    final seen = <String>{};
    final out = <DrDeviceItem>[];
    for (final p in [
      ...gFFI.recentPeersModel.peers,
      ...gFFI.favoritePeersModel.peers
    ]) {
      if (p.id.isEmpty || !seen.add(p.id)) continue;
      out.add(DrDeviceItem(
        id: p.id,
        name: drPeerName(p),
        online: p.online,
        platform: drPlatformLabel(p.platform),
        lastSeen: favIds.contains(p.id) ? 'Favourite' : 'Recent',
      ));
    }
    final before = items.map((e) => '${e.id}${e.online}${e.name}').join();
    final after = out.map((e) => '${e.id}${e.online}${e.name}').join();
    items = out;
    if (before != after) _onChange?.call();
  }
}

String drPeerName(Peer p) {
  if (p.alias.isNotEmpty) return p.alias;
  if (p.hostname.isNotEmpty) return p.hostname;
  return drFormatId(p.id);
}

String drPlatformLabel(String platform) {
  final p = platform.toLowerCase();
  if (p.contains('mac')) return 'macOS';
  if (p.contains('win')) return 'Windows';
  if (p.contains('linux')) return 'Linux';
  if (p.contains('android')) return 'Android';
  if (p.contains('ios')) return 'iOS';
  return platform;
}

class DrDevicesPane extends StatefulWidget {
  const DrDevicesPane({super.key});
  @override
  State<DrDevicesPane> createState() => _DrDevicesPaneState();
}

class _DrDevicesPaneState extends State<DrDevicesPane> {
  final _feed = _PeerFeed();

  @override
  void initState() {
    super.initState();
    _feed.start(onChange: () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _feed.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrDevicesView(
      devices: _feed.items,
      lastSeenHeader: 'List',
      onConnect: (id) => connect(context, id),
      onFiles: (id) => connect(context, id, isFileTransfer: true),
      onAddDevice: () => drShowTab(DrTab.home),
      menuBuilder: (item) => _menu(context, item),
    );
  }

  Widget _menu(BuildContext context, DrDeviceItem item) {
    final c = DrColors.of(context);
    final isFav = item.lastSeen == 'Favourite';
    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: Icon(Icons.more_horiz, size: 18, color: c.textMuted),
      onSelected: (v) async {
        switch (v) {
          case 'fav':
            final favs = (await bind.mainGetFav()).toList();
            if (isFav) {
              favs.remove(item.id);
            } else if (!favs.contains(item.id)) {
              favs.add(item.id);
            }
            await bind.mainStoreFav(favs: favs);
            bind.mainLoadFavPeers();
            break;
          case 'remove':
            await bind.mainRemovePeer(id: item.id);
            bind.mainLoadRecentPeers();
            bind.mainLoadFavPeers();
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
            value: 'fav',
            child: Text(isFav ? 'Remove from favourites' : 'Add to favourites')),
        const PopupMenuItem(value: 'remove', child: Text('Remove from list')),
      ],
    );
  }
}

class DrTransfersPane extends StatefulWidget {
  const DrTransfersPane({super.key});
  @override
  State<DrTransfersPane> createState() => _DrTransfersPaneState();
}

class _DrTransfersPaneState extends State<DrTransfersPane> {
  final _feed = _PeerFeed();

  @override
  void initState() {
    super.initState();
    _feed.start(onChange: () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _feed.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DrTransfersView(
        devices: _feed.items,
        onOpen: (id) => connect(context, id, isFileTransfer: true),
      );
}
