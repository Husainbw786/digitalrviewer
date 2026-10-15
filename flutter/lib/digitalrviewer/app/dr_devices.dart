// "My devices": one list made from the stock RustDesk sources (recent sessions, favourites,
// the signed-in user's personal address book) plus devices saved on this computer.
//
// Saved devices live in two places:
// - locally, as JSON in the local option [_kSavedKey] (works signed out and for IDs that were
//   never connected — RustDesk's own peer files are dropped until a session has happened);
// - online, in the user's personal address book on the API server, through [AbModel].
// Each local entry remembers which account it belongs to, so a list saved signed out is uploaded
// on the next sign-in, and a device removed on another computer is removed here too.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/ab_model.dart';
import 'package:flutter_hbb/models/peer_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:get/get.dart';

import '../screens/add_device_dialog.dart' show DrIdStatus;
import '../screens/home_view.dart' show DrDeviceItem;
import '../widgets.dart' show drFormatId;

const _kSavedKey = 'dr-saved-devices';
const _kDismissedKey = 'dr-save-prompt-dismissed';
const _kCbQueryOnlines = 'callback_query_onlines';

/// Name of the stock legacy address book (servers without the personal-book API).
const _kLegacyAbName = 'Legacy address book';

class DrSavedDevice {
  final String id;
  String name;
  String note;

  /// Account the entry is synced with; '' = saved while signed out, not uploaded yet.
  String user;
  DrSavedDevice(this.id, {this.name = '', this.note = '', this.user = ''});

  factory DrSavedDevice.fromJson(Map<String, dynamic> j) => DrSavedDevice(
      j['id'] ?? '',
      name: j['name'] ?? '',
      note: j['note'] ?? '',
      user: j['user'] ?? '');
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'note': note, 'user': user};
}

/// A session that just started to a device that isn't saved yet.
class DrSavePrompt {
  final String id;
  final String name;
  final String platform;
  const DrSavePrompt(this.id, this.name, this.platform);
}

class DrDevicesStore extends ChangeNotifier {
  DrDevicesStore._();
  static final DrDevicesStore instance = DrDevicesStore._();

  final Map<String, DrSavedDevice> _saved = {};
  final Set<String> _dismissed = {};
  final Map<String, bool> _online = {};
  final Map<String, Completer<bool>> _checks = {};
  List<DrDeviceItem> _items = const [];
  DrSavePrompt? _prompt;
  final List<StreamSubscription> _subs = [];
  bool _started = false;
  bool _syncing = false;

  List<DrDeviceItem> get items => _items;
  DrSavePrompt? get prompt => _prompt;
  bool get signedIn => gFFI.userModel.isLogin;
  String get userName => gFFI.userModel.userName.value;

  /// Starts listening to the stock models. Safe to call repeatedly.
  void start() {
    if (_started) return;
    _started = true;
    _loadLocal();
    gFFI.recentPeersModel.addListener(_rebuild);
    gFFI.favoritePeersModel.addListener(_rebuild);
    _subs.add(gFFI.userModel.userName.listen((_) => _onAccountChanged()));
    _subs.add(gFFI.abModel.addressbooks.listen((_) => _watchAb()));
    _watchAb();
    platformFFI.registerEventHandler(_kCbQueryOnlines, 'dr_devices',
        (evt) async => _onOnlines(evt));
    bind.mainLoadRecentPeers();
    bind.mainLoadFavPeers();
    Timer.periodic(const Duration(seconds: 10), (_) => _queryOnlines());
    Future.delayed(const Duration(seconds: 1), _queryOnlines);
    _rebuild();
  }

  // ---------------------------------------------------------------- sources

  BaseAb? get _myAb {
    final books = gFFI.abModel.addressbooks;
    return books[gFFI.abModel.personalAddressBookName()] ??
        books[_kLegacyAbName];
  }

  String? get _myAbName {
    final books = gFFI.abModel.addressbooks;
    final personal = gFFI.abModel.personalAddressBookName();
    if (books.containsKey(personal)) return personal;
    if (books.containsKey(_kLegacyAbName)) return _kLegacyAbName;
    return null;
  }

  StreamSubscription? _abPeersSub;
  BaseAb? _watchedAb;

  void _watchAb() {
    final ab = _myAb;
    if (identical(ab, _watchedAb)) return;
    _abPeersSub?.cancel();
    _watchedAb = ab;
    _abPeersSub = ab?.peers.listen((_) => _onAbChanged());
    _onAbChanged();
  }

  void _onAccountChanged() {
    _watchAb();
    _rebuild();
  }

  /// The address book was (re)loaded: mirror it locally and upload devices saved signed out.
  Future<void> _onAbChanged() async {
    final ab = _myAb;
    final user = userName;
    if (ab == null || !signedIn || user.isEmpty) {
      _rebuild();
      return;
    }
    // Only trust a book that loaded cleanly, so a network error never deletes local entries.
    if (!ab.initialized || ab.pullError.value.isNotEmpty || _syncing) {
      _rebuild();
      return;
    }
    final online = {for (final p in ab.peers) p.id: p};
    var changed = false;
    for (final p in online.values) {
      final local = _saved[p.id];
      if (local == null) {
        _saved[p.id] =
            DrSavedDevice(p.id, name: p.alias, note: p.note, user: user);
        changed = true;
      } else if (local.user == user &&
          (local.name != p.alias ||
              (p.note.isNotEmpty && local.note != p.note))) {
        // Our API server (rustdesk-api) doesn't store notes: an empty note from the server
        // never overwrites the one kept on this computer.
        local.name = p.alias;
        if (p.note.isNotEmpty) local.note = p.note;
        changed = true;
      }
    }
    // Removed in this account on another computer.
    _saved.removeWhere((id, d) {
      final gone = d.user == user && !online.containsKey(id);
      if (gone) changed = true;
      return gone;
    });
    final pending = _saved.values
        .where((d) => d.user.isEmpty || (d.user == user && !online.containsKey(d.id)))
        .toList();
    if (changed) _storeLocal();
    _rebuild();
    if (pending.isNotEmpty) {
      _syncing = true;
      try {
        for (final d in pending) {
          if (await _upload(d)) d.user = user;
        }
        _storeLocal();
      } finally {
        _syncing = false;
      }
      _rebuild();
    }
  }

  Future<bool> _upload(DrSavedDevice d) async {
    final name = _myAbName;
    if (name == null) return false;
    final err = await gFFI.abModel.addPeersTo([
      {'id': d.id, 'alias': d.name, 'note': d.note, 'tags': <dynamic>[]}
    ], name);
    if (err != null) debugPrint('dr devices: upload ${d.id} failed: $err');
    return err == null;
  }

  // ------------------------------------------------------------- list model

  void _rebuild() {
    final favIds = gFFI.favoritePeersModel.peers.map((p) => p.id).toSet();
    final abPeers = signedIn
        ? {for (final p in _myAb?.peers ?? <Peer>[]) p.id: p}
        : <String, Peer>{};
    final known = <String, Peer>{};
    for (final p in [
      ...gFFI.recentPeersModel.peers,
      ...gFFI.favoritePeersModel.peers
    ]) {
      if (p.id.isNotEmpty) known.putIfAbsent(p.id, () => p);
    }
    final user = userName;
    final visibleSaved = _saved.values
        .where((d) => !signedIn || d.user.isEmpty || d.user == user)
        .map((d) => d.id)
        .toSet();

    // Recent order first (most recent on top), then saved devices never connected from here.
    final order = <String>[
      ...known.keys,
      ...visibleSaved.where((id) => !known.containsKey(id)),
      ...abPeers.keys.where((id) => !known.containsKey(id) && !visibleSaved.contains(id)),
    ];
    final out = <DrDeviceItem>[];
    for (final id in order) {
      final peer = known[id] ?? abPeers[id];
      final saved = _saved[id];
      final isSaved = visibleSaved.contains(id) || abPeers.containsKey(id);
      final isFav = favIds.contains(id);
      final alias = (saved?.name.isNotEmpty ?? false)
          ? saved!.name
          : (abPeers[id]?.alias.isNotEmpty ?? false)
              ? abPeers[id]!.alias
              : '';
      out.add(DrDeviceItem(
        id: id,
        name: alias.isNotEmpty
            ? alias
            : peer != null
                ? drPeerName(peer)
                : drFormatId(id),
        online: _online[id] ?? peer?.online ?? false,
        platform: drPlatformLabel(peer?.platform ?? ''),
        lastSeen: isSaved
            ? 'Saved'
            : isFav
                ? 'Favourite'
                : 'Recent',
        saved: isSaved,
        favourite: isFav,
        recent: known.containsKey(id),
        note: saved?.note.isNotEmpty == true
            ? saved!.note
            : abPeers[id]?.note ?? '',
      ));
    }
    String sig(List<DrDeviceItem> l) => l
        .map((e) =>
            '${e.id}|${e.name}|${e.online}|${e.lastSeen}|${e.favourite}|${e.note}|${e.platform}')
        .join(';');
    final changed = sig(out) != sig(_items);
    _items = out;
    if (changed) notifyListeners();
  }

  // ----------------------------------------------------------- online state

  void _queryOnlines() {
    final ids = _items.map((e) => e.id).toList();
    if (ids.isNotEmpty) bind.queryOnlines(ids: ids);
  }

  void _onOnlines(Map<String, dynamic> evt) {
    void apply(String key, bool value) {
      for (final id in (evt[key] as String? ?? '').split(',')) {
        if (id.isEmpty) continue;
        _online[id] = value;
        _checks.remove(id)?.complete(value);
      }
    }

    apply('onlines', true);
    apply('offlines', false);
    _rebuild();
  }

  /// Asks the ID server whether [id] is online. The server can't tell an unknown ID from an
  /// offline one, so the UI words [DrIdStatus.offline] as "not reachable right now".
  Future<DrIdStatus> check(String rawId) async {
    final id = drNormalizeId(rawId);
    if (!drIsValidId(id)) return DrIdStatus.invalid;
    final c = _checks[id] ??= Completer<bool>();
    bind.queryOnlines(ids: [id]);
    try {
      final online = await c.future.timeout(const Duration(seconds: 6));
      return online ? DrIdStatus.online : DrIdStatus.offline;
    } on TimeoutException {
      _checks.remove(id);
      return DrIdStatus.offline;
    }
  }

  // ---------------------------------------------------------------- actions

  bool isSaved(String id) => _items.any((e) => e.id == id && e.saved);

  DrDeviceItem? find(String id) => _items.firstWhereOrNull((e) => e.id == id);

  /// Saves (or updates) a device on this computer and, when signed in, in the account.
  /// Returns an error message, or null on success.
  Future<String?> save(String rawId, {String name = '', String note = ''}) async {
    final id = drNormalizeId(rawId);
    if (!drIsValidId(id)) return 'Enter a valid device ID.';
    name = name.trim();
    note = note.trim();
    final d = _saved[id] ?? DrSavedDevice(id);
    d
      ..name = name
      ..note = note;
    _saved[id] = d;
    _dismissed.remove(id);
    if (_prompt?.id == id) _prompt = null;
    // Keep the name RustDesk shows in window titles in step, for devices with a session history.
    if (await bind.mainPeerExists(id: id)) {
      await bind.mainSetPeerAlias(id: id, alias: name);
    }
    _storeLocal();
    _rebuild();
    String? error;
    if (signedIn && _myAb != null) {
      _syncing = true;
      try {
        error = await _saveOnline(_myAb!, d, name, note);
      } finally {
        _syncing = false;
      }
      _storeLocal();
      _rebuild();
    }
    return error;
  }

  Future<String?> _saveOnline(
      BaseAb ab, DrSavedDevice d, String name, String note) async {
    final existing = ab.peers.firstWhereOrNull((p) => p.id == d.id);
    if (existing == null) {
      if (!await _upload(d)) {
        return 'Saved on this computer, but it could not be added to your account.';
      }
      d.user = userName;
      return null;
    }
    d.user = userName;
    var ok = true;
    if (existing.alias != name) {
      ok &= await ab.changeAlias(id: d.id, alias: name);
    }
    // Best effort: servers without note support keep the note on this computer only.
    if (existing.note != note && !gFFI.abModel.legacyMode.value) {
      await ab.changeNote(id: d.id, note: note);
    }
    await ab.pullAb(quiet: true);
    return ok ? null : 'Saved on this computer, but your account was not updated.';
  }

  /// Removes a device from "My devices" (this computer and the account). Recent history and
  /// favourites are left alone unless [alsoForget] is set.
  Future<void> remove(String id, {bool alsoForget = false}) async {
    _saved.remove(id);
    _storeLocal();
    final ab = _myAb;
    if (signedIn && ab != null && ab.peers.any((p) => p.id == id)) {
      await ab.deletePeers([id]);
      await ab.pullAb(quiet: true);
    }
    if (alsoForget) {
      final favs = (await bind.mainGetFav()).toList()..remove(id);
      await bind.mainStoreFav(favs: favs);
      await bind.mainRemovePeer(id: id);
      bind.mainLoadRecentPeers();
      bind.mainLoadFavPeers();
    }
    _rebuild();
  }

  Future<void> setFavourite(String id, bool favourite) async {
    final favs = (await bind.mainGetFav()).toList();
    favs.remove(id);
    if (favourite) favs.add(id);
    await bind.mainStoreFav(favs: favs);
    bind.mainLoadFavPeers();
  }

  // ---------------------------------------------------- save-after-connect

  /// A session window reported a successful login to [id].
  void onConnected(String id, {String hostname = '', String platform = ''}) {
    bind.mainLoadRecentPeers();
    if (id.isEmpty || isSaved(id) || _dismissed.contains(id)) return;
    final name = hostname.isNotEmpty ? hostname : drFormatId(id);
    _prompt = DrSavePrompt(id, name, drPlatformLabel(platform));
    notifyListeners();
  }

  void dismissPrompt({bool forever = true}) {
    final p = _prompt;
    if (p == null) return;
    if (forever) {
      _dismissed.add(p.id);
      bind.mainSetLocalOption(
          key: _kDismissedKey, value: jsonEncode(_dismissed.toList()));
    }
    _prompt = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------- storage

  void _loadLocal() {
    try {
      final raw = bind.mainGetLocalOption(key: _kSavedKey);
      if (raw.isNotEmpty) {
        for (final e in jsonDecode(raw) as List) {
          final d = DrSavedDevice.fromJson(Map<String, dynamic>.from(e));
          if (d.id.isNotEmpty) _saved[d.id] = d;
        }
      }
    } catch (e) {
      debugPrint('dr devices: bad $_kSavedKey: $e');
    }
    try {
      final raw = bind.mainGetLocalOption(key: _kDismissedKey);
      if (raw.isNotEmpty) _dismissed.addAll((jsonDecode(raw) as List).cast<String>());
    } catch (_) {}
  }

  void _storeLocal() {
    bind.mainSetLocalOption(
        key: _kSavedKey,
        value: jsonEncode(_saved.values.map((d) => d.toJson()).toList()));
  }
}

// ------------------------------------------------------------------ helpers

String drNormalizeId(String id) => id.replaceAll(RegExp(r'\s'), '');

/// RustDesk IDs are 6+ digits, or a custom ID (letter first, letters/digits/_-, 6–16 chars).
bool drIsValidId(String id) =>
    RegExp(r'^\d{6,}$').hasMatch(id) ||
    RegExp(r'^[A-Za-z][A-Za-z0-9_-]{5,15}$').hasMatch(id);

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

/// Hook for FfiModel's 'peer_info' event (a remote-desktop session logged in). Runs in the
/// session window; tells the main window so it can offer to save the device.
void drOnSessionPeerInfo(String peerId, Map<String, dynamic> evt) {
  if (!isDesktop) return;
  final payload = jsonEncode({
    'id': peerId,
    'hostname': evt['hostname'] ?? '',
    'platform': evt['platform'] ?? '',
  });
  if (isMainDesktopWindow) {
    drHandlePeerConnectedCall(payload);
  } else {
    rustDeskWinManager
        .call(WindowType.Main, kWindowDrPeerConnected, payload)
        .then((_) {}, onError: (e) => debugPrint('dr devices: notify main: $e'));
  }
}

/// Main-window side of [drOnSessionPeerInfo].
void drHandlePeerConnectedCall(dynamic args) {
  try {
    final m = jsonDecode(args as String) as Map<String, dynamic>;
    DrDevicesStore.instance.onConnected(m['id'] ?? '',
        hostname: m['hostname'] ?? '', platform: m['platform'] ?? '');
  } catch (e) {
    debugPrint('dr devices: bad peer-connected call: $e');
  }
}
