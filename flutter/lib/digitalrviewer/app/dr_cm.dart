// Connection-manager (incoming request) adapter for the DigitalRViewer card.
import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:provider/provider.dart';

import '../screens/incoming_view.dart';
import 'dr_main_window.dart' show kDrUi;

/// True when the DigitalRViewer request card should replace the stock CM card: only for
/// a pending request with no elevation prompt (other states keep RustDesk's panel,
/// which carries chat, voice call, elevation and switch-back controls).
bool drUseRequestCard(Client client, ServerModel model) {
  if (!kDrUi || client.authorized || client.disconnected) return false;
  final showElevation = bind.cmCanElevate() &&
      model.showElevation &&
      client.type_() == ClientType.remote &&
      bind.mainGetBuildinOption(key: kOptionHideElevateButtonInAcceptWindow) !=
          'Y';
  return !showElevation;
}

class DrCmRequestCard extends StatefulWidget {
  final Client client;
  const DrCmRequestCard({super.key, required this.client});
  @override
  State<DrCmRequestCard> createState() => _DrCmRequestCardState();
}

class _DrCmRequestCardState extends State<DrCmRequestCard> {
  void _switch(String name, bool enabled, void Function() apply) {
    bind.cmSwitchPermission(
        connId: widget.client.id, name: name, enabled: enabled);
    setState(apply);
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final model = Provider.of<ServerModel>(context);
    final type = client.type_();
    final perms = <DrPermission>[];
    if (type == ClientType.remote) {
      perms.addAll([
        DrPermission(translate('Use your mouse and keyboard'), client.keyboard,
            (v) => _switch('keyboard', v, () => client.keyboard = v)),
        DrPermission(translate('Use your clipboard'), client.clipboard,
            (v) => _switch('clipboard', v, () => client.clipboard = v)),
        DrPermission(translate('Send and receive files'), client.file,
            (v) => _switch('file', v, () => client.file = v)),
        DrPermission(translate('Hear your audio'), client.audio,
            (v) => _switch('audio', v, () => client.audio = v)),
      ]);
    }
    final name = client.name.isEmpty ? client.peerId : client.name;
    final headline = switch (type) {
      ClientType.file => '$name wants to transfer files',
      ClientType.portForward => '$name wants to open a tunnel',
      ClientType.terminal => '$name wants to open a terminal',
      _ => '$name wants to connect',
    };
    return SingleChildScrollView(
      child: DrIncomingRequestCard(
        compact: true,
        name: name,
        headline: headline,
        peerId: client.peerId,
        permissions: perms,
        showAllow: model.approveMode != 'password',
        note: type == ClientType.remote
            ? 'They will see your screen. You can end the session at any time.'
            : null,
        onAllow: () => model.sendLoginResponse(client, true),
        onDecline: () => bind.cmCloseConnection(connId: client.id),
      ),
    );
  }
}
