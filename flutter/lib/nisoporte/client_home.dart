import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';

import 'theme.dart';
import 'widgets.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({Key? key, this.serviceStopped = false}) : super(key: key);

  final bool serviceStopped;

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  Timer? _timer;
  String _password = '';
  bool _changingPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshPassword();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshPassword());
  }

  Future<void> _refreshPassword() async {
    try {
      // The shared model deliberately hides this value in click approval mode.
      final password = await bind.mainGetTemporaryPassword();
      if (mounted && (password != _password || _error != null)) {
        setState(() {
          _password = password;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'No se ha podido leer la contraseña.');
    }
  }

  Future<void> _changePassword() async {
    setState(() => _changingPassword = true);
    try {
      await bind.mainUpdateTemporaryPassword();
      await _refreshPassword();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se ha podido cambiar la contraseña.');
      }
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _credential(BuildContext context, String label, String value,
          {bool password = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: NiTheme.text2)),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SelectableText(value.isEmpty ? 'Generando…' : value,
                  style: NiTheme.codeStyle),
            ),
          ),
          IconButton(
            tooltip: 'Copiar $label',
            onPressed: value.isEmpty ? null : () => niCopy(context, value),
            icon: const Icon(Icons.copy),
          ),
          if (password)
            IconButton(
              tooltip: 'Cambiar contraseña',
              onPressed: _changingPassword ? null : _changePassword,
              icon: const Icon(Icons.refresh),
            ),
        ]),
      ]);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: gFFI.serverModel,
        builder: (context, _) {
          final model = gFFI.serverModel;
          return Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const NiBrand(),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: NiStatus(
                              status: widget.serviceStopped
                                  ? -1
                                  : model.connectStatus),
                        ),
                        const SizedBox(height: 20),
                        _credential(context, 'ID',
                            model.connectStatus == 1 ? model.serverId.text : ''),
                        const SizedBox(height: 16),
                        _credential(context, 'Contraseña', _password,
                            password: true),
                        const SizedBox(height: 12),
                        const Text('Díctale estos números a nuestro técnico',
                            style: TextStyle(color: NiTheme.text2)),
                        if (_error != null)
                          Text(_error!, style: const TextStyle(color: NiTheme.error)),
                        const Spacer(),
                        const SizedBox(height: 12),
                        const NiContact(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
