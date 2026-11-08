# CLIENTE: ventana de ayuda y permisos de Windows

La ventana del gestor de conexiones de CLIENTE deja de estar siempre al frente.
Durante una ayuda ocupa aproximadamente 320 × 150 píxeles, ofrece «Minimizar» y
«Terminar ayuda», y se minimiza automáticamente tres segundos después de aceptar.
Minimizar no cierra la conexión. Para terminar la ayuda, restaura la ventana desde
la barra de tareas o pulsa el icono de NiSoporte en la bandeja (también «Abrir»).
CLIENTE inicia la bandeja también cuando se ejecuta como portable, sin servicio
instalado. El gestor conserva su título nativo para que la bandeja lo encuentre.
Una nueva petición restaura el aviso de 440 × 490 y cancela la minimización
pendiente mientras haya solicitudes sin responder. Con varias sesiones activas,
los controles se pueden desplazar dentro de la ventana compacta.

El workflow `.github/workflows/nisoporte-windows.yml` añade, únicamente para
`matrix.variant == 'CLIENTE'`, `requestedExecutionLevel level="requireAdministrator"`
antes de compilar. Modifica en el checkout del runner estos manifiestos:

- `flutter/windows/runner/runner.exe.manifest`: ejecutable Flutter del payload.
- `res/manifest.xml`: manifiesto usado por `libs/portable/build.rs` para el portable.
- Cualquier `*.manifest` o `*manifest*.xml` dentro de `libs/portable`, si existe.

Actualmente los dos manifiestos no incluyen `requestedExecutionLevel`, así que el
paso crea el bloque `trustInfo/security/requestedPrivileges` cuando falta. TECNICO
no ejecuta este paso y conserva su comportamiento actual (asInvoker implícito).
Los manifiestos del árbol de trabajo no se cambian.

Al abrir CLIENTE en Windows aparecerá la solicitud de UAC de administrador. Si la
cuenta no es administradora, Windows pedirá credenciales de administrador; sin
aceptar la elevación, CLIENTE no se abre. La elevación permite operar con ventanas
con permisos elevados; el control del escritorio seguro de UAC debe comprobarse
en Windows con una conexión real antes de darlo por garantizado.

## Superficie de regresión

- `flutter/lib/main.dart`: solo el arranque del gestor CLIENTE deja de ser siempre
  al frente y reaparece sin el antiguo truco de minimizar/enfocar; el gestor de
  otras variantes mantiene su configuración.
- `flutter/lib/nisoporte/incoming_dialog.dart`: interfaz exclusiva de CLIENTE,
  tamaño compacto, minimizar y temporizador; mantiene el ciclo de cierre existente.
- `flutter/lib/models/server_model.dart`: CLIENTE solo pide el primer plano para
  solicitudes sin autorizar y deja su minimización al temporizador de su interfaz.
- `flutter/lib/desktop/pages/server_page.dart`: CLIENTE conserva el título nativo
  para localizar su gestor desde la bandeja; otras variantes conservan su título.
- `src/core_main.rs`: CLIENTE inicia la bandeja en Windows también sin instalación.
- `src/platform/windows.rs` y `src/tray.rs`: «Abrir» y el clic de bandeja restauran
  el gestor CLIENTE existente; si no existe, sigue abriéndose la ventana principal.
- `.github/workflows/nisoporte-windows.yml`: eleva únicamente los binarios CLIENTE;
  no cambia el proceso de compilación de TECNICO.

## Verificación pendiente en Windows

Sin SDK de Flutter ni compilador Rust/Windows local, quedan pendientes la
compilación, los tests Flutter, la ejecución de CI y la comprobación real de
minimizar/restaurar desde barra y bandeja, mantener la conexión, recibir una nueva
petición y aceptar/rechazar el aviso de UAC en los ejecutables finales.

## Comprobaciones locales realizadas

- Análisis del YAML con `CPAN::Meta::YAML`, disponible sin instalar paquetes
  (analizador limitado a un subconjunto de YAML; no sustituye a `actionlint`).
- Compilación y ejecución del Python extraído literalmente del paso de CI sobre
  copias temporales de ambos manifiestos y dos manifiestos opcionales de prueba.
  Se verificaron inserción, reemplazo de `asInvoker`, XML válido e idempotencia.
- Condición exclusiva de CLIENTE y posición del paso anterior a la compilación.
- Búsqueda de símbolos y llamadas con `rg` y comprobación `git diff --check`.
  Las API del plugin `window_manager` tienen llamadas existentes en el proyecto;
  no se pudieron contrastar sus definiciones sin el SDK y las dependencias.
