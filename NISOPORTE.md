# NiSoporte sobre RustDesk 1.5.1

Implementación local de las secciones 1 (nombre/metadatos), 2, 3, 4 y 5 de `../MAPA-FORK.md`. Rama `nisoporte`, base `23e5bb471a040d62f0a6ad52591fb30784265b73` (tag `1.5.1`). No se han usado red, despliegues, instalaciones ni generación del bridge.

## Configuración y variantes

La compilación Rust admite `NISOPORTE_VARIANT=CLIENTE` o `NISOPORTE_VARIANT=TECNICO`, mediante `option_env!` en `hbb_common::config`. Sin variable se obtiene CLIENTE; una cadena vacía u otro valor hace fallar la evaluación constante. El build script declara la dependencia del entorno y del proto. No se consulta esa variable durante la ejecución.

Ambas variantes se llaman NiSoporte, con empresa NiRepair y atribución upstream conservada. El runner y el payload Flutter se llaman `NiSoporte.exe`; los nombres del crate, la DLL y sus símbolos permanecen compatibles. No se han cambiado imágenes ni iconos.

Rendezvous fijo: `soporte.nirepair.es:21116`. Relay fijo: `soporte.nirepair.es:21117`. La clave pública está en `libs/hbb_common/src/config.rs`. Los getters y mapas de sobrescritura impiden reemplazarlos con opciones heredadas, licencias en el nombre del EXE o configuración comercial. Las conexiones que seleccionan otro servidor se rechazan; el técnico conserva la conexión directa por IP.

CLIENTE usa `incoming`, oculta ajustes/instalación y rechaza conexiones salientes en Rust, también por CLI/URI y switch-back. TÉCNICO mantiene la recepción, control saliente, transferencia, recientes/favoritos locales y túneles. La inversión que necesita el servicio API `switch-grant` queda desactivada en ambos: se oculta la acción y se rechazan sus entradas Rust. Se conservan firmas, cifrado, protocolo remoto y mecanismos de autenticación local.

Ambos desactivan cuentas/libretas/grupos y registro HTTP de dispositivos, conservando el registro de ID ante hbbs. No se deriva API 21114; no se arranca heartbeat/inventario; se retiraron proxy API TCP, heartbeat de cuenta y consumo de contraseña/identidad de cuenta. El módulo `account.rs` permanece en disco como código upstream sin inclusión en el producto; las firmas FFI conservadas no lanzan autenticación/despliegue. La subida API de grabaciones está inactiva; la grabación local se conserva. HTTP ordinario, SOCKS y túneles siguen disponibles para sus usos ajenos a cuentas.

Los getters locales siempre ignoran `access_token`/`user_info`; la inicialización Flutter los limpia mediante setters, junto a `verifier`, y sobrescribe las cachés Ab/Group con contenido vacío sin consultar sus valores. La interfaz no inicia el temporizador Ab ni carga cachés de cuenta. El modelo de usuario queda compatible y sin peticiones. Las entradas HTTP de cuenta fallan explícitamente. Las actualizaciones originales de RustDesk están desactivadas; su tarjeta queda oculta por la identidad de cliente personalizado.

El idioma inicial es español; TÉCNICO conserva la elección explícita del usuario. La bienvenida española cambia según la variante y no presupone una sesión conectada.

## Fuentes del antiguo submódulo

Se incorporan al repositorio padre las fuentes de `hbb_common` del commit `fae47e024dd83cef6aaecde0aa7d11731df11649`, para que el parche incluya la configuración modificada sin necesitar un fork remoto. Se sustituye el gitlink y se vacía `.gitmodules`. No hay cambio de dependencias Rust.

No se incorporan fixtures PEM ni las pruebas TLS de proxy que los incluyen; su módulo deja de declararse. No se leyeron ni copiaron esas claves/certificados. Los ficheros locales anteriores del submódulo, incluido su puntero `.git`, se conservan; operar con Git desde la raíz del proyecto. El parche contiene las fuentes necesarias, no un gitlink a un commit exclusivamente local. Para aplicarlo a otro árbol, usar la base 1.5.1 con el directorio del submódulo sin poblar; no se ha probado aplicarlo encima de un submódulo ya inicializado.

## Verificación realizada y límites

- Parseo de los tres TOML afectados y del Python de empaquetado: correcto.
- Base64 de la clave pública: formato válido, 32 bytes; no prueba que coincida con el servidor.
- Equilibrio de delimitadores de los Rust modificados: correcto. Es una comprobación textual, no compilación ni análisis de tipos.
- Inspección de referencias: sin consumidores activos del proxy API, `hc_connection`, arranque de sincronización HTTP ni `register_switch_grant`; `account` ya no se incluye. Sin modificaciones de iconos/binarios y sin fixtures PEM en el parche.
- `git diff --check a4e628c`: correcto para los cambios del producto. Contra 1.5.1 aparecen cuatro avisos de espacios finales que ya traía el proto vendorizado (líneas 31, 32, 92 y 237); se mantienen las fuentes upstream sin limpieza de formato.
- Parche contrastado en un índice Git alternativo contra el tag 1.5.1, comprobando que reconstruye exactamente el árbol final.
- Se añaden tres pruebas Rust: servidor fijo, política de variante/cuentas y ausencia de derivación API. No se han ejecutado.
- Intentos para CLIENTE y TECNICO: `CARGO_NET_OFFLINE=true cargo check --offline --locked -p hbb_common`. Ambos terminan con código 127: `cargo: command not found`. Tampoco hay `rustc`, `rustfmt`, Dart ni Flutter disponibles en PATH. No se han instalado.

NO verificado: compilación/análisis de tipos Rust y Dart, rechazo real de variantes inválidas por el compilador, ejecución de pruebas unitarias, empaquetado/recursos EXE/MSI, interfaz Windows (anchura y altura de bienvenida), instalación/servicio/bandeja, limpieza real de configuración heredada, sesiones directas/relay/transferencias/túneles, compatibilidad de hbbs, correspondencia real de la clave y captura de tráfico que confirme ausencia de API/proxy. No se ha reproducido `Failed to secure tcp` ni se afirma resolver cualquier fallo de handshake.

En el workflow existente solo se adaptan nombres/rutas del payload y salidas Windows y el nombre pasado al preprocesador MSI. Se mantienen los identificadores internos de artefactos para sus consumidores. No se implementa la sección 6, no se crea una matriz de variantes ni se ejecuta ese workflow. El workflow upstream todavía contiene firma/publicación y otras plataformas; preparar el workflow específico de la sección 6 queda para un encargo posterior.

## Superficie de regresión

- `libs/hbb_common/{src/config.rs,build.rs}`: identidad, servidor, opciones inmutables, idioma y variante. Es necesario para aplicar restricciones en todos los procesos Rust y antes de cargar configuración de usuario. La vendorización del resto conserva su comportamiento, salvo excluir pruebas que requieren PEM.
- `src/common.rs`: resolución de servidor/clave, API, transporte HTTP y personalización/actualizador upstream; se retiran los caminos que podían contradecir el servidor fijo o iniciar llamadas de cuenta/actualización.
- `src/client.rs`, `src/ui_session_interface.rs`, `src/server/connection.rs`, `src/ipc.rs`: inicio/autenticación de sesiones, identidad local e inversión. Es necesario para ignorar tokens/cachés y hacer efectivo el rol CLIENTE fuera de la interfaz, y para cerrar switch-grant en ambos productos.
- `src/client/io_loop.rs`, `src/port_forward.rs`: se retiran únicamente llamadas al heartbeat de cuenta; los bucles de sesión/túnel se conservan.
- `src/hbbs_http.rs`, `src/hbbs_http/{sync.rs,record_upload.rs}`, `src/rendezvous_mediator.rs`: se retiran inclusión de cuenta, sincronización y subida API; queda un canal de notificaciones inerte compatible con los receptores existentes, sin hilo ni temporizador. El mediador mantiene su arranque restante.
- `src/core_main.rs`, `src/ui_interface.rs`, `src/flutter_ffi.rs`: entradas CLI/FFI de cuenta/despliegue e inicialización que limpia datos heredados; se mantienen firmas compartidas.
- `libs/base/src/config/keys.rs`: se retira la opción sin consumidores del proxy API.
- Dart `models/{user_model,ab_model,group_model}.dart`, `utils/http_service.dart`, `common/widgets/{login,toolbar,dialog}.dart`, `desktop/pages/desktop_home_page.dart`: bloqueo de cuentas y cachés, menú CLIENTE e inversión ligada a API; los paneles existentes incoming-only se reutilizan.
- `src/lang/es.rs`: título y bienvenida solicitados por variante; no se modifica el resto de traducciones.
- `Cargo.toml`, `libs/portable/Cargo.toml`, `flutter/windows/{CMakeLists.txt,runner/main.cpp,runner/Runner.rc}`, `build.py`, `.github/workflows/flutter-build.yml`: nombre/metadatos y rutas de empaquetado necesarias tras renombrar el EXE Flutter.

No se han modificado captura, codecs, entrada ni criptografía de sesión. Ambos productos comparten identidad/configuración/servicio y no están diseñados para instalarse de forma independiente en el mismo equipo.

## Ficheros cambiados respecto a 1.5.1

- `.github/workflows/flutter-build.yml`
- `.gitmodules`
- `Cargo.toml`
- `build.py`
- `flutter/lib/common/widgets/dialog.dart`
- `flutter/lib/common/widgets/login.dart`
- `flutter/lib/common/widgets/toolbar.dart`
- `flutter/lib/desktop/pages/desktop_home_page.dart`
- `flutter/lib/models/ab_model.dart`
- `flutter/lib/models/group_model.dart`
- `flutter/lib/models/user_model.dart`
- `flutter/lib/utils/http_service.dart`
- `flutter/windows/CMakeLists.txt`
- `flutter/windows/runner/Runner.rc`
- `flutter/windows/runner/main.cpp`
- `libs/base/src/config/keys.rs`
- `libs/hbb_common`
- `libs/hbb_common/.gitignore`
- `libs/hbb_common/Cargo.toml`
- `libs/hbb_common/build.rs`
- `libs/hbb_common/examples/config.rs`
- `libs/hbb_common/examples/webrtc.rs`
- `libs/hbb_common/examples/webrtc_echo.rs`
- `libs/hbb_common/protos/rendezvous.proto`
- `libs/hbb_common/src/bytes_codec.rs`
- `libs/hbb_common/src/compress.rs`
- `libs/hbb_common/src/config.rs`
- `libs/hbb_common/src/config/permanent_password.rs`
- `libs/hbb_common/src/fingerprint.rs`
- `libs/hbb_common/src/lib.rs`
- `libs/hbb_common/src/log_throttle.rs`
- `libs/hbb_common/src/mem.rs`
- `libs/hbb_common/src/password_security.rs`
- `libs/hbb_common/src/protos/mod.rs`
- `libs/hbb_common/src/proxy.rs`
- `libs/hbb_common/src/rx_probe.rs`
- `libs/hbb_common/src/sh.rs`
- `libs/hbb_common/src/socket_client.rs`
- `libs/hbb_common/src/stream.rs`
- `libs/hbb_common/src/tcp.rs`
- `libs/hbb_common/src/tls.rs`
- `libs/hbb_common/src/udp.rs`
- `libs/hbb_common/src/verifier.rs`
- `libs/hbb_common/src/webrtc.rs`
- `libs/hbb_common/src/websocket.rs`
- `libs/portable/Cargo.toml`
- `src/client.rs`
- `src/client/io_loop.rs`
- `src/common.rs`
- `src/core_main.rs`
- `src/flutter_ffi.rs`
- `src/hbbs_http.rs`
- `src/hbbs_http/record_upload.rs`
- `src/hbbs_http/sync.rs`
- `src/ipc.rs`
- `src/lang/es.rs`
- `src/port_forward.rs`
- `src/rendezvous_mediator.rs`
- `src/server/connection.rs`
- `src/ui_interface.rs`
- `src/ui_session_interface.rs`
- `NISOPORTE.md` (este informe).

Entrega externa autorizada: `../nisoporte.patch`, generado con `git diff --binary 1.5.1 HEAD`.
