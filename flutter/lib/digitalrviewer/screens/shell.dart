// Main-window chrome: top bar with brand, segmented nav and settings button.
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

enum DrTab { home, devices, transfers, settings }

class DrTopBar extends StatelessWidget {
  final DrTab tab;
  final ValueChanged<DrTab> onTab;

  /// Space reserved on the left for native window controls (macOS traffic lights).
  final double leadingInset;

  /// Optional widget at the far right (e.g. Windows min/max/close).
  final Widget? trailing;

  /// Optional widget just left of the settings button (e.g. the update pill).
  final Widget? actions;

  const DrTopBar(
      {super.key,
      required this.tab,
      required this.onTab,
      this.leadingInset = 0,
      this.trailing,
      this.actions});

  static const tabs = [DrTab.home, DrTab.devices, DrTab.transfers];
  static const labels = ['Home', 'Devices', 'Transfers'];

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Container(
      height: 64,
      padding: EdgeInsets.only(left: 24 + leadingInset, right: trailing == null ? 24 : 8),
      decoration: BoxDecoration(
          color: c.bg, border: Border(bottom: BorderSide(color: c.divider))),
      child: Row(
        children: [
          const DrBrand(),
          Expanded(
            child: Center(
              child: DrSegmentedNav(
                labels: labels,
                selected: tabs.indexOf(tab),
                onSelect: (i) => onTab(tabs[i]),
              ),
            ),
          ),
          if (actions != null) ...[actions!, const SizedBox(width: 10)],
          DrIconCircle(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            active: tab == DrTab.settings,
            onTap: () => onTab(DrTab.settings),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

/// Standard page padding from the mockups (28 top, 40 sides, 32 bottom).
class DrPage extends StatelessWidget {
  final Widget child;
  final bool scroll;
  const DrPage({super.key, required this.child, this.scroll = true});

  @override
  Widget build(BuildContext context) {
    const pad = EdgeInsets.fromLTRB(40, 28, 40, 32);
    if (!scroll) return Padding(padding: pad, child: child);
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: pad,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - pad.vertical),
          child: child,
        ),
      ),
    );
  }
}

/// Serif page heading + muted subtitle ("Your devices", "File transfers").
class DrPageHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  const DrPageHeading(this.title, {super.key, this.subtitle});
  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: DrText.serif(34, c.text)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: DrText.sans(14, c.textMuted)),
        ],
      ],
    );
  }
}
