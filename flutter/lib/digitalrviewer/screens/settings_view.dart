// Settings building blocks ("4 · Settings" mockup): left nav, section header, toggle
// group, radio cards. The app keeps its own setting logic and lays it out with these.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets.dart';
import 'shell.dart';

class DrSettingsShell extends StatelessWidget {
  final List<String> sections;
  final int selected;
  final ValueChanged<int> onSelect;
  final Widget content;

  const DrSettingsShell(
      {super.key,
      required this.sections,
      required this.selected,
      required this.onSelect,
      required this.content});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 28, 40, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Settings', style: DrText.serif(34, c.text)),
                const SizedBox(height: 18),
                for (var i = 0; i < sections.length; i++) ...[
                  _NavItem(
                      label: sections[i],
                      selected: i == selected,
                      onTap: () => onSelect(i)),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem(
      {required this.label, required this.selected, required this.onTap});
  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: widget.selected
                ? c.accent
                : (_hover ? c.chrome : Colors.transparent),
            borderRadius: BorderRadius.circular(DrRadius.nav),
          ),
          child: Text(widget.label,
              style: DrText.sans(
                  14, widget.selected ? c.accentText : c.textMuted,
                  weight: widget.selected ? FontWeight.w600 : FontWeight.w500)),
        ),
      ),
    );
  }
}

class DrSettingsHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const DrSettingsHeader(this.title, {super.key, this.subtitle});
  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DrText.sans(20, c.text, weight: FontWeight.w600)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: DrText.sans(14, c.textMuted)),
          ],
        ],
      ),
    );
  }
}

/// White rounded group of rows (toggles, values). Children are separated by dividers.
class DrSettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const DrSettingsGroup({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DrCard(
        padding: EdgeInsets.fromLTRB(24, title == null ? 4 : 20, 24, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(title!,
                    style: DrText.sans(14, c.text, weight: FontWeight.w600)),
              ),
            for (var i = 0; i < children.length; i++)
              Container(
                decoration: BoxDecoration(
                    border: i == children.length - 1
                        ? null
                        : Border(bottom: BorderSide(color: c.divider))),
                child: children[i],
              ),
          ],
        ),
      ),
    );
  }
}

class DrToggleRow extends StatelessWidget {
  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Small tag after the title, e.g. "Set by your organisation".
  final String? badge;

  /// Extra widget between the text and the toggle (e.g. a "Test" or "Manage…" button).
  final Widget? extra;
  const DrToggleRow(
      {super.key,
      required this.title,
      this.description,
      required this.value,
      this.onChanged,
      this.badge,
      this.extra});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Row(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DrRowTitle(title, badge: badge, enabled: onChanged != null),
                if (description != null) ...[
                  const SizedBox(height: 3),
                  Text(description!,
                      style: DrText.sans(13, c.textSubtle, height: 1.4)),
                ],
              ],
            ),
          ),
        ),
        if (extra != null) ...[const SizedBox(width: 12), extra!],
        const SizedBox(width: 20),
        DrToggle(value: value, onChanged: onChanged, semanticLabel: title),
      ]),
    );
  }
}

class DrRadioOption<T> {
  final T value;
  final String title;
  final String description;
  const DrRadioOption(this.value, this.title, this.description);
}

/// Two-up radio cards ("One-time password" / "Permanent password").
class DrRadioCards<T> extends StatelessWidget {
  final List<DrRadioOption<T>> options;
  final T? selected;
  final ValueChanged<T>? onSelect;
  const DrRadioCards(
      {super.key, required this.options, required this.selected, this.onSelect});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: _card(c, options[i], options[i].value == selected)),
          ]
        ],
      ),
    );
  }

  Widget _card(DrColors c, DrRadioOption<T> o, bool on) {
    return MouseRegion(
      cursor: onSelect == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onSelect == null ? null : () => onSelect!(o.value),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: on ? c.surfaceSunk : null,
            borderRadius: BorderRadius.circular(DrRadius.option),
            border: Border.all(
                color: on ? c.text : c.borderStrong, width: on ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: on ? c.text : c.placeholder, width: on ? 5 : 1.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.title,
                        style:
                            DrText.sans(14, c.text, weight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(o.description, style: DrText.sans(13, c.textSubtle)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrRowTitle extends StatelessWidget {
  final String title;
  final String? badge;
  final bool enabled;
  const _DrRowTitle(this.title, {this.badge, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(title,
            style: DrText.sans(14, enabled ? c.text : c.textSubtle,
                weight: FontWeight.w600)),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(DrRadius.pill),
            ),
            child: Text(badge!,
                style: DrText.sans(11, c.accentText, weight: FontWeight.w600)),
          ),
      ],
    );
  }
}

/// A settings row: title + optional description on the left, any control on the right.
class DrSettingRow extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? trailing;
  final String? badge;
  final bool enabled;

  /// Put the control under the text instead of beside it (wide controls).
  final Widget? below;
  const DrSettingRow(
      {super.key,
      required this.title,
      this.description,
      this.trailing,
      this.badge,
      this.enabled = true,
      this.below});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DrRowTitle(title, badge: badge, enabled: enabled),
                  if (description != null) ...[
                    const SizedBox(height: 3),
                    Text(description!,
                        style: DrText.sans(13, c.textSubtle, height: 1.4)),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 20), trailing!],
          ]),
          if (below != null) ...[const SizedBox(height: 12), below!],
        ],
      ),
    );
  }
}

/// Small segmented choice (2–4 short options) used inside settings rows.
class DrChoicePills<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  const DrChoicePills(
      {super.key, required this.options, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    final enabled = onChanged != null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: c.chrome, borderRadius: BorderRadius.circular(DrRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in options)
              MouseRegion(
                cursor: enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: GestureDetector(
                  onTap: enabled ? () => onChanged!(o.$1) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: o.$1 == value ? c.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(DrRadius.pill),
                      boxShadow: o.$1 == value ? DrShadow.segmentOn : null,
                    ),
                    child: Text(o.$2,
                        style: DrText.sans(
                            13, o.$1 == value ? c.text : c.textMuted,
                            weight: o.$1 == value
                                ? FontWeight.w600
                                : FontWeight.w500)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Rounded dropdown in the design language.
class DrSelect<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final double width;
  const DrSelect(
      {super.key,
      required this.options,
      required this.value,
      this.onChanged,
      this.width = 220});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    final has = options.any((o) => o.$1 == value);
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.borderStrong),
        borderRadius: BorderRadius.circular(DrRadius.pill),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: has ? value : null,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: c.surface,
          icon: Icon(Icons.expand_more, size: 18, color: c.textMuted),
          style: DrText.sans(13.5, c.text),
          onChanged:
              onChanged == null ? null : (v) => v == null ? null : onChanged!(v),
          items: [
            for (final o in options)
              DropdownMenuItem<T>(
                  value: o.$1,
                  child: Text(o.$2,
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

/// Short text/number field with an Apply button that appears only when the value changed.
class DrInputApply extends StatefulWidget {
  final String value;
  final String hint;
  final String? suffix;
  final bool enabled;
  final String? allowPattern;
  final Future<void> Function(String) onApply;
  final double width;
  const DrInputApply(
      {super.key,
      required this.value,
      required this.onApply,
      this.hint = '',
      this.suffix,
      this.enabled = true,
      this.allowPattern,
      this.width = 96});

  @override
  State<DrInputApply> createState() => _DrInputApplyState();
}

class _DrInputApplyState extends State<DrInputApply> {
  late final _ctl = TextEditingController(text: widget.value);
  late String _saved = widget.value;

  @override
  void didUpdateWidget(covariant DrInputApply old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctl.text == _saved) {
      _ctl.text = widget.value;
      _saved = widget.value;
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    final dirty = _ctl.text.trim() != _saved.trim();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: widget.width,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.enabled ? c.surface : c.disabledFill,
          border: Border.all(color: c.borderStrong),
          borderRadius: BorderRadius.circular(DrRadius.pill),
        ),
        child: TextField(
          controller: _ctl,
          enabled: widget.enabled,
          onChanged: (_) => setState(() {}),
          inputFormatters: widget.allowPattern == null
              ? null
              : [FilteringTextInputFormatter.allow(RegExp(widget.allowPattern!))],
          style: DrText.sans(13.5, c.text, tabular: true),
          decoration: InputDecoration(
            isCollapsed: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            hintText: widget.hint,
            hintStyle: DrText.sans(13.5, c.placeholder),
          ),
        ),
      ),
      if (widget.suffix != null) ...[
        const SizedBox(width: 8),
        Text(widget.suffix!, style: DrText.sans(13, c.textMuted)),
      ],
      if (dirty && widget.enabled) ...[
        const SizedBox(width: 8),
        DrButton('Apply', height: 36, fontSize: 13, onPressed: () async {
          final v = _ctl.text.trim();
          await widget.onApply(v);
          if (mounted) setState(() => _saved = v);
        }),
      ],
    ]);
  }
}

/// Indented block of rows that only matters while its parent option is on.
class DrSubRows extends StatelessWidget {
  final List<Widget> children;
  const DrSubRows({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Container(
      margin: const EdgeInsets.only(left: 4, bottom: 10),
      padding: const EdgeInsets.only(left: 18),
      decoration: BoxDecoration(
          border: Border(left: BorderSide(color: c.accentBorder, width: 2))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// A settings group that starts collapsed (used for the Advanced section).
class DrCollapsibleGroup extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyOpen;
  const DrCollapsibleGroup(
      {super.key,
      required this.title,
      this.subtitle,
      required this.children,
      this.initiallyOpen = false});

  @override
  State<DrCollapsibleGroup> createState() => _DrCollapsibleGroupState();
}

class _DrCollapsibleGroupState extends State<DrCollapsibleGroup> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DrCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 18, 18),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title,
                              style: DrText.sans(15, c.text,
                                  weight: FontWeight.w600)),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(widget.subtitle!,
                                style: DrText.sans(13, c.textSubtle)),
                          ],
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(Icons.expand_more, color: c.textMuted),
                    ),
                  ]),
                ),
              ),
            ),
            if (_open)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.divider))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < widget.children.length; i++)
                      Container(
                        decoration: BoxDecoration(
                            border: i == widget.children.length - 1
                                ? null
                                : Border(
                                    bottom: BorderSide(color: c.divider))),
                        child: widget.children[i],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "These settings are locked" banner with an Unlock button.
class DrUnlockBanner extends StatelessWidget {
  final String message;
  final VoidCallback onUnlock;
  const DrUnlockBanner(
      {super.key, required this.message, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
      decoration: BoxDecoration(
        color: c.accent,
        border: Border.all(color: c.accentBorder),
        borderRadius: BorderRadius.circular(DrRadius.tile),
      ),
      child: Row(children: [
        Icon(Icons.lock_outline, size: 20, color: c.accentText),
        const SizedBox(width: 12),
        Expanded(
            child: Text(message,
                style: DrText.sans(13.5, c.accentText, height: 1.4))),
        const SizedBox(width: 12),
        DrButton('Unlock', height: 38, fontSize: 13, onPressed: onUnlock),
      ]),
    );
  }
}

/// Convenience: a scrollable settings content column with the standard header.
class DrSettingsPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  const DrSettingsPage(
      {super.key, required this.title, this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [DrSettingsHeader(title, subtitle: subtitle), ...children],
    );
  }
}

/// Re-export for the settings screen's top-bar usage.
typedef DrSettingsTab = DrTab;
