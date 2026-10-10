// DigitalRViewer UI components. Flutter-only (no RustDesk imports), see theme.dart.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

enum DrButtonKind { primary, secondary, ghostOnAccent, disabled }

/// Pill button from the mockups: black primary, white/outlined secondary.
class DrButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final DrButtonKind kind;
  final double height;
  final double fontSize;
  final Widget? icon;
  final bool expand;
  final EdgeInsetsGeometry? padding;

  const DrButton(this.label,
      {super.key,
      this.onPressed,
      this.kind = DrButtonKind.primary,
      this.height = 46,
      this.fontSize = 14,
      this.icon,
      this.expand = false,
      this.padding});

  @override
  State<DrButton> createState() => _DrButtonState();
}

class _DrButtonState extends State<DrButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    final disabled =
        widget.onPressed == null || widget.kind == DrButtonKind.disabled;
    late Color fill, fg;
    Border? border;
    switch (disabled ? DrButtonKind.disabled : widget.kind) {
      case DrButtonKind.primary:
        fill = _hover ? Color.alphaBlend(const Color(0x22FFFFFF), c.primary) : c.primary;
        fg = c.onPrimary;
        break;
      case DrButtonKind.secondary:
        fill = _hover ? c.chrome : c.surface;
        fg = c.text;
        border = Border.all(color: c.borderStrong);
        break;
      case DrButtonKind.ghostOnAccent:
        fill = _hover ? c.accentBorder.withOpacity(0.35) : Colors.transparent;
        fg = c.text;
        border = Border.all(color: c.accentBorder);
        break;
      case DrButtonKind.disabled:
        fill = c.disabledFill;
        fg = c.disabledText;
        border = Border.all(color: c.borderStrong);
        break;
    }
    final weight = widget.kind == DrButtonKind.primary || disabled
        ? FontWeight.w600
        : FontWeight.w500;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: widget.height,
      padding: widget.padding ??
          EdgeInsets.symmetric(horizontal: widget.height >= 44 ? 22 : 14),
      decoration: BoxDecoration(
          color: fill,
          border: border,
          borderRadius: BorderRadius.circular(DrRadius.pill)),
      // An aligned Container fills its parent, so only align when asked to expand.
      alignment: widget.expand ? Alignment.center : null,
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            IconTheme(
                data: IconThemeData(color: fg, size: 15), child: widget.icon!),
            const SizedBox(width: 8),
          ],
          Text(widget.label,
              style: DrText.sans(widget.fontSize, fg, weight: weight)),
        ],
      ),
    );
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: disabled ? null : widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: Semantics(button: true, enabled: !disabled, child: child),
      ),
    );
  }
}

/// White rounded card with the mockups' thin warm border.
class DrCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final bool shadow;
  final bool border;

  const DrCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(18),
      this.radius = DrRadius.card,
      this.color,
      this.shadow = false,
      this.border = true});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: c.border) : null,
        boxShadow: shadow ? DrShadow.card : null,
      ),
      child: child,
    );
  }
}

/// Pill toggle (44×26 settings / 40×24 dialog).
class DrToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool small;
  final String? semanticLabel;

  const DrToggle(
      {super.key,
      required this.value,
      this.onChanged,
      this.small = false,
      this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    final w = small ? 40.0 : 44.0, h = small ? 24.0 : 26.0;
    final knob = h - 6;
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: enabled ? () => onChanged!(!value) : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: w,
              height: h,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                  color: value ? c.primary : c.toggleOff,
                  borderRadius: BorderRadius.circular(h / 2)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 140),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: knob,
                  height: knob,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: value
                        ? null
                        : const [
                            BoxShadow(
                                color: Color(0x26161513),
                                blurRadius: 2,
                                offset: Offset(0, 1))
                          ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The segmented pill nav in the top bar (Home / Devices / Transfers).
class DrSegmentedNav extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  const DrSegmentedNav(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: c.chrome, borderRadius: BorderRadius.circular(DrRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            _Segment(
                label: labels[i],
                on: i == selected,
                onTap: () => onSelect(i)),
          ]
        ],
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Segment({required this.label, required this.on, required this.onTap});
  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.on ? c.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(DrRadius.pill),
            boxShadow: widget.on ? DrShadow.segmentOn : null,
          ),
          child: Text(widget.label,
              style: DrText.sans(
                  13,
                  widget.on ? c.text : (_hover ? c.text : c.textMuted),
                  weight: widget.on ? FontWeight.w600 : FontWeight.w500)),
        ),
      ),
    );
  }
}

/// Small filter chip (All · 6 / Online · 4 …).
class DrChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const DrChip(this.label,
      {super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? c.accent : c.surface,
            border: selected ? null : Border.all(color: c.borderStrong),
            borderRadius: BorderRadius.circular(DrRadius.pill),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(label,
                style: DrText.sans(13, selected ? c.accentText : c.textMuted,
                    weight: selected ? FontWeight.w600 : FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}

/// Round icon button (settings gear in the top bar).
class DrIconCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final String tooltip;
  const DrIconCircle(
      {super.key,
      required this.icon,
      required this.onTap,
      this.active = false,
      required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active ? c.primary : c.surface,
              shape: BoxShape.circle,
              border: active ? null : Border.all(color: c.border),
            ),
            child: Icon(icon,
                size: 17, color: active ? c.onPrimary : c.textMuted),
          ),
        ),
      ),
    );
  }
}

/// Pill text field (Device ID input, search box).
class DrPillField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hint;
  final double height;
  final double fontSize;
  final double? letterSpacing;
  final Widget? leading;
  final bool sunk;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final String? semanticLabel;

  const DrPillField(
      {super.key,
      this.controller,
      this.focusNode,
      required this.hint,
      this.height = 54,
      this.fontSize = 18,
      this.letterSpacing,
      this.leading,
      this.sunk = true,
      this.onSubmitted,
      this.onChanged,
      this.inputFormatters,
      this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: leading != null ? 16 : 20),
      decoration: BoxDecoration(
        color: sunk ? c.surfaceSunk : c.surface,
        border: Border.all(color: c.borderStrong),
        borderRadius: BorderRadius.circular(DrRadius.pill),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: onSubmitted,
              onChanged: onChanged,
              inputFormatters: inputFormatters,
              cursorColor: c.text,
              style: DrText.sans(fontSize, c.text,
                  letterSpacing: letterSpacing, tabular: true),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hint,
                hintStyle: DrText.sans(fontSize, c.placeholder,
                    letterSpacing: letterSpacing),
                semanticCounterText: semanticLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DrStatusDot extends StatelessWidget {
  final bool online;
  final double fontSize;
  const DrStatusDot({super.key, required this.online, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
              color: online ? c.online : c.offline, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(online ? 'Online' : 'Offline',
          style: DrText.sans(fontSize, online ? c.onlineText : c.textSubtle,
              weight: FontWeight.w500)),
    ]);
  }
}

/// Lilac initials circle (device rows, incoming request).
class DrInitials extends StatelessWidget {
  final String name;
  final double size;
  const DrInitials(this.name, {super.key, this.size = 34});

  static String initialsOf(String name) {
    final parts = name
        .replaceAll(RegExp(r"['’]s\b"), '')
        .split(RegExp(r'[\s._@\-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
      child: Text(initialsOf(name),
          style: DrText.sans(size * 0.38, c.accentText, weight: FontWeight.w700)),
    );
  }
}

/// Black rounded-square logo mark with a monitor glyph (top bar).
class DrLogoMark extends StatelessWidget {
  final double size;
  const DrLogoMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: c.primary, borderRadius: BorderRadius.circular(DrRadius.logo)),
      child: CustomPaint(painter: _MonitorGlyph(c.onPrimary)),
    );
  }
}

class _MonitorGlyph extends CustomPainter {
  final Color color;
  _MonitorGlyph(this.color);
  @override
  void paint(Canvas canvas, Size s) {
    // 18-unit viewBox scaled to 15/28 of the tile, centred (matches the mockup SVG).
    final scale = s.width * 15 / 28 / 18;
    final off = (s.width - 18 * scale) / 2;
    canvas.translate(off, off);
    canvas.scale(scale);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(2, 3, 14, 9.5), const Radius.circular(2)),
        p);
    canvas.drawLine(const Offset(6.5, 15.5), const Offset(11.5, 15.5), p);
  }

  @override
  bool shouldRepaint(_MonitorGlyph old) => old.color != color;
}

/// Brand lockup used in the top bar.
class DrBrand extends StatelessWidget {
  const DrBrand({super.key});
  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const DrLogoMark(),
      const SizedBox(width: 10),
      Text(kDrDisplayName,
          style: DrText.sans(16, c.text,
              weight: FontWeight.w700, letterSpacing: -0.16)),
    ]);
  }
}

/// Linkish text button ("See all", "Connect →").
class DrLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double fontSize;
  final FontWeight weight;
  final Color? color;
  const DrLink(this.label,
      {super.key,
      required this.onTap,
      this.fontSize = 13,
      this.weight = FontWeight.w600,
      this.color});
  @override
  State<DrLink> createState() => _DrLinkState();
}

class _DrLinkState extends State<DrLink> {
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
        child: Text(widget.label,
            style: DrText.sans(widget.fontSize,
                _hover ? c.link : (widget.color ?? c.text),
                weight: widget.weight)),
      ),
    );
  }
}

/// Formats a RustDesk ID in groups of three: 318552904 → "318 552 904".
String drFormatId(String id) {
  final digits = id.replaceAll(' ', '');
  if (!RegExp(r'^\d{6,}$').hasMatch(digits)) return id;
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) b.write(' ');
    b.write(digits[i]);
  }
  return b.toString();
}

/// Inline notice banner (permissions missing, install prompt, errors).
class DrNotice extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onClose;
  const DrNotice(
      {super.key,
      required this.title,
      required this.message,
      this.actionLabel,
      this.onAction,
      this.onClose});

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(DrRadius.tile),
        border: Border.all(color: c.accentBorder),
      ),
      child: Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c.danger, shape: BoxShape.circle)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title.isNotEmpty)
                Text(title,
                    style: DrText.sans(14, c.text, weight: FontWeight.w600)),
              if (message.isNotEmpty) ...[
                if (title.isNotEmpty) const SizedBox(height: 2),
                Text(message, style: DrText.sans(13, c.textMuted, height: 1.4)),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 14),
          DrButton(actionLabel!, height: 38, fontSize: 13, onPressed: onAction),
        ],
        if (onClose != null)
          IconButton(
              tooltip: 'Dismiss',
              icon: Icon(Icons.close, size: 18, color: c.textMuted),
              onPressed: onClose),
      ]),
    );
  }
}
