# Auditoría de referencias retiradas en NiSoporte

Fecha: 2026-11-07. Comparación: `1.5.1..935f434` y correcciones de esta auditoría.
Revisión estática, sin red. Se excluye `flutter/lib/nisoporte/`, reservada a otro agente.

## Método y resultado

Se inventariaron las declaraciones en las líneas retiradas del diff de `src/` y
`flutter/lib/`, distinguiendo eliminaciones de sustituciones por stubs. Se buscó
cada nombre con `rg -w` en los fuentes Rust, Dart y proto de `src/`, `libs/` y
`flutter/`, incluidos tests y código condicionado por plataforma/features. Para
los nombres comunes se comprobaron el propietario y las rutas calificadas; una
coincidencia textual con otro propietario no implica una referencia rota.
También se compararon los árboles de imports, se buscaron sus identificadores y
se revisaron los usos en los antiguos módulos propietarios.

El tag contiene `libs/hbb_common` como gitlink, no como fuentes ordinarios. Su
base real es `fae47e024dd83cef6aaecde0aa7d11731df11649`, disponible en el repositorio
local de esa carpeta. Se comparó ese commit con los fuentes integrados actuales
mediante `git -C libs/hbb_common diff <base> -- src protos`. Solo cambian
`src/config.rs` y `src/websocket.rs`; el esquema protobuf no cambia.

No se encontraron nuevas referencias sin definición después de `364611b` en el
alcance inspeccionado. Sí se corrigieron imports y enlaces locales sin uso que
dejaron las retiradas. Una búsqueda textual no sustituye al compilador.

## Inventario Rust

Cada nombre de las siguientes listas se buscó individualmente.

| Propietario | Declaraciones eliminadas | Resultado |
| --- | --- | --- |
| `src/client.rs` | `is_switch_sides_back` (ambas variantes cfg), `try_get_password_from_personal_ab`, `hc_connection`, `hc_connection_` | Sin referencias restantes. |
| `src/common.rs` | `get_api_server_`, `should_use_raw_tcp_for_api`, `can_fallback_to_raw_tcp`, `should_use_tcp_proxy_for_api_url`, `is_tcp_proxy_api_target`, `tcp_proxy_log_target`, `get_tcp_proxy_addr`, `tcp_proxy_request`, `parse_simple_header`, `post_request_via_tcp_proxy`, `http_proxy_response_to_json`, `parse_json_header_entries`, `with_tcp_proxy_fallback`, `post_request_via_tcp_proxy_status`, `http_request_via_tcp_proxy`, `secure_tcp_silent`, `read_custom_client_advanced_settings` | Sin referencias restantes. El uso de `parse_json_header_entries` ya fue sustituido por parseo JSON directo en `364611b`. |
| `src/common.rs::read_custom_client` | Constante local `KEY` | Desaparece junto con su bloque; las coincidencias `KEY` restantes pertenecen al código de teclado. |
| `src/common.rs::tests` | `test_api_server_from_bare_ipv6_rendezvous_server`, `test_should_use_tcp_proxy_for_api_url`, `test_parse_simple_header_preserves_non_content_type_header`, `test_http_proxy_response_to_json` | Sin referencias restantes. |
| `src/hbbs_http.rs` | Declaración de módulo `account` | Sin imports ni accesos Rust a `hbbs_http::account`. `src/hbbs_http/account.rs` permanece en disco, pero ya no se incluye como módulo. |
| `src/hbbs_http/record_upload.rs` | `MAX_HEADER_LEN`, `SHOULD_SEND_TIME`, `SHOULD_SEND_SIZE`, `ENABLE`, `RecordUploader` y sus métodos `send`, `handle_new_file`, `handle_frame`, `handle_tail`, `handle_remove` | Sin referencias al propietario eliminado. Los usos homónimos de `send` y `handle_frame` pertenecen a canales, streams y audio. |
| `src/hbbs_http/sync.rs` | `TIME_HEARTBEAT`, `UPLOAD_SYSINFO_TIMEOUT`, `TIME_CONN`, `PRO`, `start`, `start_hbbs_sync`, `StrategyOptions`, `InfoUploaded` y sus métodos `default`/`uploaded`, `start_hbbs_sync_async`, `heartbeat_url`, `handle_config_options`, `register_switch_grant`, `switch_code_verifier`, `switch_grant_signed_msg` | Sin referencias al propietario eliminado. Se comprobaron los accesos a `hbbs_http::sync`; solo permanecen `signal_receiver` e `is_pro`, ambos definidos. |
| `src/hbbs_http/sync.rs::tests` | Módulo `tests`, `test_switch_code_verifier_is_not_raw_switch_code`, `test_switch_grant_signed_msg_layout` | Sin referencias a esos tests eliminados. Otros módulos `tests` son independientes. |
| `libs/hbb_common/src/websocket.rs` | Declaración del módulo `proxy_tests` | Sin referencias a la declaración retirada; no se vuelve a incluir el fixture TLS. |

No se eliminan ni renombran enums en estos diffs.

Las siguientes declaraciones aparecen como retiradas en el diff, pero conservan
su nombre, tipos de argumentos y tipo de retorno. Se verificaron sus llamadas:

- `src/common.rs`: `check_software_update`, `get_custom_rendezvous_server`,
  `get_api_server`, `get_key`, `load_custom_client`, `read_custom_client`.
- `src/hbbs_http/record_upload.rs`: `run`; también se conserva `is_enable`.
- `src/hbbs_http/sync.rs`: `SENDER` y `signal_receiver`. El sender pasó de
  `Mutex<Sender<Vec<i32>>>` a `Sender<Vec<i32>>`; solo lo consulta el
  `signal_receiver` del mismo módulo, ya adaptado con `SENDER.subscribe()`.
  Los consumidores de servidor siguen recibiendo `Receiver<Vec<i32>>`.
- `src/ui_interface.rs`: `deploy_device`, `account_auth`, `account_auth_cancel`;
  también se conserva `account_auth_result`.
- `src/ui_session_interface.rs`: `get_audit_server`.

En `hbb_common/src/config.rs` permanecen todos los nombres y tipos de constantes,
estáticos, estructuras y métodos anteriores. Cambian valores e implementaciones,
pero no desaparecen campos ni firmas. En particular siguen definidos
`PROD_RENDEZVOUS_SERVER`, `APP_NAME`, `DEFAULT_SETTINGS`, `OVERWRITE_SETTINGS`,
`DEFAULT_LOCAL_SETTINGS`, `OVERWRITE_LOCAL_SETTINGS`, `HARD_SETTINGS`,
`BUILTIN_SETTINGS`, `RENDEZVOUS_SERVERS`, `RS_PUB_KEY`,
`Config::get_rendezvous_server` y `Config::get_rendezvous_servers`.

## Campos y protobuf

Se buscaron individualmente los campos de los tres tipos eliminados:

- `RecordUploader`: `client`, `api_server`, `filepath`, `filename`, `upload_size`,
  `running`, `last_send`.
- `StrategyOptions`: `config_options`, `extra`.
- `InfoUploaded`: `uploaded`, `url`, `last_uploaded`, `id`, `username`.

No quedan construcciones ni referencias a esos tipos. Las coincidencias de
nombres genéricos pertenecen a otros propietarios. No hay campos eliminados o
renombrados dentro de estructuras que permanezcan en estos diffs.

`HeaderEntry`, `HttpProxyRequest`, `HttpProxyResponse` y las variantes
`http_proxy_request`/`http_proxy_response` siguen en
`libs/hbb_common/protos/rendezvous.proto`, idéntico a la base. No quedan usos de
esos tipos ni variantes en los fuentes Rust inspeccionados. El generador es
`protobuf-codegen` 3.7, no prost. Se deja el esquema intacto; no se recupera
ninguna ruta de proxy.

## Imports Rust

Se revisaron todos los `use` retirados o modificados, incluidos los imports
locales de las funciones y tests eliminados:

| Archivo | Imports retirados/cambiados y comprobación |
| --- | --- |
| `src/hbbs_http/record_upload.rs` | `create_http_client_with_url`, `bytes::Bytes`, `hbb_common::{bail, config::Config, lazy_static, log, ResultType}`, `reqwest::blocking::{Body, Client}`, `serde::Serialize`, `serde_json::Map`, `std::{fs::File, io::{prelude::*, SeekFrom}, sync::{mpsc::Receiver, Arc, Mutex}, time::{Duration, Instant}}`. Solo se necesita `Receiver`, que sigue importado; los usos restantes del resto pertenecen a otros módulos. |
| `src/hbbs_http/sync.rs` | `std::{collections::HashMap, sync::{Arc, Mutex}, time::Duration}`, `crate::{common::API_LOG_INTERVAL, ui_interface::get_builtin_option, Connection}`, `hbb_common::{config::{self, Config, LocalConfig}, log, tokio::{self, sync::broadcast, time::Instant}}`, `base::config::keys`, `serde::{Deserialize, Serialize}`, `serde_json::{json, Value}`. El stub usa las rutas completas de Tokio y no necesita estos imports. |
| `src/hbbs_http/sync.rs`, funciones/tests retirados | `sha2::{Digest, Sha256}`, `hbb_common::sodiumoxide::crypto::{hash::sha256, sign}`, `hbb_common::sodiumoxide::crypto::hash::sha256`, `super::{switch_code_verifier, switch_grant_signed_msg}`. Desaparecen junto con sus consumidores. |
| `src/ui_interface.rs` | `crate::hbbs_http::account`. No quedan consumidores del módulo retirado. |
| `src/ui_session_interface.rs` | Se añadió `config::self`; la retirada de cuenta dejó `LocalConfig` sin uso. Se elimina este último import en esta auditoría. |
| `src/common.rs` | `allow_err` y el alias `ui_get_api_server` quedaron sin uso; se eliminan en esta auditoría. |
| `src/client.rs` | `tokio::time::interval` quedó sin uso al retirar `hc_connection_`; se elimina en esta auditoría. Se comprobaron también los módulos hijos y los consumidores de `client::*`. |

No se encontró `deny(warnings)`/`forbid(warnings)` en `src/` o
`libs/hbb_common/src/`, ni `-D warnings` en la configuración Cargo/CI revisada.
Esto no garantiza que un entorno de compilación externo no lo active.

## Dart

Solo `UserModel` pierde métodos: `_updateLocalUserInfo` y `_parseAndUpdateUser`,
ambos privados y sin llamadas restantes. También desaparecen las constantes
locales `successStatusCodeStart` y `successStatusCodeEnd`, sin referencias.
No se eliminan clases, enums ni campos de los archivos Dart comparados.

Se conservan los miembros públicos `isLogin`, `displayNameOrUserName`,
`accountLabelWithHandle`, el constructor, `refreshCurrentUser`,
`getLocalUserInfo`, `reset`, `updateOtherModels`, `logOut`, `login`,
`getLoginResponseFromAuthBody` y `queryOidcLoginOptions`. Se comprobaron los
consumidores, incluido el diálogo de login. Las firmas siguen siendo compatibles.

Los imports retirados de `user_model.dart` (`dart:async`, `dart:convert`,
`bot_toast`, Material, `ab_model.dart`, `http_service.dart`) solo servían a los
bloques retirados. Los imports conservados siguen proporcionando los modelos,
los tipos de login, GetX, `gFFI` y `bind`. Se verificó la existencia de los destinos
locales de los imports de todos los archivos Dart modificados en el diff.
No se modificó ningún archivo Dart durante esta auditoría.

Durante la revisión se incorporó el commit concurrente `935f434`. Se comprobó
también su diff fuera de la carpeta excluida: `remote_page.dart` conserva su
función local `remoteToolbar`, y `remote_toolbar.dart` conserva todos los nombres
y firmas de `_ToolbarTheme`, ahora delegados a `NiToolbarStyle`. No introduce
eliminaciones de símbolos en esos dos archivos. La implementación de
`NiToolbarStyle`, dentro de la carpeta excluida, corresponde al otro agente.

## Correcciones y superficie de regresión

- `src/common.rs`: retirar dos imports sin uso.
- `src/ui_session_interface.rs`: retirar un import sin uso.
- `src/client.rs`: retirar un import sin uso y marcar `_key`, `_token` y
  `_relay_server` como parámetros intencionadamente ignorados, pues la política
  fija de NiSoporte ya sustituía sus valores antes de usarlos.
- `src/client/io_loop.rs`: ignorar la segunda tupla del resultado de conexión,
  antes consumida únicamente por el heartbeat retirado.
- `src/port_forward.rs`: lo mismo en el login de túneles normal y multiplexado.

No cambian decisiones, tipos de firmas ni comportamiento de las rutas existentes:
sesión remota, conexión al relay y login RDP/port forwarding. Los cambios de esos
cinco archivos se limitan a los enlaces/imports que quedaron sin consumidores.
No se añade estado ni lógica de cuenta, API o proxy.

## Verificación y límites

- Búsquedas individuales con `rg`, inspección de propietarios, consumidores e
  imports; comparación del esquema protobuf y de las firmas conservadas.
- `git diff --check` y revisión final del diff mínimo.
- No se añadieron tests: estos cambios no alteran comportamiento ejecutable.
- No hay `cargo`, `rustc`, `rustfmt`, `dart`, `flutter` ni `protoc` en el PATH.
  No se ejecutaron compilaciones, tests ni analizadores de esos lenguajes.
- Quedan pendientes la resolución real de tipos/macros, los avisos del compilador,
  las combinaciones de plataforma/features, la generación protobuf y el bridge
  nativo de Flutter en CI. El bridge Web versionado no cambió respecto al tag.
- La carpeta `flutter/lib/nisoporte/` y cualquier cambio posterior a la revisión
  de `935f434` no están cubiertos por esta auditoría.
