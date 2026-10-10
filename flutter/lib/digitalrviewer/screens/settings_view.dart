// Settings building blocks ("4 · Settings" mockup): left nav, section header, toggle
// group, radio cards. The app keeps its own setting logic and lays it out with these.
import 'package:flutter/material.dart';

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
  const DrToggleRow(
      {super.key,
      required this.title,
      this.description,
      required this.value,
      this.onChanged});

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
                Text(title,
                    style: DrText.sans(14, c.text, weight: FontWeight.w600)),
                if (description != null) ...[
                  const SizedBox(height: 3),
                  Text(description!, style: DrText.sans(13, c.textSubtle)),
                ],
              ],
            ),
          ),
        ),
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
