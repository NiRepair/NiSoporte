import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/server_page.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';

import 'theme.dart';
import 'widgets.dart';

Future<void> configureNiClientConsent() async {
  await bind.mainSetOption(key: kOptionApproveMode, value: 'click');
  await bind.mainSetOption(key: kOptionEnableKeyboard, value: defaultOptionYes);
  await bind.mainSetOption(key: kOptionEnableClipboard, value: defaultOptionYes);
  await bind.mainSetOption(key: kOptionEnableFileTransfer, value: 'N');
  await bind.mainSetOption(key: kOptionEnableAudio, value: 'N');
}

class NiIncomingPage extends StatefulWidget {
  const NiIncomingPage({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<NiIncomingPage> createState() => _NiIncomingPageState();
}

class _NiIncomingPageState extends State<NiIncomingPage> {
  bool _helpActive = false;
  Timer? _minimizeTimer;

  @override
  void initState() {
    super.initState();
    gFFI.serverModel.addListener(_updateHelpWindow);
  }

  void _updateHelpWindow() {
    final clients = gFFI.serverModel.clients.where((c) => !c.disconnected);
    final pending = clients.any((c) => !c.authorized);
    final active = clients.any((c) => c.authorized) && !pending;
    if (pending) {
      _minimizeTimer?.cancel();
      _minimizeTimer = null;
    }
    if (active == _helpActive) return;
    _minimizeTimer?.cancel();
    _helpActive = active;
    windowManager.setSize(active ? const Size(320, 150) : const Size(440, 490));
    if (active) {
      _minimizeTimer = Timer(const Duration(seconds: 3), () {
        _minimizeTimer = null;
        if (mounted && _helpActive) windowManager.minimize();
      });
    }
  }

  @override
  void dispose() {
    _minimizeTimer?.cancel();
    gFFI.serverModel.removeListener(_updateHelpWindow);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        // Keep the existing CM event subscriptions and window-close lifecycle.
        ExcludeFocus(child: Offstage(offstage: true, child: widget.child)),
        Positioned.fill(
          child: Scaffold(
            body: Column(children: [
              SizedBox(
                height: 32,
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (_) => windowManager.startDragging(),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Text('NiSoporte'),
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Minimizar',
                    icon: const Icon(Icons.minimize, size: 18),
                    onPressed: () => windowManager.minimize(),
                  ),
                ]),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: gFFI.serverModel,
                  builder: (context, _) {
                    final clients = gFFI.serverModel.clients
                        .where((client) => !client.disconnected)
                        .toList();
                    return Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(_helpActive ? 8 : 20),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          if (!_helpActive) ...[
                            const NiBrand(),
                            const SizedBox(height: 20),
                          ],
                          if (clients.isEmpty)
                            const Text('Esperando una solicitud de ayuda…',
                                style: TextStyle(color: NiTheme.text2)),
                          for (final client in clients) ...[
                            if (client.authorized)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('NiRepair te está ayudando',
                                      style: TextStyle(color: NiTheme.success,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: NiTheme.error),
                                    onPressed: () => checkClickTime(client.id,
                                        () => bind.cmCloseConnection(connId: client.id)),
                                    child: const Text('Terminar ayuda'),
                                  ),
                                ],
                              )
                            else
                              NiIncomingDialog(
                                  key: ValueKey(client.id), client: client),
                            const SizedBox(height: 12),
                          ],
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ]);
}

class NiIncomingDialog extends StatefulWidget {
  const NiIncomingDialog({Key? key, required this.client}) : super(key: key);

  final Client client;

  @override
  State<NiIncomingDialog> createState() => _NiIncomingDialogState();
}

class _NiIncomingDialogState extends State<NiIncomingDialog> {
  bool _busy = false;
  String? _error;

  bool get _screenRequest => !widget.client.isFileTransfer &&
      !widget.client.isViewCamera &&
      !widget.client.isTerminal &&
      widget.client.portForward.isEmpty;

  Future<void> _respond(bool accept) async {
    if (!mounted || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (accept) {
        for (final permission in <String, bool>{
          'keyboard': true,
          'clipboard': true,
          'file': false,
          'audio': false,
        }.entries) {
          await bind.cmSwitchPermission(
              connId: widget.client.id,
              name: permission.key,
              enabled: permission.value);
        }
      }
      if (!mounted || widget.client.disconnected) return;
      gFFI.serverModel.sendLoginResponse(widget.client, accept);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'La solicitud no se ha podido procesar. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => NiCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('NiRepair quiere ayudarte',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(
            _screenRequest
                ? 'Al aceptar, nuestro técnico podrá ver y controlar tu pantalla y usar el portapapeles. Puedes terminar la ayuda cuando quieras.'
                : 'Esta solicitud no es para compartir la pantalla. Recházala y pide al técnico que solicite ayuda de pantalla.',
            style: const TextStyle(color: NiTheme.text2),
          ),
          const SizedBox(height: 20),
          Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => checkClickTime(widget.client.id, () => _respond(false)),
              child: const Text('Rechazar'),
            ),
            ElevatedButton(
              onPressed: _busy || !_screenRequest
                  ? null
                  : () => checkClickTime(widget.client.id, () => _respond(true)),
              child: const Text('Aceptar'),
            ),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: NiTheme.error)),
          ],
        ]),
      );
}
