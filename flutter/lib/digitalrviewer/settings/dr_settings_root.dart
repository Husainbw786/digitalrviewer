// Digital R Viewer settings: our own sections, grouping and wording on top of the same option
// keys and side effects as the stock pages in desktop_setting_page.dart.
//
// A part of that library so it can reuse its private helpers (unlock gate, proxy dialog …)
// without copying them. The stock `_General`, `_Safety` … widgets stay for kDrUi == false.
part of '../../desktop/pages/desktop_setting_page.dart';

enum _DrSection { basics, remoteAccess, sessions, recording, account, advanced, about }

extension on _DrSection {
  String get label => switch (this) {
        _DrSection.basics => 'Basics',
        _DrSection.remoteAccess => 'Remote access',
        _DrSection.sessions => 'Your sessions',
        _DrSection.recording => 'Recording',
        _DrSection.account => 'Your account',
        _DrSection.advanced => 'Advanced',
        _DrSection.about => 'App info',
      };
}

List<_DrSection> _drSections() => [
      _DrSection.basics,
      if (!bind.isOutgoingOnly() &&
          !bind.isDisableSettings() &&
          bind.mainGetBuildinOption(key: kOptionHideSecuritySetting) != 'Y')
        _DrSection.remoteAccess,
      if (!bind.isIncomingOnly()) _DrSection.sessions,
      _DrSection.recording,
      if (!bind.isDisableAccount()) _DrSection.account,
      if (!bind.isDisableSettings()) _DrSection.advanced,
      _DrSection.about,
    ];

/// Where the stock "open settings at …" calls should land.
_DrSection _drSectionFor(SettingsTabKey key) => switch (key) {
      SettingsTabKey.general => _DrSection.basics,
      SettingsTabKey.safety => _DrSection.remoteAccess,
      SettingsTabKey.network => _DrSection.advanced,
      SettingsTabKey.display => _DrSection.sessions,
      SettingsTabKey.account => _DrSection.account,
      SettingsTabKey.printer => _DrSection.advanced,
      SettingsTabKey.about => _DrSection.about,
    };

class _DrSettingsRoot extends StatefulWidget {
  final Rx<SettingsTabKey> stockTab;
  const _DrSettingsRoot({required this.stockTab});

  @override
  State<_DrSettingsRoot> createState() => _DrSettingsRootState();
}

class _DrSettingsRootState extends State<_DrSettingsRoot> {
  final sections = _drSections();
  late _DrSection _section;
  Worker? _follow;

  /// Installed builds protect Remote access and part of Advanced until unlocked, like the
  /// stock pages (administrator rights or the settings PIN).
  final RxBool locked = (!isWeb && bind.mainIsInstalled()).obs;

  @override
  void initState() {
    super.initState();
    _section = _pick(widget.stockTab.value);
    // DesktopSettingPage.switch2page(…) moves the stock tab; follow it.
    _follow = ever<SettingsTabKey>(widget.stockTab, (k) {
      if (mounted) setState(() => _section = _pick(k));
    });
  }

  _DrSection _pick(SettingsTabKey k) {
    final s = _drSectionFor(k);
    return sections.contains(s) ? s : sections.first;
  }

  @override
  void dispose() {
    _follow?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrSettingsShell(
      sections: sections.map((s) => s.label).toList(),
      selected: sections.indexOf(_section),
      onSelect: (i) => setState(() => _section = sections[i]),
      content: KeyedSubtree(
        key: ValueKey(_section),
        child: switch (_section) {
          _DrSection.basics => const _DrBasics(),
          _DrSection.remoteAccess => _DrRemoteAccess(locked: locked),
          _DrSection.sessions => const _DrSessions(),
          _DrSection.recording => const _DrRecording(),
          _DrSection.account => const _DrAccount(),
          _DrSection.advanced => _DrAdvanced(locked: locked),
          _DrSection.about => const _DrAbout(),
        },
      ),
    );
  }
}

// ── helpers ───────────────────────────────────────────────────────────────

const String _kDrManaged = 'Set by your organisation';

/// Same unlock rules as the stock `_lock` button.
Future<void> _drUnlock(VoidCallback onUnlock) async {
  final unlockPin = bind.mainGetUnlockPin();
  if (unlockPin.isEmpty || isUnlockPinDisabled()) {
    if (await callMainCheckSuperUserPermission()) onUnlock();
  } else {
    checkUnlockPinDialog(unlockPin, onUnlock);
  }
}

Widget _drUnlockBanner(RxBool locked, String what) => Obx(() => locked.value
    ? DrUnlockBanner(
        message:
            '$what can only be changed by an administrator of this computer.',
        onUnlock: () => _drUnlock(() => locked.value = false))
    : const SizedBox.shrink());

/// An on/off option bound to a setting key — the same reads, writes and value encoding as
/// the stock `_OptionCheckBox`, shown as one of our toggle rows.
class _DrOption extends StatefulWidget {
  final String title;
  final String? description;
  final String optionKey;
  final bool isServer;
  final bool reverse;
  final bool enabled;
  final bool? fakeValue;
  final bool Function()? getter;
  final Future<void> Function(String key, bool value)? setter;
  final void Function(bool value)? onChanged;
  final Widget? extra;

  const _DrOption(this.title, this.optionKey,
      {this.description,
      this.isServer = true,
      this.reverse = false,
      this.enabled = true,
      this.fakeValue,
      this.getter,
      this.setter,
      this.onChanged,
      this.extra});

  @override
  State<_DrOption> createState() => _DrOptionState();
}

class _DrOptionState extends State<_DrOption> {
  bool _read() {
    final v = widget.getter != null
        ? widget.getter!()
        : (widget.isServer
            ? mainGetBoolOptionSync(widget.optionKey)
            : mainGetLocalBoolOptionSync(widget.optionKey));
    return widget.reverse ? !v : v;
  }

  late bool _value = _read();

  @override
  void didUpdateWidget(covariant _DrOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    _value = _read();
  }

  Future<void> _set(bool shown) async {
    final stored = widget.reverse ? !shown : shown;
    final setter = widget.setter ??
        (widget.isServer ? mainSetBoolOption : mainSetLocalBoolOption);
    await setter(widget.optionKey, stored);
    if (!mounted) return;
    setState(() => _value = _read());
    widget.onChanged?.call(widget.reverse ? !_value : _value);
  }

  @override
  Widget build(BuildContext context) {
    final fixed = isOptionFixed(widget.optionKey);
    final fake = widget.fakeValue;
    return DrToggleRow(
      title: widget.title,
      description: widget.description,
      value: fake ?? _value,
      badge: fixed ? _kDrManaged : null,
      extra: widget.extra,
      onChanged: widget.enabled && !fixed && fake == null ? _set : null,
    );
  }
}

/// Group card with the standard spacing.
Widget _drGroup(String? title, List<Widget> rows) =>
    rows.isEmpty ? const SizedBox.shrink() : DrSettingsGroup(title: title, children: rows);

/// Scrollable section page with our header.
Widget _drPage(String title, String subtitle, List<Widget> children) =>
    DrSettingsPage(title: title, subtitle: subtitle, children: children);
