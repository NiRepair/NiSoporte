import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/common/widgets/dialog.dart'
    show checkUnlockPinDialog;
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/desktop_home_page.dart'
    show setPasswordDialog;
import 'package:flutter_hbb/models/peer_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:flutter_hbb/nisoporte/theme.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'about.dart';

part 'tech_lan.dart';
part 'tech_history.dart';
part 'tech_my_device.dart';
part 'tech_settings.dart';

const _kFont = 'Segoe UI Variable';
const _kFontFallback = ['Segoe UI'];
const _kMono = 'Cascadia Mono';
const _kMonoFallback = ['Consolas', 'monospace'];
const double _kRadius = 16;
const double _kRadiusLarge = 20;
const _kAnim = Duration(milliseconds: 180);

enum _TechSection {
  connect,
  recents,
  favorites,
  lan,
  history,
  myDevice,
  settings
}

enum _ServerState { connecting, ready, offline }

/// Pantalla principal de la variante TÉCNICO.
class NiTechHome extends StatefulWidget {
  const NiTechHome({Key? key}) : super(key: key);

  @override
  State<NiTechHome> createState() => _NiTechHomeState();
}

class _NiTechHomeState extends State<NiTechHome> {
  _TechSection _section = _TechSection.connect;
  _ServerState _server = _ServerState.connecting;
  Set<String> _favIds = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    gFFI.recentPeersModel.addListener(_onPeersChanged);
    gFFI.favoritePeersModel.addListener(_onPeersChanged);
    gFFI.lanPeersModel.addListener(_onPeersChanged);
    bind.mainLoadRecentPeers();
    bind.mainLoadFavPeers();
    _reloadFavIds();
    _timer = periodic_immediate(const Duration(seconds: 1), _poll);
  }

  @override
  void dispose() {
    _timer?.cancel();
    gFFI.recentPeersModel.removeListener(_onPeersChanged);
    gFFI.favoritePeersModel.removeListener(_onPeersChanged);
    gFFI.lanPeersModel.removeListener(_onPeersChanged);
    super.dispose();
  }

  void _onPeersChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _poll() async {
    await gFFI.serverModel.fetchID();
    final status =
        jsonDecode(await bind.mainGetConnectStatus()) as Map<String, dynamic>;
    final statusNum = status['status_num'];
    final next = statusNum == 1
        ? _ServerState.ready
        : statusNum == 0
            ? _ServerState.connecting
            : _ServerState.offline;
    if (mounted && next != _server) setState(() => _server = next);
  }

  Future<void> _reloadFavIds() async {
    final favs = await bind.mainGetFav();
    if (mounted) setState(() => _favIds = favs.toSet());
  }

  Future<void> _toggleFav(String id) async {
    final favs = (await bind.mainGetFav()).toList();
    if (favs.contains(id)) {
      favs.remove(id);
    } else {
      favs.add(id);
    }
    await bind.mainStoreFav(favs: favs);
    bind.mainLoadFavPeers();
    await _reloadFavIds();
  }

  Future<void> _editAlias(Peer peer) async {
    final controller = TextEditingController(text: peer.alias);
    final alias = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NiTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kRadiusLarge),
            side: const BorderSide(color: NiTheme.border)),
        title: const Text('Nombre del equipo',
            style: TextStyle(color: NiTheme.text, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: NiTheme.text),
          decoration: _inputDecoration('Por ejemplo: Portátil de Marta'),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar',
                style: TextStyle(color: NiTheme.text2)),
          ),
          _AccentButton(
            label: 'Guardar',
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          ),
        ],
      ),
    );
    if (alias == null || alias == peer.alias) return;
    await bind.mainSetPeerAlias(id: peer.id, alias: alias);
    bind.mainLoadRecentPeers();
    bind.mainLoadFavPeers();
  }

  void _connectTo(String id, {bool forceRelay = false}) {
    if (id.isEmpty) return;
    connect(context, id, forceRelay: forceRelay);
  }

  @override
  Widget build(BuildContext context) {
    final duration =
        MediaQuery.of(context).disableAnimations ? Duration.zero : _kAnim;
    return DefaultTextStyle.merge(
      style: const TextStyle(
          fontFamily: _kFont,
          fontFamilyFallback: _kFontFallback,
          color: NiTheme.text),
      child: Container(
        color: NiTheme.background,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              selected: _section,
              onSelect: (s) => setState(() => _section = s),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 20, 24, 0),
                    child: Row(
                      children: [
                        const Spacer(),
                        _ServerPill(state: _server),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: duration,
                      layoutBuilder: _fillLayout,
                      child: KeyedSubtree(
                        key: ValueKey(_section),
                        child: _buildSection(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection() {
    switch (_section) {
      case _TechSection.connect:
        return _ConnectSection(
          recents: gFFI.recentPeersModel.peers,
          favIds: _favIds,
          onConnect: _connectTo,
          onToggleFav: _toggleFav,
          onEditAlias: _editAlias,
          onShowAllRecents: () =>
              setState(() => _section = _TechSection.recents),
        );
      case _TechSection.recents:
        return _PeerListSection(
          title: 'Recientes',
          emptyText:
              'Aún no te has conectado a ningún equipo. Las conexiones aparecerán aquí, la más reciente primero.',
          peers: gFFI.recentPeersModel.peers,
          favIds: _favIds,
          onConnect: _connectTo,
          onToggleFav: _toggleFav,
          onEditAlias: _editAlias,
        );
      case _TechSection.favorites:
        return _PeerListSection(
          title: 'Favoritos',
          emptyText:
              'Marca un equipo con la estrella para tenerlo siempre a mano.',
          peers: gFFI.favoritePeersModel.peers,
          favIds: _favIds,
          onConnect: _connectTo,
          onToggleFav: _toggleFav,
          onEditAlias: _editAlias,
        );
      case _TechSection.lan:
        return _LanSection(
          peers: gFFI.lanPeersModel.peers,
          favIds: _favIds,
          onConnect: _connectTo,
          onToggleFav: _toggleFav,
        );
      case _TechSection.history:
        return _HistorySection(
          peers: gFFI.recentPeersModel.peers,
          favIds: _favIds,
          onConnect: _connectTo,
          onToggleFav: _toggleFav,
          onEditAlias: _editAlias,
        );
      case _TechSection.myDevice:
        return _MyDeviceSection(
          server: _server,
          onOpenSecurity: () =>
              setState(() => _section = _TechSection.settings),
        );
      case _TechSection.settings:
        return const _SettingsSection();
    }
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: NiTheme.muted),
      filled: true,
      fillColor: NiTheme.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: NiTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: NiTheme.accent, width: 2),
      ),
    );

BoxDecoration _cardDecoration({Color color = NiTheme.surface}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(_kRadiusLarge),
      border: Border.all(color: NiTheme.border),
    );

const _monoStyle = TextStyle(
  fontFamily: _kMono,
  fontFamilyFallback: _kMonoFallback,
  letterSpacing: 1.5,
);

void _copy(String value) {
  if (value.isEmpty || value == '-') return;
  Clipboard.setData(ClipboardData(text: value));
  showToast('Copiado');
}

// ---------------------------------------------------------------- sidebar

class _Sidebar extends StatelessWidget {
  final _TechSection selected;
  final ValueChanged<_TechSection> onSelect;

  const _Sidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: NiTheme.surface,
        border: Border(right: BorderSide(color: NiTheme.border)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              loadIcon(36),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NiSoporte',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('Técnico',
                        style: TextStyle(color: NiTheme.muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _navItem(_TechSection.connect, Icons.cast_connected_rounded,
              'Conectar'),
          _navItem(_TechSection.recents, Icons.history_rounded, 'Recientes'),
          _navItem(_TechSection.favorites, Icons.star_rounded, 'Favoritos'),
          _navItem(_TechSection.lan, Icons.lan_rounded, 'Red local'),
          _navItem(
              _TechSection.history, Icons.receipt_long_rounded, 'Historial'),
          _navItem(
              _TechSection.myDevice, Icons.verified_user_rounded, 'Mi equipo'),
          _navItem(_TechSection.settings, Icons.tune_rounded, 'Ajustes'),
          const Spacer(),
          const _MyDeviceCard(),
        ],
      ),
    );
  }

  Widget _navItem(_TechSection section, IconData icon, String label) {
    final isSelected = section == selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? NiTheme.surface2 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelect(section),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: isSelected ? NiTheme.accent : NiTheme.muted),
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? NiTheme.text : NiTheme.text2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyDeviceCard extends StatelessWidget {
  const _MyDeviceCard();

  @override
  Widget build(BuildContext context) {
    final model = gFFI.serverModel;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(color: NiTheme.surface2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mi equipo',
              style: TextStyle(
                  color: NiTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: model.serverId,
            builder: (_, v, __) => _miniRow('ID', v.text),
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: model.serverPasswd,
            builder: (_, v, __) => _miniRow('Clave', v.text),
          ),
        ],
      ),
    );
  }

  Widget _miniRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label,
              style: const TextStyle(color: NiTheme.muted, fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              style: _monoStyle.copyWith(
                  fontSize: 13, color: NiTheme.text, letterSpacing: 0.5)),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _copy(value),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.copy_rounded, size: 15, color: NiTheme.muted),
          ),
        ),
      ],
    );
  }
}

class _ServerPill extends StatelessWidget {
  final _ServerState state;

  const _ServerPill({required this.state});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (state) {
      _ServerState.ready => (NiTheme.success, 'Servidor NiRepair: conectado'),
      _ServerState.connecting => (NiTheme.warning, 'Servidor NiRepair: conectando…'),
      _ServerState.offline => (NiTheme.error, 'Servidor NiRepair: sin conexión'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: NiTheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: NiTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, color: NiTheme.text2)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- connect

class _ConnectSection extends StatefulWidget {
  final List<Peer> recents;
  final Set<String> favIds;
  final void Function(String id, {bool forceRelay}) onConnect;
  final ValueChanged<String> onToggleFav;
  final ValueChanged<Peer> onEditAlias;
  final VoidCallback onShowAllRecents;

  const _ConnectSection({
    required this.recents,
    required this.favIds,
    required this.onConnect,
    required this.onToggleFav,
    required this.onEditAlias,
    required this.onShowAllRecents,
  });

  @override
  State<_ConnectSection> createState() => _ConnectSectionState();
}

class _ConnectSectionState extends State<_ConnectSection> {
  final _idController = IDTextEditingController();
  final _focusNode = FocusNode();
  bool _forceRelay = false;

  static const _maxRecentsHere = 6;

  @override
  void initState() {
    super.initState();
    _idController.addListener(_onIdChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _idController.removeListener(_onIdChanged);
    _idController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onIdChanged() => setState(() {});

  void _submit() =>
      widget.onConnect(_idController.id, forceRelay: _forceRelay);

  @override
  Widget build(BuildContext context) {
    final recents = widget.recents.take(_maxRecentsHere).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿A quién ayudamos hoy?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Escribe o pega el ID que te dicta el cliente.',
              style: TextStyle(color: NiTheme.muted)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idController,
                        focusNode: _focusNode,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.visiblePassword,
                        inputFormatters: [IDTextInputFormatter()],
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _submit(),
                        cursorColor: NiTheme.accent,
                        style: _monoStyle.copyWith(
                            fontSize: 30,
                            letterSpacing: 3,
                            color: NiTheme.text),
                        decoration: _inputDecoration('123 456 789').copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          hintStyle: _monoStyle.copyWith(
                              fontSize: 30,
                              letterSpacing: 3,
                              color: NiTheme.border),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      height: 66,
                      child: _AccentButton(
                        label: 'Conectar',
                        icon: Icons.arrow_forward_rounded,
                        large: true,
                        onPressed: _idController.id.isEmpty ? null : _submit,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Switch(
                      value: _forceRelay,
                      activeColor: NiTheme.accent,
                      onChanged: (v) => setState(() => _forceRelay = v),
                    ),
                    const SizedBox(width: 6),
                    const Text('Forzar relay',
                        style: TextStyle(color: NiTheme.text2)),
                    const SizedBox(width: 8),
                    const Tooltip(
                      message:
                          'Pasa la conexión por el servidor de NiRepair. Úsalo si la conexión directa falla.',
                      child: Icon(Icons.info_outline_rounded,
                          size: 16, color: NiTheme.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Text('Recientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (widget.recents.length > _maxRecentsHere)
                TextButton(
                  onPressed: widget.onShowAllRecents,
                  child: const Text('Ver todos',
                      style: TextStyle(color: NiTheme.accent)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (recents.isEmpty)
            const _EmptyHint(
                text: 'Aquí verás los equipos a los que te conectes.')
          else
            _PeerGrid(
              peers: recents,
              favIds: widget.favIds,
              onConnect: widget.onConnect,
              onToggleFav: widget.onToggleFav,
              onEditAlias: widget.onEditAlias,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- peers

class _PeerListSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<Peer> peers;
  final Set<String> favIds;
  final void Function(String id, {bool forceRelay}) onConnect;
  final ValueChanged<String> onToggleFav;
  final ValueChanged<Peer> onEditAlias;

  const _PeerListSection({
    required this.title,
    required this.emptyText,
    required this.peers,
    required this.favIds,
    required this.onConnect,
    required this.onToggleFav,
    required this.onEditAlias,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          if (peers.isEmpty)
            _EmptyHint(text: emptyText)
          else
            _PeerGrid(
              peers: peers,
              favIds: favIds,
              onConnect: onConnect,
              onToggleFav: onToggleFav,
              onEditAlias: onEditAlias,
            ),
        ],
      ),
    );
  }
}

class _PeerGrid extends StatelessWidget {
  final List<Peer> peers;
  final Set<String> favIds;
  final void Function(String id, {bool forceRelay}) onConnect;
  final ValueChanged<String> onToggleFav;
  final ValueChanged<Peer>? onEditAlias;

  const _PeerGrid({
    required this.peers,
    required this.favIds,
    required this.onConnect,
    required this.onToggleFav,
    this.onEditAlias,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: peers
          .map((p) => _PeerCard(
                peer: p,
                isFav: favIds.contains(p.id),
                onConnect: () =>
                    onConnect(p.id, forceRelay: p.forceAlwaysRelay),
                onToggleFav: () => onToggleFav(p.id),
                onEditAlias:
                    onEditAlias == null ? null : () => onEditAlias!(p),
              ))
          .toList(),
    );
  }
}

class _PeerCard extends StatefulWidget {
  final Peer peer;
  final bool isFav;
  final VoidCallback onConnect;
  final VoidCallback onToggleFav;
  final VoidCallback? onEditAlias;

  const _PeerCard({
    required this.peer,
    required this.isFav,
    required this.onConnect,
    required this.onToggleFav,
    this.onEditAlias,
  });

  @override
  State<_PeerCard> createState() => _PeerCardState();
}

class _PeerCardState extends State<_PeerCard> {
  bool _hover = false;

  IconData get _platformIcon {
    final platform = widget.peer.platform.toLowerCase();
    if (platform.contains('windows')) return Icons.desktop_windows_rounded;
    if (platform.contains('mac')) return Icons.laptop_mac_rounded;
    if (platform.contains('android') || platform.contains('ios')) {
      return Icons.phone_android_rounded;
    }
    return Icons.computer_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final peer = widget.peer;
    final hasAlias = peer.alias.isNotEmpty;
    final subtitle = [peer.hostname, peer.username]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    final duration =
        MediaQuery.of(context).disableAnimations ? Duration.zero : _kAnim;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
          duration: duration,
          width: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hover ? NiTheme.surface2 : NiTheme.surface,
            borderRadius: BorderRadius.circular(_kRadiusLarge),
            border: Border.all(
                color: _hover ? NiTheme.accent.withOpacity(0.5) : NiTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_platformIcon, size: 20, color: NiTheme.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: widget.onEditAlias,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              hasAlias ? peer.alias : 'Sin nombre',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: hasAlias
                                      ? NiTheme.text
                                      : NiTheme.muted),
                            ),
                          ),
                          if (widget.onEditAlias != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_rounded,
                                size: 13, color: NiTheme.muted),
                          ],
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: widget.isFav
                        ? 'Quitar de favoritos'
                        : 'Añadir a favoritos',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onToggleFav,
                    icon: Icon(
                      widget.isFav
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: widget.isFav ? NiTheme.warning : NiTheme.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(formatID(peer.id),
                  style: _monoStyle.copyWith(
                      fontSize: 20, color: NiTheme.text)),
              const SizedBox(height: 4),
              Text(subtitle.isEmpty ? ' ' : subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: NiTheme.muted, fontSize: 12)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: _AccentButton(
                  label: 'Conectar',
                  onPressed: widget.onConnect,
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Text(text, style: const TextStyle(color: NiTheme.muted)),
    );
  }
}

class _AccentButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool large;
  final VoidCallback? onPressed;

  const _AccentButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: NiTheme.accentStrong,
        foregroundColor: Colors.white,
        disabledBackgroundColor: NiTheme.surface2,
        disabledForegroundColor: NiTheme.muted,
        elevation: 0,
        padding: EdgeInsets.symmetric(
            horizontal: large ? 26 : 16, vertical: large ? 18 : 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kRadius)),
        textStyle: TextStyle(
            fontFamily: _kFont,
            fontFamilyFallback: _kFontFallback,
            fontWeight: FontWeight.w600,
            fontSize: large ? 16 : 14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 18),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- shared

// AnimatedSwitcher's default layout centers loosely; sections must fill.
Widget _fillLayout(Widget? current, List<Widget> previous) => Stack(
      fit: StackFit.expand,
      children: [...previous, if (current != null) current],
    );

class _SettingCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: NiTheme.text)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
