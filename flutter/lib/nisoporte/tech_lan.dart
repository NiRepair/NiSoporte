part of 'tech_home.dart';

/// Equipos descubiertos en la red local (`gFFI.lanPeersModel`), igual que la
/// pestaña de descubrimiento original: carga la lista guardada y lanza una
/// búsqueda nueva al entrar y al pulsar «Buscar de nuevo».
class _LanSection extends StatefulWidget {
  final List<Peer> peers;
  final Set<String> favIds;
  final void Function(String id, {bool forceRelay}) onConnect;
  final ValueChanged<String> onToggleFav;

  const _LanSection({
    required this.peers,
    required this.favIds,
    required this.onConnect,
    required this.onToggleFav,
  });

  @override
  State<_LanSection> createState() => _LanSectionState();
}

class _LanSectionState extends State<_LanSection> {
  bool _searching = false;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _startSearch();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  void _discover() => setState(_startSearch);

  void _startSearch() {
    bind.mainLoadLanPeers();
    bind.mainDiscover();
    _searchTimer?.cancel();
    _searching = true;
    _searchTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _searching = false);
      bind.mainLoadLanPeers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lanDiscoveryDenied =
        !mainGetBoolOptionSync(kOptionEnableLanDiscovery);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Equipos de la red local',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              ),
              _SecondaryButton(
                label: _searching ? 'Buscando…' : 'Buscar de nuevo',
                icon: Icons.refresh_rounded,
                onPressed: _searching ? null : _discover,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
              'Equipos con NiSoporte abiertos en tu misma red (Wi-Fi o cable).',
              style: TextStyle(color: NiTheme.muted)),
          if (lanDiscoveryDenied) ...[
            const SizedBox(height: 12),
            const _InfoBanner(
              color: NiTheme.warning,
              text:
                  'Este equipo no se anuncia en la red local («Denegar descubrimiento en red local» en Ajustes › Seguridad). Aun así puedes ver a los demás.',
            ),
          ],
          const SizedBox(height: 20),
          if (widget.peers.isEmpty)
            _EmptyHint(
                text: _searching
                    ? 'Buscando equipos en la red…'
                    : 'No se ha encontrado ningún equipo en la red local.')
          else
            _PeerGrid(
              peers: widget.peers,
              favIds: widget.favIds,
              onConnect: widget.onConnect,
              onToggleFav: widget.onToggleFav,
            ),
        ],
      ),
    );
  }
}
