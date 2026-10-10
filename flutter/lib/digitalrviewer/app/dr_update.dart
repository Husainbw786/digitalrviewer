// In-app updater: check digitalrviewer.com for a newer release, download it with progress,
// then "Restart to update". Download and install reuse RustDesk's own machinery
// (downloader + platform::update_to / extract_update_dmg), driven through mainSetCommon.
import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Abi;

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../theme.dart';
import '../widgets.dart';
import 'dr_version.dart';

const String kDrUpdateFeed = 'https://digitalrviewer.com/download/latest.json';
const String kDrReleaseBase =
    'https://github.com/Husainbw786/digitalrviewer/releases/download';
const Duration _kFirstCheck = Duration(seconds: 8);
const Duration _kCheckEvery = Duration(hours: 4);
const String _kHandler = 'dr-updater';

enum DrUpdateStage { idle, available, downloading, preparing, ready, failed }

/// Compares dotted version strings numerically ("1.5.0.10" > "1.5.0.9").
int drCompareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split(RegExp(r'[^0-9]+'))
      .where((s) => s.isNotEmpty)
      .map(int.parse)
      .toList();
  final x = parts(a), y = parts(b);
  for (var i = 0; i < (x.length > y.length ? x.length : y.length); i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d.sign;
  }
  return 0;
}

class DrUpdater {
  DrUpdater._();
  static final DrUpdater instance = DrUpdater._();

  final stage = DrUpdateStage.idle.obs;
  final progress = 0.0.obs; // 0..1 while downloading
  final latestVersion = ''.obs;
  String error = '';
  String _url = '';
  String _downloadId = '';
  Timer? _checkTimer;
  Timer? _pollTimer;
  bool _started = false;

  /// Starts periodic checks (main window only, macOS and Windows only).
  void start() {
    if (_started || !(isMacOS || isWindows)) return;
    _started = true;
    Future.delayed(_kFirstCheck, check);
    _checkTimer = Timer.periodic(_kCheckEvery, (_) => check());
  }

  void dispose() {
    _checkTimer?.cancel();
    _pollTimer?.cancel();
  }

  /// Picks this machine's installer from the feed.
  Map<String, dynamic>? _pickFile(List files) {
    final mac = isMacOS;
    final arch = Abi.current() == Abi.macosArm64 ? 'aarch64' : 'x86_64';
    for (final f in files.cast<Map<String, dynamic>>()) {
      final name = (f['name'] ?? '') as String;
      if (mac && name.endsWith('.dmg') && f['arch'] == arch) return f;
      // Custom clients update with the self-extracting exe (RustDesk does the same).
      if (!mac && name.endsWith('.exe')) return f;
    }
    return null;
  }

  Future<void> check() async {
    if (stage.value == DrUpdateStage.downloading ||
        stage.value == DrUpdateStage.preparing ||
        stage.value == DrUpdateStage.ready) {
      return;
    }
    try {
      final res = await http
          .get(Uri.parse(kDrUpdateFeed), headers: {'Cache-Control': 'no-cache'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;
      final feed = jsonDecode(res.body) as Map<String, dynamic>;
      final file = _pickFile((feed['files'] ?? []) as List);
      if (file == null) return;
      final version = (file['version'] ?? feed['version'] ?? '') as String;
      final tag = (file['tag'] ?? feed['tag'] ?? '') as String;
      if (version.isEmpty || tag.isEmpty) return;
      if (drCompareVersions(version, kDrVersion) <= 0) {
        if (stage.value == DrUpdateStage.available) {
          stage.value = DrUpdateStage.idle;
        }
        return;
      }
      _url = '$kDrReleaseBase/$tag/${Uri.encodeComponent(file['name'] as String)}';
      latestVersion.value = version;
      stage.value = DrUpdateStage.available;
    } catch (e) {
      debugPrint('DigitalRViewer update check failed: $e');
    }
  }

  void download() {
    if (_url.isEmpty) return;
    progress.value = 0;
    error = '';
    stage.value = DrUpdateStage.downloading;
    platformFFI.registerEventHandler('download-new-version', _kHandler,
        (evt) async {
      if (evt['id'] != null) {
        _downloadId = evt['id'] as String;
        _pollTimer?.cancel();
        _pollTimer =
            Timer.periodic(const Duration(milliseconds: 400), (_) => _poll());
      } else {
        _fail((evt['error'] ?? 'Download failed') as String);
      }
    }, replace: true);
    if (isMacOS) {
      platformFFI.registerEventHandler('extract-update-dmg', _kHandler,
          (evt) async {
        final err = (evt['err'] ?? '') as String;
        if (err.isNotEmpty) {
          _fail(err);
        } else {
          stage.value = DrUpdateStage.ready;
        }
      }, replace: true);
    }
    bind.mainSetCommon(key: 'download-new-version', value: _url);
  }

  void _poll() {
    final raw = bind.mainGetCommonSync(key: 'download-data-$_downloadId');
    if (raw.startsWith('error:')) return _fail(raw.substring(6));
    try {
      final d = jsonDecode(raw) as Map<String, dynamic>;
      if (d['error'] != null) return _fail(d['error'].toString());
      final total = d['total_size'] as int?;
      final done = (d['downloaded_size'] ?? 0) as int;
      if (total != null && total > 0) progress.value = done / total;
      if (total != null && done >= total) {
        _pollTimer?.cancel();
        bind.mainSetCommon(key: 'remove-downloader', value: _downloadId);
        if (total == 0) return _fail('The downloaded file is empty.');
        if (isMacOS) {
          stage.value = DrUpdateStage.preparing;
          bind.mainSetCommon(key: 'extract-update-dmg', value: _url);
        } else {
          stage.value = DrUpdateStage.ready;
        }
      }
    } catch (_) {
      // transient: the downloader may not have reported yet
    }
  }

  void _fail(String message) {
    _pollTimer?.cancel();
    error = message;
    stage.value = DrUpdateStage.failed;
    debugPrint('DigitalRViewer update failed: $message');
  }

  void cancel() {
    _pollTimer?.cancel();
    if (_downloadId.isNotEmpty) {
      bind.mainSetCommon(key: 'cancel-downloader', value: _downloadId);
    }
    stage.value = DrUpdateStage.available;
  }

  /// Installs the downloaded update. The installer closes this app and starts the new one;
  /// macOS asks for an administrator password, Windows shows a UAC prompt.
  void restartToUpdate() {
    if (stage.value != DrUpdateStage.ready) return;
    bind.mainSetCommon(key: 'update-me', value: _url);
  }
}

/// Top-bar pill: "Update" → "Downloading 42%" → "Restart to update".
class DrUpdatePill extends StatelessWidget {
  const DrUpdatePill({super.key});

  @override
  Widget build(BuildContext context) {
    final u = DrUpdater.instance;
    return Obx(() {
      final c = DrColors.of(context);
      final v = u.latestVersion.value;
      switch (u.stage.value) {
        case DrUpdateStage.idle:
          return const SizedBox.shrink();
        case DrUpdateStage.available:
          return Tooltip(
            message: 'Version $v is available',
            child: DrButton('Update',
                kind: DrButtonKind.ghostOnAccent,
                height: 36,
                fontSize: 13,
                icon: const Icon(Icons.arrow_downward_rounded),
                onPressed: u.download),
          );
        case DrUpdateStage.downloading:
          final pct = (u.progress.value * 100).clamp(0, 100).round();
          return Tooltip(
            message: 'Click to cancel',
            child: GestureDetector(
              onTap: u.cancel,
              child: _ProgressPill(
                  label: 'Downloading $pct%', value: u.progress.value),
            ),
          );
        case DrUpdateStage.preparing:
          return const _ProgressPill(label: 'Preparing…', value: null);
        case DrUpdateStage.ready:
          return Tooltip(
            message: 'Install version $v and restart',
            child: DrButton('Restart to update',
                height: 36,
                fontSize: 13,
                onPressed: () => _confirmRestart(context)),
          );
        case DrUpdateStage.failed:
          return Tooltip(
            message: u.error.isEmpty ? 'Update failed' : u.error,
            child: DrButton('Update failed · Retry',
                kind: DrButtonKind.secondary,
                height: 36,
                fontSize: 13,
                icon: Icon(Icons.refresh, color: c.danger),
                onPressed: u.download),
          );
      }
    });
  }

  void _confirmRestart(BuildContext context) {
    final busy = gFFI.serverModel.clients.any((cl) => !cl.disconnected);
    if (!busy) return DrUpdater.instance.restartToUpdate();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restart now?'),
        content: const Text(
            'Someone is connected to this computer. Restarting ends their session.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later')),
          ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                DrUpdater.instance.restartToUpdate();
              },
              child: const Text('Restart')),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final String label;
  final double? value;
  const _ProgressPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Container(
      height: 36,
      width: 168,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: c.accent, borderRadius: BorderRadius.circular(DrRadius.pill)),
      child: Row(children: [
        Text(label,
            style: DrText.sans(13, c.accentText, weight: FontWeight.w600)),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: c.surface,
              valueColor: AlwaysStoppedAnimation(c.link),
            ),
          ),
        ),
      ]),
    );
  }
}
