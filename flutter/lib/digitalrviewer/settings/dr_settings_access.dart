// Settings sections: Basics and Remote access (what happens when someone connects to you).
part of '../../desktop/pages/desktop_setting_page.dart';

// ── Basics ────────────────────────────────────────────────────────────────

class _DrBasics extends StatefulWidget {
  const _DrBasics();
  @override
  State<_DrBasics> createState() => _DrBasicsState();
}

class _DrBasicsState extends State<_DrBasics> {
  final RxBool _serviceStopped =
      isWeb ? RxBool(false) : Get.find<RxBool>(tag: 'stop-service');
  final RxBool _serviceBusy = false.obs;

  @override
  Widget build(BuildContext context) {
    return _drPage('Basics', 'How the app looks, which language it speaks, and when it runs.', [
      _drGroup('Look and language', [
        _theme(),
        if (!isWeb) _language(),
      ]),
      if (!isWeb && !bind.isOutgoingOnly()) _service(),
      _drGroup('Stay awake', [
        if (!bind.isOutgoingOnly())
          const _DrOption('While someone is connected to this computer',
              kOptionKeepAwakeDuringIncomingSessions,
              description: 'Stops this computer going to sleep in the middle of a session.'),
        if (!bind.isIncomingOnly())
          const _DrOption('While I’m connected to another computer',
              kOptionKeepAwakeDuringOutgoingSessions,
              isServer: false),
      ]),
    ]);
  }

  Widget _theme() {
    final current = MyTheme.getThemeModePreference().toShortString();
    final fixed = isOptionFixed(kCommConfKeyTheme);
    return DrSettingRow(
      title: 'Appearance',
      badge: fixed ? _kDrManaged : null,
      trailing: DrChoicePills<String>(
        options: const [('light', 'Light'), ('dark', 'Dark'), ('system', 'Match system')],
        value: current,
        onChanged: fixed
            ? null
            : (v) async {
                await MyTheme.changeDarkMode(MyTheme.themeModeFromString(v));
                if (mounted) setState(() {});
              },
      ),
    );
  }

  Widget _language() {
    return futureBuilder(
      future: bind.mainGetLangs(),
      hasData: (raw) {
        final list = jsonDecode(raw as String) as List<dynamic>;
        final options = <(String, String)>[
          (defaultOptionLang, 'Same as my computer'),
          for (final v in list) (v[0] as String, v[1] as String),
        ];
        var current = bind.mainGetLocalOption(key: kCommConfKeyLang);
        if (!options.any((o) => o.$1 == current)) current = defaultOptionLang;
        final fixed = isOptionFixed(kCommConfKeyLang);
        return DrSettingRow(
          title: 'Language',
          badge: fixed ? _kDrManaged : null,
          trailing: DrSelect<String>(
            options: options,
            value: current,
            onChanged: fixed
                ? null
                : (key) async {
                    await bind.mainSetLocalOption(key: kCommConfKeyLang, value: key);
                    reloadAllWindows();
                    bind.mainChangeLanguage(lang: key);
                  },
          ),
        );
      },
    );
  }

  Widget _service() {
    final hideStop = bind.mainGetBuildinOption(key: kOptionHideStopService) == 'Y';
    return Obx(() {
      final stopped = _serviceStopped.value;
      if (hideStop && !stopped) return const SizedBox.shrink();
      return _drGroup('Availability', [
        DrSettingRow(
          title: stopped ? 'Remote access is paused' : 'Remote access is on',
          description: stopped
              ? 'Nobody can connect to this computer until you turn it back on.'
              : 'Other people can connect to this computer with your ID and password.',
          trailing: DrButton(stopped ? 'Turn on' : 'Pause',
              kind: stopped ? DrButtonKind.primary : DrButtonKind.secondary,
              height: 38,
              fontSize: 13,
              onPressed: _serviceBusy.value
                  ? null
                  : () async {
                      _serviceBusy.value = true;
                      await start_service(stopped);
                      Future.delayed(const Duration(seconds: 1),
                          () => _serviceBusy.value = false);
                    }),
        ),
      ]);
    });
  }
}

// ── Remote access ─────────────────────────────────────────────────────────

class _DrRemoteAccess extends StatefulWidget {
  final RxBool locked;
  const _DrRemoteAccess({required this.locked});
  @override
  State<_DrRemoteAccess> createState() => _DrRemoteAccessState();
}

class _DrRemoteAccessState extends State<_DrRemoteAccess> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final enabled = !widget.locked.value;
      return _drPage(
          'Remote access',
          'Decide how people get into this computer and what they’re allowed to do once they’re in.',
          [
            _drUnlockBanner(widget.locked, 'Remote access'),
            ChangeNotifierProvider.value(
              value: gFFI.serverModel,
              child: Consumer<ServerModel>(
                  builder: (context, model, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _howIn(model, enabled),
                          if (model.approveMode != 'click') _passwords(model, enabled),
                        ],
                      )),
            ),
            _permissions(enabled),
            if (!bind.isOutgoingOnly()) _sound(),
            _protection(enabled),
            _whoMayConnect(enabled),
            if (!isChangeIdDisabled()) _yourId(enabled),
          ]);
    });
  }

  Widget _howIn(ServerModel model, bool enabled) {
    final keys = ['password', 'click', defaultOptionApproveMode];
    var current = model.approveMode;
    if (!keys.contains(current)) current = defaultOptionApproveMode;
    final fixed = isOptionFixed(kOptionApproveMode);
    return _drGroup('How people get in', [
      if (fixed) DrSettingRow(title: 'Chosen for you', badge: _kDrManaged),
      DrRadioCards<String>(
        options: [
          const DrRadioOption('click', 'Ask me every time',
              'A request pops up and you choose Allow or Decline.'),
          const DrRadioOption('password', 'Password only',
              'Anyone with the right password gets in without asking.'),
          DrRadioOption(defaultOptionApproveMode, 'Either way',
              'A password lets them straight in; without one, you’re asked.'),
        ],
        selected: current,
        onSelect: enabled && !fixed ? (v) => model.setApproveMode(v) : null,
      ),
    ]);
  }

  Widget _passwords(ServerModel model, bool enabled) {
    final method = model.verificationMethod;
    final oneTimeOn = method != kUsePermanentPassword;
    final permanentOn = method != kUseTemporaryPassword;
    Future<void> setMethod(String key) async {
      Future<void> apply() async {
        await model.setVerificationMethod(key);
        await model.updatePasswordModel();
      }

      if (key == kUsePermanentPassword &&
          (await bind.mainGetCommon(key: 'permanent-password-set')) != 'true' &&
          !isChangePermanentPasswordDisabled()) {
        setPasswordDialog(notEmptyCallback: apply);
      } else {
        await apply();
      }
    }

    final numFixed = isOptionFixed(kOptionAllowNumericOneTimePassword);
    return _drGroup('Passwords', [
      DrRadioCards<String>(
        options: const [
          DrRadioOption(kUseTemporaryPassword, 'Fresh password',
              'A new password you read out each time.'),
          DrRadioOption(kUsePermanentPassword, 'Fixed password',
              'One password you choose, for your own devices.'),
          DrRadioOption(kUseBothPasswords, 'Both',
              'Either password works.'),
        ],
        selected: method,
        onSelect: enabled ? setMethod : null,
      ),
      DrSettingRow(
        title: 'Fresh password length',
        enabled: enabled && oneTimeOn,
        trailing: DrChoicePills<String>(
          options: const [('6', '6'), ('8', '8'), ('10', '10')],
          value: model.temporaryPasswordLength,
          onChanged: enabled && oneTimeOn
              ? (v) async {
                  await model.setTemporaryPasswordLength(v);
                  await model.updatePasswordModel();
                }
              : null,
        ),
      ),
      DrToggleRow(
        title: 'Numbers only',
        description: 'Easier to read out over the phone.',
        value: model.allowNumericOneTimePassword,
        badge: numFixed ? _kDrManaged : null,
        onChanged: enabled && oneTimeOn && !numFixed
            ? (_) => model.switchAllowNumericOneTimePassword()
            : null,
      ),
      if (!isChangePermanentPasswordDisabled())
        DrSettingRow(
          title: 'Fixed password',
          description: 'Set or change the password for unattended access.',
          enabled: enabled && permanentOn,
          trailing: DrButton('Set password…',
              kind: DrButtonKind.secondary,
              height: 38,
              fontSize: 13,
              onPressed: enabled && permanentOn ? () => setPasswordDialog() : null),
        ),
    ]);
  }

  Widget _permissions(bool enabled) {
    final raw = bind.mainGetOptionSync(key: kOptionAccessMode);
    final preset = raw == 'full' || raw == 'view' ? raw : defaultOptionAccessMode;
    final bool? fake = preset == 'full' ? true : (preset == 'view' ? false : null);
    final presetFixed = isOptionFixed(kOptionAccessMode);
    Widget perm(String title, String key, {String? description}) => _DrOption(
        title, key,
        description: description, enabled: enabled, fakeValue: fake);
    return _drGroup('What they can do', [
      DrSettingRow(
        title: 'Access level',
        description: preset == defaultOptionAccessMode
            ? 'Choose each permission below.'
            : (preset == 'full'
                ? 'Everything below is allowed.'
                : 'They can only watch your screen.'),
        badge: presetFixed ? _kDrManaged : null,
        trailing: DrChoicePills<String>(
          options: [
            ('full', 'Full control'),
            ('view', 'View only'),
            (defaultOptionAccessMode, 'Choose…'),
          ],
          value: preset,
          onChanged: enabled && !presetFixed
              ? (v) async {
                  await bind.mainSetOption(key: kOptionAccessMode, value: v);
                  _refresh();
                }
              : null,
        ),
      ),
      perm('Use my mouse and keyboard', kOptionEnableKeyboard),
      perm('Copy and paste between computers', kOptionEnableClipboard),
      perm('Send and receive files', kOptionEnableFileTransfer),
      perm('Hear sound from this computer', kOptionEnableAudio),
      perm('Use my camera', kOptionEnableCamera),
      perm('Open a command terminal', kOptionEnableTerminal),
      perm('Create network tunnels', kOptionEnableTunnel),
      perm('Restart this computer', kOptionEnableRemoteRestart),
      perm('Record the session', kOptionEnableRecordSession),
      if (isWindows) perm('Print to my printer', kOptionEnableRemotePrinter),
      if (isWindows) perm('Block my mouse and keyboard', kOptionEnableBlockInput),
      if (bind.mainSupportedPrivacyModeImpls() != '[]')
        perm('Turn on the privacy screen', kOptionEnablePrivacyMode,
            description: 'Blanks my screen while they work.'),
      perm('Change my settings', kOptionAllowRemoteConfigModification),
    ]);
  }

  Widget _sound() => AudioInput(
        isCm: false,
        isVoiceCall: false,
        builder: (devices, current, setDevice) => _drGroup('Sound', [
          DrSettingRow(
            title: 'Sound sent to the other side',
            description: 'Which microphone or audio source people hear during a session.',
            trailing: DrSelect<String>(
              width: 260,
              options: [for (final d in devices) (d, d)],
              value: current,
              onChanged: (d) {
                setDevice(d);
                _refresh();
              },
            ),
          ),
        ]),
      );

  Widget _protection(bool enabled) {
    final has2fa = bind.mainHasValid2FaSync();
    final hasBot = bind.mainHasValidBotSync();
    final pin = bind.mainGetUnlockPin();
    final autoEnd = option2bool(kOptionAllowAutoDisconnect,
        bind.mainGetOptionSync(key: kOptionAllowAutoDisconnect));
    return _drGroup('Protection', [
      DrToggleRow(
        title: 'Two-step verification',
        description: 'People also need a code from an authenticator app.',
        value: has2fa,
        onChanged: enabled
            ? (on) {
                if (!on) {
                  CommonConfirmDialog(gFFI.dialogManager,
                      translate('cancel-2fa-confirm-tip'), () => change2fa(callback: _refresh));
                } else {
                  change2fa(callback: _refresh);
                }
              }
            : null,
      ),
      if (has2fa)
        DrSubRows(children: [
          DrToggleRow(
            title: 'Send codes to Telegram',
            value: hasBot,
            onChanged: enabled
                ? (on) {
                    if (!on) {
                      CommonConfirmDialog(gFFI.dialogManager,
                          translate('cancel-bot-confirm-tip'), () => changeBot(callback: _refresh));
                    } else {
                      changeBot(callback: _refresh);
                    }
                  }
                : null,
          ),
          _DrOption('Remember trusted computers', kOptionEnableTrustedDevices,
              description: 'Skip the code on computers you’ve approved before.',
              enabled: enabled,
              onChanged: (_) => _refresh(),
              extra: mainGetBoolOptionSync(kOptionEnableTrustedDevices)
                  ? DrButton('Manage…',
                      kind: DrButtonKind.secondary,
                      height: 34,
                      fontSize: 12.5,
                      onPressed: enabled ? manageTrustedDeviceDialog : null)
                  : null),
        ]),
      _DrOption('End idle sessions automatically', kOptionAllowAutoDisconnect,
          description: 'Disconnects people who haven’t done anything for a while.',
          enabled: enabled,
          onChanged: (_) => _refresh()),
      if (autoEnd)
        DrSubRows(children: [
          DrSettingRow(
            title: 'After',
            trailing: DrInputApply(
              value: bind.mainGetOptionSync(key: kOptionAutoDisconnectTimeout),
              hint: '10',
              suffix: 'minutes',
              enabled: enabled && !isOptionFixed(kOptionAutoDisconnectTimeout),
              allowPattern: r'^\d{0,5}$',
              onApply: (v) =>
                  bind.mainSetOption(key: kOptionAutoDisconnectTimeout, value: v),
            ),
          ),
        ]),
      if (bind.mainIsInstalled())
        _DrOption('Only while the app window is open', 'allow-only-conn-window-open',
            description: 'Nobody can connect while Digital R Viewer is closed to the tray.',
            enabled: enabled),
      if (bind.mainIsInstalled() && !isUnlockPinDisabled())
        DrToggleRow(
          title: 'Protect these settings with a PIN',
          description: 'Asks for a PIN instead of administrator rights to unlock.',
          value: pin.isNotEmpty,
          onChanged: enabled ? (_) => changeUnlockPinDialog(pin, _refresh) : null,
        ),
    ]);
  }

  Widget _whoMayConnect(bool enabled) {
    final ipList = whitelistNotEmpty();
    final idList = idWhitelistNotEmpty();
    return _drGroup('Who may connect', [
      DrToggleRow(
        title: 'Only from approved IP addresses',
        description: ipList ? 'An allow-list is active.' : 'Connections from any address are allowed.',
        value: ipList,
        badge: isOptionFixed(kOptionWhitelist) ? _kDrManaged : null,
        onChanged: enabled && !isOptionFixed(kOptionWhitelist)
            ? (_) => changeWhiteList(callback: _refresh)
            : null,
      ),
      DrToggleRow(
        title: 'Only from approved IDs',
        description: idList ? 'An allow-list is active.' : 'Any ID may ask to connect.',
        value: idList,
        badge: isOptionFixed(kOptionIdWhitelist) ? _kDrManaged : null,
        onChanged: enabled && !isOptionFixed(kOptionIdWhitelist)
            ? (_) => changeIdWhiteList(callback: _refresh)
            : null,
      ),
      _DrOption('Visible on my local network', 'enable-lan-discovery',
          description: 'Lets computers on the same Wi-Fi or office network find this one.',
          enabled: enabled),
    ]);
  }

  Widget _yourId(bool enabled) => ChangeNotifierProvider.value(
        value: gFFI.serverModel,
        child: Consumer<ServerModel>(
          builder: (context, model, _) => _drGroup('Your ID', [
            DrSettingRow(
              title: 'Pick a different ID',
              description: 'Choose an easier number or name for this computer.',
              trailing: DrButton('Change ID…',
                  kind: DrButtonKind.secondary,
                  height: 38,
                  fontSize: 13,
                  onPressed: enabled && model.connectStatus > 0 ? changeIdDialog : null),
            ),
          ]),
        ),
      );
}
