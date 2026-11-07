part of 'tech_home.dart';

/// Historial de sesiones salientes. El cliente no registra fecha ni duración
/// de cada sesión: la lista es la de recientes (ordenada por la última vez
/// que se usó cada equipo) más el último ID al que se conectó.
class _HistorySection extends StatefulWidget {
  final List<Peer> peers;
  final Set<String> favIds;
  final void Function(String id, {bool forceRelay}) onConnect;
  final ValueChanged<String> onToggleFav;
  final ValueChanged<Peer> onEditAlias;

  const _HistorySection({
    required this.peers,
    required this.favIds,
    required this.onConnect,
    required this.onToggleFav,
    required this.onEditAlias,
  });

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  String _lastId = '';
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _loadLastId();
  }

  Future<void> _loadLastId() async {
    final id = await bind.mainGetLastRemoteId();
    if (mounted) setState(() => _lastId = id);
  }

  Future<void> _remove(Peer peer) async {
    final name = peer.alias.isNotEmpty ? peer.alias : formatID(peer.id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NiTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kRadiusLarge),
            side: const BorderSide(color: NiTheme.border)),
        title: const Text('Quitar del historial',
            style: TextStyle(color: NiTheme.text, fontWeight: FontWeight.w700)),
        content: Text(
            '¿Quitar «$name» del historial? Se borrarán también su nombre y sus ajustes guardados.',
            style: const TextStyle(color: NiTheme.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:
                const Text('Cancelar', style: TextStyle(color: NiTheme.text2)),
          ),
          _AccentButton(
            label: 'Quitar',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await bind.mainRemovePeer(id: peer.id);
    bind.mainLoadRecentPeers();
    bind.mainLoadFavPeers();
  }

  bool _matches(Peer p) {
    if (_filter.isEmpty) return true;
    final q = _filter.toLowerCase();
    return p.id.contains(q.replaceAll(' ', '')) ||
        p.alias.toLowerCase().contains(q) ||
        p.hostname.toLowerCase().contains(q) ||
        p.username.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final peers = widget.peers.where(_matches).toList();
    final pending = gFFI.recentPeersModel.restPeerIds.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial de sesiones',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
              'Equipos a los que te has conectado, del más reciente al más antiguo. NiSoporte no guarda la fecha ni la duración de cada sesión.',
              style: TextStyle(color: NiTheme.muted)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: NiTheme.text),
                  cursorColor: NiTheme.accent,
                  decoration: _inputDecoration('Buscar por nombre, ID o equipo')
                      .copyWith(
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: NiTheme.muted)),
                  onChanged: (v) => setState(() => _filter = v.trim()),
                ),
              ),
              if (_lastId.isNotEmpty) ...[
                const SizedBox(width: 14),
                _SecondaryButton(
                  label: 'Repetir última: ${formatID(_lastId)}',
                  icon: Icons.replay_rounded,
                  onPressed: () => widget.onConnect(_lastId),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (widget.peers.isEmpty)
            const _EmptyHint(text: 'Todavía no hay sesiones en el historial.')
          else if (peers.isEmpty)
            const _EmptyHint(text: 'Ningún equipo coincide con la búsqueda.')
          else
            Container(
              decoration: _cardDecoration(),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < peers.length; i++) ...[
                    if (i > 0)
                      const Divider(
                          height: 1, thickness: 1, color: NiTheme.border),
                    _HistoryRow(
                      peer: peers[i],
                      position: widget.peers.indexOf(peers[i]) + 1,
                      isFav: widget.favIds.contains(peers[i].id),
                      onConnect: () => widget.onConnect(peers[i].id,
                          forceRelay: peers[i].forceAlwaysRelay),
                      onFiles: () => connect(context, peers[i].id,
                          isFileTransfer: true,
                          forceRelay: peers[i].forceAlwaysRelay),
                      onToggleFav: () => widget.onToggleFav(peers[i].id),
                      onEditAlias: () => widget.onEditAlias(peers[i]),
                      onRemove: () => _remove(peers[i]),
                    ),
                  ],
                ],
              ),
            ),
          if (pending > 0) ...[
            const SizedBox(height: 10),
            Text('Cargando $pending equipos más…',
                style: const TextStyle(color: NiTheme.muted, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatefulWidget {
  final Peer peer;
  final int position;
  final bool isFav;
  final VoidCallback onConnect;
  final VoidCallback onFiles;
  final VoidCallback onToggleFav;
  final VoidCallback onEditAlias;
  final VoidCallback onRemove;

  const _HistoryRow({
    required this.peer,
    required this.position,
    required this.isFav,
    required this.onConnect,
    required this.onFiles,
    required this.onToggleFav,
    required this.onEditAlias,
    required this.onRemove,
  });

  @override
  State<_HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<_HistoryRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final peer = widget.peer;
    final title = peer.alias.isNotEmpty ? peer.alias : 'Sin nombre';
    final subtitle = [peer.hostname, peer.username, peer.platform]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    final duration =
        MediaQuery.of(context).disableAnimations ? Duration.zero : _kAnim;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: duration,
        color: _hover ? NiTheme.surface2 : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text('${widget.position}',
                  style: const TextStyle(color: NiTheme.muted, fontSize: 12)),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: peer.alias.isNotEmpty
                              ? NiTheme.text
                              : NiTheme.muted)),
                  const SizedBox(height: 2),
                  Text(formatID(peer.id),
                      style: _monoStyle.copyWith(
                          fontSize: 13, color: NiTheme.text2)),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(subtitle.isEmpty ? '—' : subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: NiTheme.muted, fontSize: 12)),
            ),
            if (peer.forceAlwaysRelay)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: 'Siempre por relay',
                  child: Icon(Icons.alt_route_rounded,
                      size: 18, color: NiTheme.muted),
                ),
              ),
            _rowIcon(
                widget.isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                widget.isFav ? 'Quitar de favoritos' : 'Añadir a favoritos',
                widget.onToggleFav,
                color: widget.isFav ? NiTheme.warning : NiTheme.muted),
            _rowIcon(Icons.edit_rounded, 'Cambiar nombre', widget.onEditAlias),
            _rowIcon(Icons.folder_open_rounded, 'Transferir archivos',
                widget.onFiles),
            _rowIcon(Icons.delete_outline_rounded, 'Quitar del historial',
                widget.onRemove),
            const SizedBox(width: 8),
            _AccentButton(label: 'Conectar', onPressed: widget.onConnect),
          ],
        ),
      ),
    );
  }

  Widget _rowIcon(IconData icon, String tooltip, VoidCallback onPressed,
      {Color color = NiTheme.muted}) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      onPressed: onPressed,
      icon: Icon(icon, size: 19, color: color),
    );
  }
}
