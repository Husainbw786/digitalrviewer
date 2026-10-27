// Settings sections: Your sessions, Recording, Your account, Advanced, App info.
part of '../../desktop/pages/desktop_setting_page.dart';

// ── Your sessions (defaults for connections you start) ─────────────────────

/// Our wording for the stock "other default options", grouped.
const Map<String, (String, String)> _kDrSessionDefaults = {
  // key: (group, label)
  kOptionViewOnly: ('Display', 'Start in view-only mode'),
  kKeyShowMonitorsToolbar: ('Display', 'Show the screen picker in the session bar'),
  kOptionCollapseToolbar: ('Display', 'Start with the session bar tucked away'),
  kOptionShowQualityMonitor: ('Display', 'Show connection stats'),
  kOptionI444: ('Display', 'Full colour (sharper text, uses more data)'),
  kKeyShowDisplaysAsIndividualWindows: ('Display', 'Open each of their screens in its own window'),
  kKeyUseAllMyDisplaysForTheRemoteSession: ('Display', 'Spread their screens across all of mine'),
  kOptionShowRemoteCursor: ('Mouse and keyboard', 'Show their mouse pointer'),
  kOptionFollowRemoteCursor: ('Mouse and keyboard', 'Follow their pointer around the screen'),
  kOptionFollowRemoteWindow: ('Mouse and keyboard', 'Follow the window they’re using'),
  kOptionZoomCursor: ('Mouse and keyboard', 'Scale the pointer with the picture'),
  kKeyReverseMouseWheel: ('Mouse and keyboard', 'Reverse scrolling direction'),
  kOptionSwapLeftRightMouse: ('Mouse and keyboard', 'Swap left and right mouse buttons'),
  kOptionDisableAudio: ('During a session', 'Start with their sound muted'),
  kOptionEnableFileCopyPaste: ('During a session', 'Copy and paste files'),
  kOptionDisableClipboard: ('During a session', 'Don’t share the clipboard'),
  kOptionLockAfterSessionEnd: ('During a session', 'Lock their computer when I disconnect'),
  kOptionPrivacyMode: ('During a session', 'Start with their screen blanked'),
  kOptionTerminalPersistent: ('Terminal', 'Keep terminal sessions running after I disconnect'),
  kOptionAllowTerminalClipboardWrite: ('Terminal', 'Let terminal apps copy to my clipboard'),
};

class _DrSessions extends StatefulWidget {
  const _DrSessions();
  @override
  State<_DrSessions> createState() => _DrSessionsState();
}

class _DrSessionsState extends State<_DrSessions> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _setDefault(String key, String value) async {
    await bind.mainSetUserDefaultOption(key: key, value: value);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Widget>>{};
    for (final e in otherDefaultSettings()) {
      final key = e.$2;
      final (group, label) = _kDrSessionDefaults[key] ?? ('More', translate(e.$1));
      final readOnly = isOtherDefaultSettingReadOnly(key);
      groups.putIfAbsent(group, () => []).add(DrToggleRow(
            title: label,
            value: getOtherDefaultSettingOption(key) == 'Y',
            badge: readOnly ? _kDrManaged : null,
            onChanged: readOnly
                ? null
                : (on) async {
                    await setOtherDefaultSettingOption(
                        key,
                        on
                            ? 'Y'
                            : (key == kOptionEnableFileCopyPaste ? 'N' : defaultOptionNo));
                    _refresh();
                  },
          ));
    }

    return _drPage('Your sessions',
        'How things start when you connect to another computer. You can still change them from the session bar.', [
      _drGroup('Picture', [
        _quality(),
        _size(),
        _scrolling(),
      ]),
      for (final g in ['Display', 'Mouse and keyboard'])
        if (groups[g] != null)
          _drGroup(g, [
            if (g == 'Mouse and keyboard' && isDesktop) _trackpad(),
            ...groups[g]!,
          ]),
      _drGroup('Windows and tabs', [
        if (!isWeb)
          const _DrOption('Open new connections as tabs', kOptionOpenNewConnInTabs,
              isServer: false),
        if (!isWeb)
          const _DrOption('Ask before closing several tabs', kOptionEnableConfirmClosingTabs,
              isServer: false),
        if (!isWeb)
          const _DrOption('Share one clipboard across all my sessions',
              kOptionAllowSyncClipboardBetweenSessions,
              isServer: false),
        if (!bind.isDisableAccount())
          _DrOption('Ask me for a note when a session ends',
              kOptionAllowAskForNoteAtEndOfConnection,
              isServer: false, setter: (key, value) async {
            if (value && !gFFI.userModel.isLogin) {
              final ok = await loginDialog();
              if (ok != true) return;
            }
            await mainSetLocalBoolOption(key, value);
          }),
      ]),
      for (final g in ['During a session', 'Terminal', 'More'])
        if (groups[g] != null) _drGroup(g, groups[g]!),
    ]);
  }

  Widget _quality() {
    final fixed = isOptionFixed(kOptionImageQuality);
    final v = bind.mainGetUserDefaultOption(key: kOptionImageQuality);
    return DrSettingRow(
      title: 'Picture quality',
      description: 'Balanced suits most connections. Fastest helps on slow networks.',
      badge: fixed ? _kDrManaged : null,
      trailing: DrChoicePills<String>(
        options: const [
          (kRemoteImageQualityBest, 'Sharpest'),
          (kRemoteImageQualityBalanced, 'Balanced'),
          (kRemoteImageQualityLow, 'Fastest'),
          (kRemoteImageQualityCustom, 'Custom'),
        ],
        value: v,
        onChanged: fixed ? null : (q) => _setDefault(kOptionImageQuality, q),
      ),
      below: v == kRemoteImageQualityCustom ? customImageQualitySetting() : null,
    );
  }

  Widget _size() {
    final fixed = isOptionFixed(kOptionViewStyle);
    return DrSettingRow(
      title: 'Their screen size',
      badge: fixed ? _kDrManaged : null,
      trailing: DrChoicePills<String>(
        options: const [
          (kRemoteViewStyleAdaptive, 'Fit my window'),
          (kRemoteViewStyleOriginal, 'Actual size'),
        ],
        value: bind.mainGetUserDefaultOption(key: kOptionViewStyle),
        onChanged: fixed ? null : (v) => _setDefault(kOptionViewStyle, v),
      ),
    );
  }

  Widget _scrolling() {
    final fixed = isOptionFixed(kOptionScrollStyle);
    final v = bind.mainGetUserDefaultOption(key: kOptionScrollStyle);
    return DrSettingRow(
      title: 'Moving around a large screen',
      badge: fixed ? _kDrManaged : null,
      trailing: DrChoicePills<String>(
        options: [
          (kRemoteScrollStyleAuto, 'Follow the mouse'),
          (kRemoteScrollStyleBar, 'Scroll bars'),
          if (!isWeb) (kRemoteScrollStyleEdge, 'Screen edges'),
        ],
        value: v,
        onChanged: fixed ? null : (s) => _setDefault(kOptionScrollStyle, s),
      ),
      below: v == kRemoteScrollStyleEdge && !isWeb
          ? EdgeThicknessControl(
              value: double.tryParse(bind.mainGetUserDefaultOption(
                      key: kOptionEdgeScrollEdgeThickness)) ??
                  100.0,
              onChanged: isOptionFixed(kOptionEdgeScrollEdgeThickness)
                  ? null
                  : (t) => _setDefault(kOptionEdgeScrollEdgeThickness, t.round().toString()),
            )
          : null,
    );
  }

  Widget _trackpad() {
    final initial =
        int.tryParse(bind.mainGetUserDefaultOption(key: kKeyTrackpadSpeed)) ?? kDefaultTrackpadSpeed;
    return DrSettingRow(
      title: 'Trackpad speed',
      below: TrackpadSpeedWidget(
        value: SimpleWrapper(initial),
        onDebouncer: (v) =>
            bind.mainSetUserDefaultOption(key: kKeyTrackpadSpeed, value: v.toString()),
      ),
    );
  }
}

// ── Recording ─────────────────────────────────────────────────────────────

class _DrRecording extends StatefulWidget {
  const _DrRecording();
  @override
  State<_DrRecording> createState() => _DrRecordingState();
}

class _DrRecordingState extends State<_DrRecording> {
  @override
  Widget build(BuildContext context) {
    final showRoot = isWindows && bind.mainIsInstalled();
    final userDir = bind.mainVideoSaveDirectory(root: false);
    final rootDir = showRoot ? bind.mainVideoSaveDirectory(root: true) : '';
    final fixed = isOptionFixed(kOptionVideoSaveDirectory);

    Widget folder(String title, String path, {bool canChange = false}) => DrSettingRow(
          title: title,
          description: path,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            DrButton('Open',
                kind: DrButtonKind.secondary,
                height: 36,
                fontSize: 13,
                onPressed: () async {
                  if (await Directory(path).exists()) launchUrl(Uri.file(path));
                }),
            if (canChange) ...[
              const SizedBox(width: 8),
              DrButton('Change…',
                  kind: DrButtonKind.secondary,
                  height: 36,
                  fontSize: 13,
                  onPressed: fixed
                      ? null
                      : () async {
                          final initial =
                              await Directory(path).exists() ? path : null;
                          final picked = await FilePicker.platform
                              .getDirectoryPath(initialDirectory: initial);
                          if (picked != null) {
                            await bind.mainSetLocalOption(
                                key: kOptionVideoSaveDirectory, value: picked);
                            if (mounted) setState(() {});
                          }
                        }),
            ],
          ]),
        );

    return _drPage('Recording', 'Save sessions as video files on this computer.', [
      _drGroup('Record automatically', [
        if (!bind.isOutgoingOnly())
          const _DrOption('When someone connects to me', kOptionAllowAutoRecordIncoming),
        if (!bind.isIncomingOnly())
          const _DrOption('When I connect to someone', kOptionAllowAutoRecordOutgoing,
              isServer: false),
      ]),
      _drGroup('Where recordings go', [
        if (showRoot && !bind.isOutgoingOnly())
          folder(bind.isIncomingOnly() ? 'Recordings' : 'Sessions others start', rootDir),
        if (!(showRoot && bind.isIncomingOnly()))
          folder(showRoot && !bind.isOutgoingOnly() ? 'Sessions I start' : 'Recordings', userDir,
              canChange: true),
      ]),
    ]);
  }
}

// ── Your account ──────────────────────────────────────────────────────────

class _DrAccount extends StatelessWidget {
  const _DrAccount();

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Obx(() {
      final user = gFFI.userModel.userName.value;
      if (user.isEmpty) {
        return _drPage('Your account', 'Sign in to keep your saved devices on every computer you use.', [
          _drGroup(null, [
            DrSettingRow(
              title: 'You’re not signed in',
              description:
                  'Devices you save stay on this computer only. Sign in to see them everywhere — with Google or the username your administrator gave you.',
              trailing: DrButton('Sign in', height: 40, onPressed: () => loginDialog()),
            ),
          ]),
        ]);
      }
      final name = gFFI.userModel.displayNameOrUserName;
      return _drPage('Your account', 'Your saved devices follow you to every computer where you sign in.', [
        _drGroup(null, [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              DrInitials(name, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: DrText.sans(16, c.text, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  SelectableText('@$user', style: DrText.sans(13, c.textMuted)),
                ]),
              ),
              DrButton('Sign out',
                  kind: DrButtonKind.secondary,
                  height: 38,
                  fontSize: 13,
                  onPressed: logOutConfirmDialog),
            ]),
          ),
        ]),
      ]);
    });
  }
}

// ── Advanced ──────────────────────────────────────────────────────────────

class _DrAdvanced extends StatefulWidget {
  final RxBool locked;
  const _DrAdvanced({required this.locked});
  @override
  State<_DrAdvanced> createState() => _DrAdvancedState();
}

class _DrAdvancedState extends State<_DrAdvanced> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final incomingOnly = bind.isIncomingOnly();
    final outgoingOnly = bind.isOutgoingOnly();
    return _drPage('Advanced',
        'Technical options. The defaults work well for almost everyone — only change these if you know you need to.', [
      DrCollapsibleGroup(
        title: 'Performance',
        subtitle: 'Video encoding and how the picture is drawn',
        children: _performance(incomingOnly, outgoingOnly),
      ),
      Obx(() => DrCollapsibleGroup(
            title: 'Connection',
            subtitle: 'Direct links, proxies and network fallbacks',
            initiallyOpen: false,
            children: _connection(incomingOnly, outgoingOnly, !widget.locked.value),
          )),
      DrCollapsibleGroup(
        title: 'Session window',
        subtitle: 'The bar and screen controls during a session',
        children: _sessionWindow(incomingOnly),
      ),
      if (isWindows) ..._windowsOnly(),
      if (isLinux) const WaylandCard(),
    ]);
  }

  List<Widget> _performance(bool incomingOnly, bool outgoingOnly) {
    final hw = !isWeb && (bind.mainHasHwcodec() || bind.mainHasVram());
    final codecFixed = isOptionFixed(kOptionCodecPreference);
    final codecs = <(String, String)>[
      ('auto', 'Automatic'),
      ('vp8', 'VP8'),
      ('vp9', 'VP9'),
      ('av1', 'AV1'),
    ];
    try {
      final m = jsonDecode(bind.mainSupportedHwdecodings()) as Map;
      if (m['h264'] == true) codecs.add(('h264', 'H.264'));
      if (m['h265'] == true) codecs.add(('h265', 'H.265'));
    } catch (_) {}
    return [
      if (hw)
        _DrOption('Use the graphics card for video', kOptionEnableHwcodec,
            description: 'Smoother and lighter on the processor when supported.',
            onChanged: (on) {
          if (on) bind.mainCheckHwcodec();
        }),
      if (!incomingOnly)
        DrSettingRow(
          title: 'Preferred video format',
          badge: codecFixed ? _kDrManaged : null,
          trailing: DrSelect<String>(
            width: 160,
            options: codecs,
            value: bind.mainGetUserDefaultOption(key: kOptionCodecPreference),
            onChanged: codecFixed
                ? null
                : (v) async {
                    await bind.mainSetUserDefaultOption(key: kOptionCodecPreference, value: v);
                    _refresh();
                  },
          ),
        ),
      if (!isWeb && !outgoingOnly)
        const _DrOption('Adjust quality to the connection speed', kOptionEnableAbr),
      if (!isWeb && !incomingOnly)
        _DrOption('Draw the picture with textures', kOptionTextureRender,
            description: translate('texture_render_tip'),
            getter: bind.mainGetUseTextureRender,
            setter: (k, v) => bind.mainSetLocalOption(key: k, value: v ? 'Y' : 'N')),
      if (isWindows && !incomingOnly)
        const _DrOption('Draw the picture with Direct3D', kOptionD3DRender, isServer: false),
      if (isLinux && !incomingOnly)
        const _DrOption('Draw without the graphics card', kOptionAllowAlwaysSoftwareRender),
      if (isWindows && !outgoingOnly)
        const _DrOption('Capture my screen with DirectX', kOptionDirectxCapture),
      if (!isWeb && !outgoingOnly)
        futureBuilder(
          future: bind.mainSupportRemoveWallpaper(),
          hasData: (supported) => supported == true
              ? _DrOption('Hide my wallpaper during sessions', kOptionAllowRemoveWallpaper,
                  description: 'A plain background makes the picture faster.',
                  onChanged: (_) => _refresh(),
                  extra: mainGetBoolOptionSync(kOptionAllowRemoveWallpaper)
                      ? DrButton('Try it',
                          kind: DrButtonKind.secondary,
                          height: 34,
                          fontSize: 12.5,
                          onPressed: () => bind.mainTestWallpaper(second: 5))
                      : null)
              : const SizedBox.shrink(),
        ),
    ];
  }

  List<Widget> _connection(bool incomingOnly, bool outgoingOnly, bool unlocked) {
    final directOn = option2bool(
        kOptionDirectServer, bind.mainGetOptionSync(key: kOptionDirectServer));
    final webrtcOn = mainGetLocalBoolOptionSync(kOptionEnableWebrtc);
    final hideProxy = isWeb || bind.mainGetBuildinOption(key: kOptionHideProxySetting) == 'Y';
    final hideWs = isWeb || bind.mainGetBuildinOption(key: kOptionHideWebSocketSetting) == 'Y';
    return [
      if (!unlocked)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _drUnlockBanner(widget.locked, 'Some connection options'),
        ),
      if (!isWeb && !incomingOnly) ...[
        const _DrOption('Try a direct link over TCP', kOptionEnableTcpPunch, isServer: false),
        const _DrOption('Try a direct link over UDP', kOptionEnableUdpPunch, isServer: false),
        const _DrOption('Try a direct link over IPv6', kOptionEnableIpv6Punch, isServer: false),
      ],
      if (!incomingOnly) ...[
        _DrOption('Try a direct link with WebRTC', kOptionEnableWebrtc,
            isServer: false, onChanged: (_) => _refresh()),
        if (webrtcOn)
          DrSubRows(children: [
            DrSettingRow(
              title: 'Wait before using the relay',
              description: translate('relay-fallback-delay-tip'),
              trailing: DrInputApply(
                value: bind.mainGetLocalOption(key: kOptionRelayFallbackDelay),
                hint: '2.5',
                suffix: 'seconds',
                enabled: !isOptionFixed(kOptionRelayFallbackDelay),
                allowPattern: r'^([0-9]|[1-9][0-9])?(\.[0-9]?)?$',
                onApply: (v) => bind.mainSetLocalOption(key: kOptionRelayFallbackDelay, value: v),
              ),
            ),
          ]),
        if (!isWeb)
          const _DrOption('Reuse one link for all port forwards', kOptionEnablePortForwardMux,
              isServer: false),
      ],
      if (!outgoingOnly) ...[
        _DrOption('Allow connections straight to my IP address', kOptionDirectServer,
            description: 'For use inside a trusted network without the relay.',
            enabled: unlocked,
            onChanged: (_) => _refresh()),
        if (directOn)
          DrSubRows(children: [
            DrSettingRow(
              title: 'Port',
              trailing: DrInputApply(
                value: bind.mainGetOptionSync(key: kOptionDirectAccessPort),
                hint: '21118',
                enabled: unlocked && !isOptionFixed(kOptionDirectAccessPort),
                allowPattern: r'^\d{0,5}$',
                onApply: (v) => bind.mainSetOption(key: kOptionDirectAccessPort, value: v),
              ),
            ),
          ]),
      ],
      if (!hideProxy)
        DrSettingRow(
          title: 'Proxy server',
          description: 'Send connections through a SOCKS5 or HTTP proxy.',
          trailing: DrButton('Set up…',
              kind: DrButtonKind.secondary,
              height: 36,
              fontSize: 13,
              onPressed: unlocked ? changeSocks5Proxy : null),
        ),
      if (!hideWs)
        _DrOption('Connect over WebSocket', kOptionAllowWebSocket,
            description: 'Helps on networks that block other traffic.', enabled: unlocked),
      if (!isWeb)
        futureBuilder(
          future: bind.mainIsUsingPublicServer(),
          hasData: (public) => public == true
              ? const SizedBox.shrink()
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _DrOption('Accept older secure connections', kOptionAllowInsecureTLSFallback,
                      description: translate('allow-insecure-tls-fallback-tip'),
                      enabled: unlocked),
                  if (!outgoingOnly)
                    _DrOption('Don’t use UDP', kOptionDisableUdp,
                        enabled: unlocked,
                        getter: () => bind.mainGetOptionSync(key: kOptionDisableUdp) == 'Y',
                        setter: (k, v) => bind.mainSetOption(key: k, value: v ? 'Y' : 'N')),
                ]),
        ),
    ];
  }

  List<Widget> _sessionWindow(bool incomingOnly) {
    final showOnMain = mainGetLocalBoolOptionSync(kOptionAllowMonitorSwitchMainToolbar);
    List<dynamic> impls = const [];
    try {
      impls = jsonDecode(bind.mainSupportedPrivacyModeImpls()) as List<dynamic>;
    } catch (_) {}
    var impl = bind.mainGetOptionSync(key: 'privacy-mode-impl-key');
    if (impl.isEmpty) impl = bind.mainDefaultPrivacyModeImpl();
    return [
      if (!incomingOnly)
        _DrOption('Let me dock the session bar on any edge', kOptionAllowMultiEdgeToolbarDock,
            isServer: false, onChanged: (_) => reloadAllWindows()),
      _DrOption('Screen switch buttons in the session bar', kOptionAllowMonitorSwitchMainToolbar,
          isServer: false, onChanged: (on) async {
        if (!on) await mainSetLocalBoolOption(kOptionAllowMonitorSwitchMinToolbar, false);
        _refresh();
        reloadAllWindows();
      }),
      if (showOnMain)
        DrSubRows(children: [
          _DrOption('Also when the bar is tucked away', kOptionAllowMonitorSwitchMinToolbar,
              isServer: false, onChanged: (_) => reloadAllWindows()),
        ]),
      if (!isWeb && impls.length >= 2)
        DrSettingRow(
          title: 'Privacy screen method',
          trailing: DrSelect<String>(
            width: 240,
            options: [for (final d in impls) ((d as List)[0] as String, d[1] as String)],
            value: impl,
            onChanged: (v) async {
              await bind.mainSetOption(key: 'privacy-mode-impl-key', value: v);
              _refresh();
            },
          ),
        ),
    ];
  }

  List<Widget> _windowsOnly() {
    final installed = bind.mainIsInstalled();
    final printer = PrinterOptions.load();
    return [
      DrCollapsibleGroup(
        title: 'Windows',
        subtitle: 'Printing and Remote Desktop sharing',
        children: [
          if (installed)
            DrToggleRow(
              title: 'Share with Windows Remote Desktop sessions',
              value: bind.mainIsShareRdp(),
              onChanged: (on) async {
                await bind.mainSetShareRdp(enable: on);
                _refresh();
              },
            ),
          DrSettingRow(
            title: 'When they print to my printer',
            trailing: DrSelect<String>(
              width: 230,
              options: const [
                (kValuePrinterIncomingJobDismiss, 'Ignore the print job'),
                (kValuePrinterIncomingJobDefault, 'Use my default printer'),
                (kValuePrinterIncomingJobSelected, 'Use a printer I choose'),
              ],
              value: printer.action,
              onChanged: (v) async {
                await bind.mainSetLocalOption(key: kKeyPrinterIncomingJobAction, value: v);
                _refresh();
              },
            ),
          ),
          if (printer.action == kValuePrinterIncomingJobSelected && printer.printerNames.isNotEmpty)
            DrSubRows(children: [
              DrSettingRow(
                title: 'Printer',
                trailing: DrSelect<String>(
                  width: 230,
                  options: [for (final n in printer.printerNames) (n, n)],
                  value: printer.printerName,
                  onChanged: (v) async {
                    await bind.mainSetLocalOption(key: kKeyPrinterSelected, value: v);
                    _refresh();
                  },
                ),
              ),
            ]),
          _DrOption('Print without asking', kKeyPrinterAllowAutoPrint,
              isServer: false, enabled: printer.action != kValuePrinterIncomingJobDismiss),
          if (installed &&
              bind.mainGetCommonSync(key: 'is-support-printer-driver') == 'true' &&
              bind.mainGetCommonSync(key: 'is-printer-installed') != 'true')
            DrSettingRow(
              title: 'Print from their computer to mine',
              description: 'Installs the Digital R Viewer printer on this computer.',
              trailing: DrButton('Install printer',
                  kind: DrButtonKind.secondary,
                  height: 36,
                  fontSize: 13,
                  onPressed: () => bind.mainSetCommon(key: 'install-printer', value: '')),
            ),
        ],
      ),
    ];
  }
}

// ── App info ──────────────────────────────────────────────────────────────

class _DrAbout extends StatelessWidget {
  const _DrAbout();

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return futureBuilder(
      future: (() async => <String, String>{
            'engine': await bind.mainGetVersion(),
            'built': await bind.mainGetBuildDate(),
            'fingerprint': isWeb ? '' : await bind.mainGetFingerprint(),
            'id': await bind.mainGetMyId(),
          })(),
      hasData: (d) {
        final m = d as Map<String, String>;
        Widget info(String label, String value) => DrSettingRow(
              title: label,
              trailing: SelectableText(value, style: DrText.sans(13.5, c.textMuted, tabular: true)),
            );
        return _drPage('App info', 'Version details, updates and licences.', [
          _drGroup(null, [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(children: [
                const DrLogoMark(size: 44),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(kDrDisplayName, style: DrText.serif(26, c.text)),
                    Text('Version $kDrVersion', style: DrText.sans(13, c.textMuted)),
                  ]),
                ),
                DrButton('Check for updates',
                    kind: DrButtonKind.secondary,
                    height: 38,
                    fontSize: 13,
                    onPressed: () async {
                      await DrUpdater.instance.check();
                      final s = DrUpdater.instance.stage.value;
                      showToast(s == DrUpdateStage.idle
                          ? 'You’re on the latest version'
                          : 'An update is ready — use the button at the top');
                    }),
              ]),
            ),
            info('Your ID', drFormatId(m['id'] ?? '')),
            if ((m['fingerprint'] ?? '').isNotEmpty) info('Security fingerprint', m['fingerprint']!),
            info('Engine', '${m['engine']} · built ${m['built']}'),
          ]),
          _drGroup('More', [
            DrSettingRow(
              title: 'Website',
              trailing: DrLink('digitalrviewer.com',
                  onTap: () => launchUrlString('https://digitalrviewer.com')),
            ),
            DrSettingRow(
              title: 'Privacy policy',
              trailing: DrLink('Read it',
                  onTap: () => launchUrlString('https://digitalrviewer.com/privacy/')),
            ),
            DrSettingRow(
              title: 'Licences',
              description:
                  '$kDrDisplayName is built on RustDesk and is free software under the GNU Affero General Public License v3. The source code is published on GitHub.',
              trailing: DrLink('Source code',
                  onTap: () => launchUrlString('https://github.com/Husainbw786/digitalrviewer')),
            ),
          ]),
        ]);
      },
    );
  }
}
