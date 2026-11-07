import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

class NiBrand extends StatelessWidget {
  const NiBrand({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Row(children: [
        Image.asset('assets/icon.png', width: 40, height: 40,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.build, size: 40, color: NiTheme.accent)),
        const SizedBox(width: 12),
        Expanded(
          child: const Text('NiSoporte',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
      ]);
}

class NiCard extends StatelessWidget {
  const NiCard({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: NiTheme.surface,
          border: Border.all(color: NiTheme.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      );
}

class NiStatus extends StatelessWidget {
  const NiStatus({Key? key, required this.status}) : super(key: key);

  final int status;

  @override
  Widget build(BuildContext context) {
    final color = status == 1
        ? NiTheme.success
        : status == 0
            ? NiTheme.warning
            : NiTheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 10),
        Text(
          status == 1
              ? 'Listo'
              : status == 0
                  ? 'Conectando…'
                  : 'Sin conexión',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

Future<void> niCopy(BuildContext context, String value) async {
  try {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copiado al portapapeles')));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido copiar. Inténtalo de nuevo.')));
  }
}

class NiContact extends StatelessWidget {
  const NiContact({Key? key}) : super(key: key);

  Future<void> _open(BuildContext context, String address) async {
    try {
      if (await launchUrl(Uri.parse(address))) return;
    } catch (_) {
      // A missing desktop URL handler is reported with the same useful message.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No se ha podido abrir WhatsApp. Inténtalo de nuevo.')));
  }

  @override
  Widget build(BuildContext context) => TextButton(
        style: TextButton.styleFrom(foregroundColor: NiTheme.muted),
        onPressed: () => _open(context, 'https://wa.me/34630224731'),
        child: const Text('WhatsApp 630 22 47 31'),
      );
}

class NiSessionBanner extends StatelessWidget {
  const NiSessionBanner({Key? key, required this.onEnd}) : super(key: key);

  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => NiCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('NiRepair te está ayudando',
              style: TextStyle(color: NiTheme.success, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: NiTheme.error),
            onPressed: onEnd,
            child: const Text('Terminar ayuda'),
          ),
        ]),
      );
}
