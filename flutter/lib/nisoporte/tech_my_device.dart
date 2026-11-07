part of 'tech_home.dart';

/// «Mi equipo»: ID, contraseña temporal, estado del servicio y un resumen de
/// los permisos de acceso entrante. Los permisos se cambian en Ajustes ›
/// Seguridad, que conserva el desbloqueo de la página de ajustes original.
class _MyDeviceSection extends StatefulWidget {
  final _ServerState server;
  final VoidCallback onOpenSecurity;

  const _MyDeviceSection({required this.server, required this.onOpenSecurity});

  @override
  State<_MyDeviceSection> createState() => _MyDeviceSectionState();
}

class _MyDeviceSectionState extends State<_MyDeviceSection> {
  final RxBool _serviceStopped = Get.find<RxBool>(tag: 'stop-service');
  bool _serviceBusy = false;

  Future<void> _toggleService() async {
    setState(() => _serviceBusy = true);
    await start_service(_serviceStopped.value);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _serviceBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final model = gFFI.serverModel;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: AnimatedBuilder(
          animation: model,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mi equipo',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                  'Datos para que otro técnico se conecte a este ordenador.',
                  style: TextStyle(color: NiTheme.muted)),
              const SizedBox(height: 20),
              _codeCard(model),
              const SizedBox(height: 14),
              _serviceCard(),
              _permissionsCard(model),
            ],
          ),
        ),
      ),
    );
  }

  Widget _codeCard(ServerModel model) {
    final showOneTime = model.approveMode != 'click' &&
        model.verificationMethod != kUsePermanentPassword;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ID', style: TextStyle(color: NiTheme.muted)),
          const SizedBox(height: 4),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: model.serverId,
            builder: (_, v, __) => Row(
              children: [
                Expanded(
                  child: SelectableText(v.text,
                      style: NiTheme.codeStyle.copyWith(fontSize: 32)),
                ),
                _SecondaryButton(
                  label: 'Copiar',
                  icon: Icons.copy_rounded,
                  onPressed: () => _copy(v.text.replaceAll(' ', '')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: NiTheme.border),
          const SizedBox(height: 18),
          const Text('Contraseña de un solo uso',
              style: TextStyle(color: NiTheme.muted)),
          const SizedBox(height: 4),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: model.serverPasswd,
            builder: (_, v, __) => Row(
              children: [
                Expanded(
                  child: SelectableText(v.text,
                      style: NiTheme.codeStyle.copyWith(fontSize: 32)),
                ),
                _SecondaryButton(
                  label: 'Copiar',
                  icon: Icons.copy_rounded,
                  onPressed: showOneTime ? () => _copy(v.text) : null,
                ),
                const SizedBox(width: 8),
                _SecondaryButton(
                  label: 'Cambiar',
                  icon: Icons.refresh_rounded,
                  onPressed: showOneTime
                      ? () => bind.mainUpdateTemporaryPassword()
                      : null,
                ),
              ],
            ),
          ),
          if (!showOneTime) ...[
            const SizedBox(height: 8),
            Text(
                model.approveMode == 'click'
                    ? 'Las conexiones se aceptan con un clic: no se usa contraseña.'
                    : 'Solo se acepta la contraseña permanente (Ajustes › Seguridad).',
                style: const TextStyle(color: NiTheme.muted, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _serviceCard() {
    final hideStopService =
        bind.mainGetBuildinOption(key: kOptionHideStopService) == 'Y';
    return Obx(() {
      final stopped = _serviceStopped.value;
      final (Color color, String label) = stopped
          ? (NiTheme.error, 'Servicio detenido: nadie puede conectarse aquí')
          : switch (widget.server) {
              _ServerState.ready => (
                  NiTheme.success,
                  'Servicio activo y conectado al servidor NiRepair'
                ),
              _ServerState.connecting => (
                  NiTheme.warning,
                  'Servicio activo, conectando con el servidor…'
                ),
              _ServerState.offline => (
                  NiTheme.error,
                  'Servicio activo, sin conexión con el servidor'
                ),
            };
      return _SettingCard(
        title: 'Estado del servicio',
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: const TextStyle(color: NiTheme.text2))),
            if (!bind.mainIsInstalled())
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('Sin instalar',
                    style: TextStyle(color: NiTheme.muted, fontSize: 12)),
              ),
            if (stopped || !hideStopService)
              _SecondaryButton(
                label: stopped ? 'Iniciar' : 'Detener',
                icon: stopped
                    ? Icons.play_arrow_rounded
                    : Icons.stop_rounded,
                onPressed: _serviceBusy ? null : _toggleService,
              ),
          ],
        ),
      );
    });
  }

  Widget _permissionsCard(ServerModel model) {
    final accessMode = bind.mainGetOptionSync(key: kOptionAccessMode);
    final String modeLabel = switch (accessMode) {
      'full' => 'Acceso completo',
      'view' => 'Solo ver la pantalla',
      _ => 'Personalizado',
    };
    final approve = switch (model.approveMode) {
      'password' => 'Con contraseña',
      'click' => 'Con un clic',
      _ => 'Con contraseña o con un clic',
    };
    bool perm(String key) => accessMode == 'full'
        ? true
        : accessMode == 'view'
            ? false
            : mainGetBoolOptionSync(key);
    final items = <(String, bool)>[
      ('Teclado y ratón', perm(kOptionEnableKeyboard)),
      ('Portapapeles', perm(kOptionEnableClipboard)),
      ('Transferir archivos', perm(kOptionEnableFileTransfer)),
      ('Audio', perm(kOptionEnableAudio)),
      ('Reiniciar el equipo', perm(kOptionEnableRemoteRestart)),
      ('Grabar la sesión', perm(kOptionEnableRecordSession)),
    ];
    return _SettingCard(
      title: 'Acceso entrante',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Modo de acceso', modeLabel),
          _kv('Aceptar conexiones', approve),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final i in items) _PermChip(label: i.$1, on: i.$2)],
          ),
          const SizedBox(height: 14),
          _SecondaryButton(
            label: 'Cambiar en Ajustes › Seguridad',
            icon: Icons.shield_outlined,
            onPressed: widget.onOpenSecurity,
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
                width: 160,
                child: Text(k, style: const TextStyle(color: NiTheme.muted))),
            Expanded(
                child: Text(v, style: const TextStyle(color: NiTheme.text))),
          ],
        ),
      );
}

class _PermChip extends StatelessWidget {
  final String label;
  final bool on;

  const _PermChip({required this.label, required this.on});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: NiTheme.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: on ? NiTheme.success.withOpacity(0.5) : NiTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(on ? Icons.check_rounded : Icons.block_rounded,
              size: 15, color: on ? NiTheme.success : NiTheme.muted),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: on ? NiTheme.text : NiTheme.muted)),
        ],
      ),
    );
  }
}
