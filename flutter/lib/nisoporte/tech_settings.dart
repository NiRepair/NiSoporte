part of 'tech_home.dart';

const _kNiSoporteVersion = '1.0';
const _kSourceUrl = 'https://github.com/NiRepair/NiSoporte';
const _kLicenseUrl = 'https://www.gnu.org/licenses/agpl-3.0.html';
const _kWebUrl = 'https://nirepair.es';

enum _SettingsTab { general, security, display, about }

/// Ajustes del técnico con el estilo NiSoporte. Lee y escribe las mismas
/// opciones que `desktop_setting_page.dart` y conserva sus protecciones: la
/// pestaña Seguridad se desbloquea igual (PIN o permiso de administrador) y
/// todo se bloquea mientras una sesión entrante pueda modificar los ajustes.
class _SettingsSection extends StatefulWidget {
  const _SettingsSection();

  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  _SettingsTab _tab = _SettingsTab.general;
  final RxBool _canBeBlocked = false.obs;
  Timer? _blockTimer;

  @override
  void initState() {
    super.initState();
    _blockTimer = periodic_immediate(const Duration(seconds: 1), () async {
      if (!mounted) return;
      final blocked = await canBeBlocked();
      if (mounted) _canBeBlocked.value = blocked;
    });
  }

  @override
  void dispose() {
    _blockTimer?.cancel();
    super.dispose();
  }

  Widget _tabContent() {
    switch (_tab) {
      case _SettingsTab.general:
        return const _GeneralSettings();
      case _SettingsTab.security:
        return const _SecuritySettings();
      case _SettingsTab.display:
        return const _DisplaySettings();
      case _SettingsTab.about:
        return const _AboutSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration =
        MediaQuery.of(context).disableAnimations ? Duration.zero : _kAnim;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ajustes',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tabChip(_SettingsTab.general, Icons.settings_rounded,
                      'General'),
                  _tabChip(_SettingsTab.security, Icons.shield_outlined,
                      'Seguridad'),
                  _tabChip(_SettingsTab.display, Icons.monitor_rounded,
                      'Pantalla'),
                  _tabChip(
                      _SettingsTab.about, Icons.info_outline_rounded,
                      'Acerca de'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            final videoConnBlock =
                _canBeBlocked.value && stateGlobal.videoConnCount > 0;
            return Stack(
              fit: StackFit.expand,
              children: [
                preventMouseKeyBuilder(
                  block: videoConnBlock,
                  child: AnimatedSwitcher(
                    duration: duration,
                    layoutBuilder: _fillLayout,
                    child: KeyedSubtree(
                        key: ValueKey(_tab), child: _tabContent()),
                  ),
                ),
                if (videoConnBlock)
                  const Positioned(
                    left: 32,
                    right: 32,
                    top: 0,
                    child: _InfoBanner(
                      color: NiTheme.warning,
                      text:
                          'Hay una sesión entrante en curso: los ajustes quedan bloqueados hasta que termine.',
                    ),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _tabChip(_SettingsTab tab, IconData icon, String label) {
    final selected = tab == _tab;
    return Material(
      color: selected ? NiTheme.surface2 : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: selected ? NiTheme.accent : NiTheme.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => setState(() => _tab = tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 17, color: selected ? NiTheme.accent : NiTheme.muted),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? NiTheme.text : NiTheme.text2)),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _settingsScroll(List<Widget> children) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );

// ---------------------------------------------------------------- general

class _GeneralSettings extends StatefulWidget {
  const _GeneralSettings();

  @override
  State<_GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<_GeneralSettings> {
  List<MapEntry<String, String>> _langs = [];

  @override
  void initState() {
    super.initState();
    _loadLangs();
  }

  Future<void> _loadLangs() async {
    final List<dynamic> list = jsonDecode(await bind.mainGetLangs());
    final langs = <MapEntry<String, String>>[
      MapEntry(defaultOptionLang, 'Idioma del sistema'),
      for (final v in list) MapEntry(v[0] as String, v[1] as String),
    ];
    if (mounted) setState(() => _langs = langs);
  }

  Future<void> _setLang(String key) async {
    await bind.mainSetLocalOption(key: kCommConfKeyLang, value: key);
    reloadAllWindows();
    bind.mainChangeLanguage(lang: key);
  }

  Future<void> _pickRecordDir(String current) async {
    final selected = await FilePicker.platform.getDirectoryPath(
        initialDirectory: current.isEmpty ? null : current);
    if (selected == null) return;
    await bind.mainSetLocalOption(
        key: kOptionVideoSaveDirectory, value: selected);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String currentLang = bind.mainGetLocalOption(key: kCommConfKeyLang);
    if (!_langs.any((e) => e.key == currentLang)) {
      currentLang = defaultOptionLang;
    }
    final recordDir = bind.mainVideoSaveDirectory(root: false);

    return _settingsScroll([
      _SettingCard(
        title: 'Idioma',
        child: _langs.isEmpty
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentLang,
                  dropdownColor: NiTheme.surface2,
                  borderRadius: BorderRadius.circular(12),
                  style: const TextStyle(color: NiTheme.text),
                  items: _langs
                      .map((e) => DropdownMenuItem<String>(
                          value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: isOptionFixed(kCommConfKeyLang)
                      ? null
                      : (key) {
                          if (key != null) _setLang(key);
                        },
                ),
              ),
      ),
      const _SettingCard(
        title: 'Tema',
        child: Text('Oscuro NiRepair. Es fijo y no sigue el tema de Windows.',
            style: TextStyle(color: NiTheme.text2)),
      ),
      const _SettingCard(
        title: 'Calidad de imagen por defecto',
        child: _QualityChoice(),
      ),
      _SettingCard(
        title: 'Ventanas de sesión',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _OptionToggle(
              label: 'Abrir cada conexión nueva en una pestaña',
              optionKey: kOptionOpenNewConnInTabs,
              isServer: false,
            ),
            const _OptionToggle(
              label: 'Preguntar antes de cerrar varias pestañas',
              optionKey: kOptionEnableConfirmClosingTabs,
              isServer: false,
            ),
            const SizedBox(height: 6),
            const Text(
                'NiSoporte recuerda siempre el tamaño y la posición de cada ventana, también por equipo remoto.',
                style: TextStyle(color: NiTheme.muted, fontSize: 12)),
          ],
        ),
      ),
      _SettingCard(
        title: 'Carpeta de grabaciones',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(recordDir,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: NiTheme.text2)),
                ),
                const SizedBox(width: 12),
                _SecondaryButton(
                  label: 'Cambiar',
                  onPressed: isOptionFixed(kOptionVideoSaveDirectory)
                      ? null
                      : () => _pickRecordDir(recordDir),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
                'Los archivos recibidos se guardan en la carpeta que elijas en la ventana de transferencia.',
                style: TextStyle(color: NiTheme.muted, fontSize: 12)),
          ],
        ),
      ),
    ]);
  }
}

// ---------------------------------------------------------------- security

enum _AccessMode { custom, full, view }

class _SecuritySettings extends StatefulWidget {
  const _SecuritySettings();

  @override
  State<_SecuritySettings> createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends State<_SecuritySettings> {
  bool _locked = bind.mainIsInstalled();

  Future<void> _unlock() async {
    void onUnlock() {
      if (mounted) setState(() => _locked = false);
    }

    final unlockPin = bind.mainGetUnlockPin();
    if (unlockPin.isEmpty || isUnlockPinDisabled()) {
      if (await callMainCheckSuperUserPermission()) onUnlock();
    } else {
      checkUnlockPinDialog(unlockPin, onUnlock);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _settingsScroll([
      if (_locked)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(color: NiTheme.surface2),
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, color: NiTheme.accent),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                    'Los ajustes de seguridad están protegidos. Desbloquéalos para cambiarlos.',
                    style: TextStyle(color: NiTheme.text2)),
              ),
              const SizedBox(width: 12),
              _AccentButton(
                  label: 'Desbloquear',
                  icon: Icons.lock_open_rounded,
                  onPressed: _unlock),
            ],
          ),
        ),
      preventMouseKeyBuilder(
        block: _locked,
        child: Opacity(
          opacity: _locked ? 0.55 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _approveAndPasswordCard(),
              _permissionsCard(),
              _SettingCard(
                title: 'Red local',
                child: _OptionToggle(
                  label: 'Denegar descubrimiento en red local',
                  optionKey: kOptionEnableLanDiscovery,
                  reverse: true,
                  enabled: !_locked,
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _approveAndPasswordCard() {
    final model = gFFI.serverModel;
    return AnimatedBuilder(
      animation: model,
      builder: (context, _) {
        final enabled = !_locked;
        final modeKeys = <String>['password', 'click', defaultOptionApproveMode];
        var mode = model.approveMode;
        if (!modeKeys.contains(mode)) mode = defaultOptionApproveMode;
        final usePassword = model.approveMode != 'click';
        final approveFixed = isOptionFixed(kOptionApproveMode);
        final tmpEnabled = model.verificationMethod != kUsePermanentPassword;
        final permEnabled = model.verificationMethod != kUseTemporaryPassword;

        Future<void> onVerification(String key) async {
          callback() async {
            await model.setVerificationMethod(key);
            await model.updatePasswordModel();
          }

          if (key == kUsePermanentPassword &&
              (await bind.mainGetCommon(key: 'permanent-password-set')) !=
                  'true') {
            if (isChangePermanentPasswordDisabled()) {
              await callback();
              return;
            }
            setPasswordDialog(notEmptyCallback: callback);
          } else {
            await callback();
          }
        }

        final numericFixed = isOptionFixed(kOptionAllowNumericOneTimePassword);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingCard(
              title: 'Aprobar conexiones entrantes',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final m in [
                    (modeKeys[0], 'Solo con contraseña'),
                    (modeKeys[1], 'Solo con un clic en este equipo'),
                    (modeKeys[2], 'Con contraseña o con un clic'),
                  ])
                    _RadioRow<String>(
                      value: m.$1,
                      groupValue: mode,
                      label: m.$2,
                      onChanged: enabled && !approveFixed
                          ? (v) => model.setApproveMode(v)
                          : null,
                    ),
                ],
              ),
            ),
            if (usePassword)
              _SettingCard(
                title: 'Contraseña',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final v in [
                      (kUseTemporaryPassword, 'Usar contraseña de un solo uso'),
                      (kUsePermanentPassword, 'Usar contraseña permanente'),
                      (kUseBothPasswords, 'Usar las dos'),
                    ])
                      _RadioRow<String>(
                        value: v.$1,
                        groupValue: model.verificationMethod,
                        label: v.$2,
                        onChanged: enabled ? onVerification : null,
                      ),
                    const SizedBox(height: 10),
                    const Text('Longitud de la contraseña de un solo uso',
                        style: TextStyle(color: NiTheme.muted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final len in const ['6', '8', '10'])
                          _Choice(
                            label: len,
                            selected: model.temporaryPasswordLength == len,
                            onSelected: enabled && tmpEnabled
                                ? () async {
                                    await model
                                        .setTemporaryPasswordLength(len);
                                    await model.updatePasswordModel();
                                  }
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _ToggleRow(
                      label: 'Contraseña de un solo uso solo con números',
                      value: model.allowNumericOneTimePassword,
                      onChanged: enabled && tmpEnabled && !numericFixed
                          ? (_) => model.switchAllowNumericOneTimePassword()
                          : null,
                    ),
                    if (!isChangePermanentPasswordDisabled()) ...[
                      const SizedBox(height: 6),
                      _SecondaryButton(
                        label: 'Establecer contraseña permanente',
                        icon: Icons.key_rounded,
                        onPressed: enabled && permEnabled
                            ? () => setPasswordDialog()
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _permissionsCard() {
    final enabled = !_locked;
    final accessMode = bind.mainGetOptionSync(key: kOptionAccessMode);
    final mode = accessMode == 'full'
        ? _AccessMode.full
        : accessMode == 'view'
            ? _AccessMode.view
            : _AccessMode.custom;
    final bool? fakeValue = switch (mode) {
      _AccessMode.custom => null,
      _AccessMode.full => true,
      _AccessMode.view => false,
    };
    final modeFixed = isOptionFixed(kOptionAccessMode);

    Future<void> setMode(String value) async {
      await bind.mainSetOption(key: kOptionAccessMode, value: value);
      if (mounted) setState(() {});
    }

    Widget perm(String label, String key) => _OptionToggle(
          label: label,
          optionKey: key,
          enabled: enabled,
          fakeValue: fakeValue,
        );

    return _SettingCard(
      title: 'Permisos de acceso entrante',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Choice(
                label: 'Personalizado',
                selected: mode == _AccessMode.custom,
                onSelected: enabled && !modeFixed
                    ? () => setMode(defaultOptionAccessMode)
                    : null,
              ),
              _Choice(
                label: 'Acceso completo',
                selected: mode == _AccessMode.full,
                onSelected:
                    enabled && !modeFixed ? () => setMode('full') : null,
              ),
              _Choice(
                label: 'Solo ver la pantalla',
                selected: mode == _AccessMode.view,
                onSelected:
                    enabled && !modeFixed ? () => setMode('view') : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          perm('Teclado y ratón', kOptionEnableKeyboard),
          if (isWindows) perm('Impresora remota', kOptionEnableRemotePrinter),
          perm('Portapapeles', kOptionEnableClipboard),
          perm('Transferir archivos', kOptionEnableFileTransfer),
          perm('Audio', kOptionEnableAudio),
          perm('Cámara', kOptionEnableCamera),
          perm('Terminal', kOptionEnableTerminal),
          perm('Túneles TCP', kOptionEnableTunnel),
          perm('Reiniciar el equipo', kOptionEnableRemoteRestart),
          perm('Grabar la sesión', kOptionEnableRecordSession),
          if (isWindows)
            perm('Bloquear teclado y ratón del usuario',
                kOptionEnableBlockInput),
          if (bind.mainSupportedPrivacyModeImpls() != '[]')
            perm('Modo privacidad', kOptionEnablePrivacyMode),
          perm('Cambiar estos ajustes desde la sesión remota',
              kOptionAllowRemoteConfigModification),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- display

class _DisplaySettings extends StatefulWidget {
  const _DisplaySettings();

  @override
  State<_DisplaySettings> createState() => _DisplaySettingsState();
}

class _DisplaySettingsState extends State<_DisplaySettings> {
  Future<void> _setDefault(String key, String value) async {
    await bind.mainSetUserDefaultOption(key: key, value: value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final viewStyle = bind.mainGetUserDefaultOption(key: kOptionViewStyle);
    final viewFixed = isOptionFixed(kOptionViewStyle);
    final codec = bind.mainGetUserDefaultOption(key: kOptionCodecPreference);
    final codecFixed = isOptionFixed(kOptionCodecPreference);
    final codecs = <(String, String)>[
      ('auto', 'Automático'),
      ('vp8', 'VP8'),
      ('vp9', 'VP9'),
      ('av1', 'AV1'),
    ];
    try {
      final Map hw = jsonDecode(bind.mainSupportedHwdecodings());
      if (hw['h264'] == true) codecs.add(('h264', 'H264'));
      if (hw['h265'] == true) codecs.add(('h265', 'H265'));
    } catch (e) {
      debugPrint('failed to parse supported hwdecodings, err=$e');
    }

    return _settingsScroll([
      _SettingCard(
        title: 'Escala por defecto',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RadioRow<String>(
              value: kRemoteViewStyleAdaptive,
              groupValue: viewStyle,
              label: 'Ajustar a la ventana',
              onChanged: viewFixed
                  ? null
                  : (v) => _setDefault(kOptionViewStyle, v),
            ),
            _RadioRow<String>(
              value: kRemoteViewStyleOriginal,
              groupValue: viewStyle,
              label: 'Tamaño original (1:1)',
              onChanged: viewFixed
                  ? null
                  : (v) => _setDefault(kOptionViewStyle, v),
            ),
          ],
        ),
      ),
      const _SettingCard(
        title: 'Calidad de imagen por defecto',
        child: _QualityChoice(),
      ),
      _SettingCard(
        title: 'Códec por defecto',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in codecs)
                  _Choice(
                    label: c.$2,
                    selected: codec == c.$1,
                    onSelected: codecFixed
                        ? null
                        : () => _setDefault(kOptionCodecPreference, c.$1),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
                '«Automático» elige el mejor códec que admitan los dos equipos.',
                style: TextStyle(color: NiTheme.muted, fontSize: 12)),
          ],
        ),
      ),
    ]);
  }
}

class _QualityChoice extends StatefulWidget {
  const _QualityChoice();

  @override
  State<_QualityChoice> createState() => _QualityChoiceState();
}

class _QualityChoiceState extends State<_QualityChoice> {
  Future<void> _set(String value) async {
    await bind.mainSetUserDefaultOption(key: kOptionImageQuality, value: value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final quality = bind.mainGetUserDefaultOption(key: kOptionImageQuality);
    final fixed = isOptionFixed(kOptionImageQuality);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in const [
              (kRemoteImageQualityBest, 'Máxima'),
              (kRemoteImageQualityBalanced, 'Equilibrada'),
              (kRemoteImageQualityLow, 'Rápida'),
            ])
              _Choice(
                label: q.$2,
                selected: quality == q.$1,
                onSelected: fixed ? null : () => _set(q.$1),
              ),
          ],
        ),
        if (quality == kRemoteImageQualityCustom) ...[
          const SizedBox(height: 8),
          const Text(
              'Ahora mismo hay una calidad personalizada; elige una opción para sustituirla.',
              style: TextStyle(color: NiTheme.muted, fontSize: 12)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- about

class _AboutSettings extends StatelessWidget {
  const _AboutSettings();

  Future<Map<String, String>> _load() async => {
        'version': await bind.mainGetVersion(),
        'buildDate': await bind.mainGetBuildDate(),
        'fingerprint': await bind.mainGetFingerprint(),
      };

  void _open(String url) => launchUrl(Uri.parse(url));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _load(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, String>{};
        return _settingsScroll([
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(22),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                loadIcon(56),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NiSoporte Técnico',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Versión $_kNiSoporteVersion · de NiRepair',
                          style: TextStyle(color: NiTheme.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _SettingCard(
            title: 'Detalles',
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _aboutRow('Versión del motor', data['version'] ?? '…'),
                  _aboutRow('Fecha de compilación', data['buildDate'] ?? '…'),
                  _aboutRow('Huella de este equipo',
                      (data['fingerprint'] ?? '').isEmpty
                          ? '—'
                          : data['fingerprint']!),
                ],
              ),
            ),
          ),
          _SettingCard(
            title: 'Licencia',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'NiSoporte es software libre: puedes usarlo, estudiarlo, modificarlo y compartirlo bajo la licencia GNU Affero General Public License, versión 3 (AGPL-3.0). El código fuente completo de esta versión está publicado.',
                    style: TextStyle(color: NiTheme.text2, height: 1.4)),
                const SizedBox(height: 8),
                Text(
                    'Basado en RustDesk · Copyright © 2020-${DateTime.now().year} Purslane Tech Pte. Ltd. y colaboradores.',
                    style:
                        const TextStyle(color: NiTheme.muted, fontSize: 12)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SecondaryButton(
                      label: 'Código fuente',
                      icon: Icons.code_rounded,
                      onPressed: () => _open(_kSourceUrl),
                    ),
                    _SecondaryButton(
                      label: 'Texto de la licencia AGPL',
                      icon: Icons.gavel_rounded,
                      onPressed: () => _open(_kLicenseUrl),
                    ),
                    _SecondaryButton(
                      label: 'nirepair.es',
                      icon: Icons.language_rounded,
                      onPressed: () => _open(_kWebUrl),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]);
      },
    );
  }

  Widget _aboutRow(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 180,
                child: Text(k, style: const TextStyle(color: NiTheme.muted))),
            Expanded(
                child: Text(v,
                    style: _monoStyle.copyWith(
                        fontSize: 13,
                        letterSpacing: 0.5,
                        color: NiTheme.text))),
          ],
        ),
      );
}

// ---------------------------------------------------------------- controls

/// Interruptor ligado a una opción, con la misma semántica que
/// `_OptionCheckBox` de la página de ajustes original (opción fija,
/// `reverse`, `fakeValue` para los modos de acceso completo / solo ver).
class _OptionToggle extends StatefulWidget {
  final String label;
  final String optionKey;
  final bool isServer;
  final bool reverse;
  final bool enabled;
  final bool? fakeValue;

  const _OptionToggle({
    required this.label,
    required this.optionKey,
    this.isServer = true,
    this.reverse = false,
    this.enabled = true,
    this.fakeValue,
  });

  @override
  State<_OptionToggle> createState() => _OptionToggleState();
}

class _OptionToggleState extends State<_OptionToggle> {
  bool _read() => widget.isServer
      ? mainGetBoolOptionSync(widget.optionKey)
      : mainGetLocalBoolOptionSync(widget.optionKey);

  Future<void> _write(bool shown) async {
    final value = widget.reverse ? !shown : shown;
    if (widget.isServer) {
      await mainSetBoolOption(widget.optionKey, value);
    } else {
      await mainSetLocalBoolOption(widget.optionKey, value);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var value = _read();
    if (widget.reverse) value = !value;
    var enabled = widget.enabled && !isOptionFixed(widget.optionKey);
    if (widget.fakeValue != null) {
      value = widget.fakeValue!;
      enabled = false;
    }
    return _ToggleRow(
      label: widget.label,
      value: value,
      onChanged: enabled ? _write : null,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ToggleRow(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? () => onChanged!(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: enabled ? NiTheme.text2 : NiTheme.muted)),
            ),
            Switch(
              value: value,
              activeColor: NiTheme.accent,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioRow<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String label;
  final ValueChanged<T>? onChanged;

  const _RadioRow({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? () => onChanged!(value) : null,
      child: Row(
        children: [
          Radio<T>(
            value: value,
            groupValue: groupValue,
            activeColor: NiTheme.accent,
            onChanged: enabled
                ? (v) {
                    if (v != null) onChanged!(v);
                  }
                : null,
          ),
          Expanded(
            child: Text(label,
                style:
                    TextStyle(color: enabled ? NiTheme.text2 : NiTheme.muted)),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onSelected;

  const _Choice(
      {required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: NiTheme.accentStrong,
      backgroundColor: NiTheme.surface2,
      disabledColor: NiTheme.surface2,
      side: const BorderSide(color: NiTheme.border),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
          color: selected
              ? Colors.white
              : (onSelected == null ? NiTheme.muted : NiTheme.text2)),
      onSelected: onSelected == null ? null : (_) => onSelected!(),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const _SecondaryButton(
      {required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: NiTheme.accent,
        disabledForegroundColor: NiTheme.muted,
        side: const BorderSide(color: NiTheme.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
        textStyle: const TextStyle(
            fontFamily: _kFont,
            fontFamilyFallback: _kFontFallback,
            fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final Color color;
  final String text;

  const _InfoBanner({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: NiTheme.text2, fontSize: 13))),
        ],
      ),
    );
  }
}
