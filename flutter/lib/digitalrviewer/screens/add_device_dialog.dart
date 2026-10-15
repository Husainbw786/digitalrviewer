// "Add device" / "Edit device" dialog. Pure view: checking and saving are supplied by the caller.
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

enum DrIdStatus { online, offline, invalid }

typedef DrCheckId = Future<DrIdStatus> Function(String id);

/// Returns an error message, or null when saved.
typedef DrSaveDevice = Future<String?> Function(
    String id, String name, String note);

/// Shows the dialog. [id] pre-fills the ID; with [editing] the ID is fixed.
Future<void> drShowAddDeviceDialog(
  BuildContext context, {
  required DrCheckId onCheck,
  required DrSaveDevice onSave,
  ValueChanged<String>? onConnect,
  bool signedIn = false,
  String id = '',
  String name = '',
  String note = '',
  bool editing = false,
}) =>
    showDialog(
      context: context,
      builder: (_) => DrAddDeviceDialog(
          onCheck: onCheck,
          onSave: onSave,
          onConnect: onConnect,
          signedIn: signedIn,
          id: id,
          name: name,
          note: note,
          editing: editing),
    );

class DrAddDeviceDialog extends StatefulWidget {
  final DrCheckId onCheck;
  final DrSaveDevice onSave;
  final ValueChanged<String>? onConnect;
  final bool signedIn;
  final String id;
  final String name;
  final String note;
  final bool editing;
  const DrAddDeviceDialog(
      {super.key,
      required this.onCheck,
      required this.onSave,
      this.onConnect,
      this.signedIn = false,
      this.id = '',
      this.name = '',
      this.note = '',
      this.editing = false});

  @override
  State<DrAddDeviceDialog> createState() => _DrAddDeviceDialogState();
}

class _DrAddDeviceDialogState extends State<DrAddDeviceDialog> {
  late final _id = TextEditingController(text: drFormatId(widget.id));
  late final _name = TextEditingController(text: widget.name);
  late final _note = TextEditingController(text: widget.note);
  DrIdStatus? _status;
  String? _checkedId;
  bool _checking = false;
  bool _saving = false;
  String? _error;

  String get _rawId => _id.text.replaceAll(RegExp(r'\s'), '');

  @override
  void initState() {
    super.initState();
    if (widget.id.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final id = _rawId;
    if (id.isEmpty) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final s = await widget.onCheck(id);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _status = s;
      _checkedId = id;
    });
  }

  Future<void> _save() async {
    if (_rawId.isEmpty) {
      setState(() => _error = 'Enter the device ID.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final err = await widget.onSave(_rawId, _name.text, _note.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DrColors.of(context);
    final label = DrText.sans(13, c.textMuted, weight: FontWeight.w600);
    final status = _checkedId == _rawId ? _status : null;
    return Dialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DrRadius.dialog)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 30, 32, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.editing ? 'Edit device' : 'Add a device',
                  style: DrText.serif(28, c.text)),
              const SizedBox(height: 6),
              Text(
                  widget.editing
                      ? 'Change how this device appears in your list.'
                      : 'Enter the ID shown on the other computer.',
                  style: DrText.sans(14, c.textMuted)),
              const SizedBox(height: 24),
              Text('Device ID', style: label),
              const SizedBox(height: 8),
              if (widget.editing)
                Text(drFormatId(widget.id),
                    style: DrText.sans(20, c.text,
                        weight: FontWeight.w600, tabular: true))
              else
                Row(children: [
                  Expanded(
                    child: DrPillField(
                      controller: _id,
                      hint: '123 456 789',
                      height: 48,
                      fontSize: 17,
                      semanticLabel: 'Device ID',
                      onChanged: (_) => setState(() => _error = null),
                      onSubmitted: (_) => _check(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DrButton(_checking ? 'Checking…' : 'Check',
                      kind: DrButtonKind.secondary,
                      height: 48,
                      onPressed: _checking ? null : _check),
                ]),
              const SizedBox(height: 10),
              _statusLine(c, status),
              const SizedBox(height: 18),
              Text('Name', style: label),
              const SizedBox(height: 8),
              DrPillField(
                controller: _name,
                hint: 'e.g. Office PC',
                height: 48,
                fontSize: 15,
                semanticLabel: 'Device name',
              ),
              const SizedBox(height: 18),
              Text('Note', style: label),
              const SizedBox(height: 8),
              DrPillField(
                controller: _note,
                hint: 'Optional — who it belongs to, where it is…',
                height: 48,
                fontSize: 15,
                semanticLabel: 'Note',
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 16),
              Text(
                  widget.signedIn
                      ? 'Saved on this computer and in your account, so it appears wherever you sign in.'
                      : 'Saved on this computer. Sign in to keep your devices in your account too.',
                  style: DrText.sans(12.5, c.textSubtle, height: 1.4)),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: DrText.sans(13, c.danger, height: 1.4)),
              ],
              const SizedBox(height: 24),
              Row(children: [
                if (widget.onConnect != null && !widget.editing)
                  DrLink('Connect now', onTap: () {
                    final id = _rawId;
                    if (id.isEmpty) return;
                    Navigator.of(context).pop();
                    widget.onConnect!(id);
                  }),
                const Spacer(),
                DrButton('Cancel',
                    kind: DrButtonKind.secondary,
                    height: 44,
                    onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: 10),
                DrButton(_saving ? 'Saving…' : 'Save device',
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    onPressed: _saving ? null : _save),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusLine(DrColors c, DrIdStatus? s) {
    if (_checking) {
      return Text('Asking the server…', style: DrText.sans(13, c.textSubtle));
    }
    switch (s) {
      case DrIdStatus.online:
        return const Align(
            alignment: Alignment.centerLeft,
            child: DrStatusDot(online: true, fontSize: 13));
      case DrIdStatus.offline:
        return Row(children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: c.offline, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
                'Not reachable right now — it may be switched off, or the ID may be wrong. You can still save it.',
                style: DrText.sans(13, c.textMuted, height: 1.4)),
          ),
        ]);
      case DrIdStatus.invalid:
        return Text('That doesn’t look like a device ID (6 or more digits).',
            style: DrText.sans(13, c.danger));
      case null:
        return Text('Check tells you whether the device is online.',
            style: DrText.sans(13, c.textSubtle));
    }
  }
}
