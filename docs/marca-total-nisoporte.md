# Marca NiSoporte en Windows

## Alcance y resultado

Revisión local en la rama `nisoporte`, sin red, SDK, compilación ni ejecución en Windows.
La interfaz española e inglesa, los recursos gráficos de marca y los nombres de los
entregables Windows usan NiSoporte. La atribución a RustDesk se conserva de forma
expresa; esta revisión no constituye una certificación de cumplimiento legal.

## Identidad que ya estaba configurada

- `libs/hbb_common/src/config.rs`: `APP_NAME = NiSoporte`. No se modifica el submódulo.
- `flutter/windows/CMakeLists.txt`: `BINARY_NAME = NiSoporte`.
- `flutter/windows/runner/main.cpp`: título principal NiSoporte y títulos derivados
  para instalación y gestor de conexiones mediante el nombre de aplicación.
- `src/platform/windows.rs`: servicio `NiSoporte` (presentación `NiSoporte Service`),
  ejecutable instalado `NiSoporte.exe`, instalación en `Program Files\NiSoporte`,
  menú Inicio, accesos directos y claves de desinstalación derivados de
  `get_app_name()`. Los registros de protocolo usan el prefijo de la aplicación.
- Los datos, configuraciones y registros de usuario se calculan con `APP_NAME` en
  `Config` (en Windows, directorio de aplicación NiSoporte dentro de AppData).
- `src/tray.rs`: tooltip e identificador derivados de `get_app_name()`, preferencia
  por `data/flutter_assets/assets/icon.png`, respaldo `res/tray-icon.ico`.
- `flutter/assets/icon.png`, `flutter/assets/logo.png`, `res/icon.png` y los ICO
  `flutter/assets/icon.ico`, `res/icon.ico`, `res/tray-icon.ico` y
  `flutter/windows/runner/resources/app_icon.ico` ya contienen la marca NiSoporte.
  Se comprobó que los cuatro ICO son idénticos; no se reescriben.

## Ficheros cambiados y superficie de regresión

Cada cambio siguiente afecta a la presentación o a un productor/consumidor del
nombre cambiado. No se cambia el protocolo de conexión ni los símbolos FFI.

| Fichero existente | Cambio y ruta afectada; motivo |
| --- | --- |
| `build.py` | Entregables Flutter y Win7 llamados NiSoporte; payload Win7 apunta a `NiSoporte.exe`, que es el fichero copiado. Conserva los nombres de entrada generados por Cargo. |
| `build.rs` | Propiedades del EXE Sciter/inline de publicación: NiRepair, NiSoporte y crédito discreto. |
| `flutter/assets/icon.svg` | Respaldo SVG válido con símbolo N de NiSoporte; evita mostrar el icono upstream si falla el PNG. |
| `flutter/lib/common.dart` | Enlace del pie de marca al repositorio de NiSoporte. |
| `flutter/lib/desktop/pages/connection_page.dart` | Enlace de ayuda comercial al proyecto NiSoporte. |
| `flutter/lib/desktop/pages/desktop_setting_page.dart` | About genérico: web de NiSoporte y enlace a su licencia AGPL con etiqueta de licencia. |
| `flutter/lib/desktop/pages/install_page.dart` | Acuerdo de instalación y tooltip enlazan a `LICENCE` de NiSoporte. |
| `flutter/lib/desktop/widgets/tabbar_widget.dart` | Título literal de la barra sustituido por NiSoporte. |
| `flutter/lib/nisoporte/tech_settings.dart` | Solo About del técnico: texto solicitado, enlaces upstream en el crédito y conservación del copyright previo. El botón Código fuente ya enlazaba a NiSoporte. |
| `flutter/windows/runner/Runner.rc` | Crédito mínimo del cliente en propiedad Comments del EXE; se conserva LegalCopyright. |
| `flutter/windows/runner/service_control.h` | Mensaje de error del control de servicio con NiSoporte. |
| `libs/portable/build.rs` | Propiedades NiSoporte/NiRepair y crédito en el EXE empaquetador. |
| `libs/portable/generate.py` | Carpeta y ejecutable predeterminados NiSoporte; conserva formato del paquete. |
| `libs/portable/src/main.rs` | Directorio portátil de respaldo, prefijo de actualización verificada y proceso auxiliar NiSoporte. |
| `libs/portable/src/ui.rs` | Etiqueta de extracción con texto NiSoporte, sin cargar el antiguo bitmap de RustDesk. |
| `res/logo.svg` | Símbolo SVG N de NiSoporte, autocontenido. |
| `res/logo-header.svg` | Cabecera SVG con nombre NiSoporte, autocontenida. |
| `res/mac-tray-dark-x2.png` | Sustituido por el PNG de 32 px embebido en el ICO NiSoporte; recurso de bandeja macOS solicitado en el inventario. |
| `res/mac-tray-light-x2.png` | Mismo PNG NiSoporte de 32 px; no se introduce diseño raster nuevo. |
| `res/msi/CustomActions/CustomActions.cpp` | Limpieza del proceso auxiliar con su nuevo nombre. |
| `res/msi/CustomActions/RemotePrinter.cpp` | Nombre de aplicación de respaldo NiSoporte al instalar la impresora. |
| `res/msi/Package/Components/RustDesk.wxs` | Terminación del proceso auxiliar con el mismo nombre que Rust y el empaquetador. |
| `res/msi/Package/Language/Package.en-us.wxl` | Nombres visibles del instalador, servicio y accesos directos NiSoporte. |
| `res/msi/preprocess.py` | Predeterminados NiSoporte/NiRepair y enlaces propios. La licencia generada incluye los créditos y la AGPL íntegra, sin sustituir autores dentro de ella. |
| `src/common.rs` | Mensaje del rechazo de actualizaciones automáticas sin marca upstream. |
| `src/lang/en.rs` | Solo valores visibles: RustDesk/Rustdesk pasa a NiSoporte. Claves, URLs técnicas y escapes conservados. |
| `src/lang/es.rs` | Mismo cambio de marca en valores visibles españoles. |
| `src/platform/windows.cc` | Nombre del registro de diagnóstico de impresión `test_nisoporte.log`. |
| `src/platform/windows.rs` | Ayudante portátil `nisoporte-sciter/NiSoporte.exe`, staging propio, mensajes y ventana de salida; limpieza de temporales con prefijos NiSoporte, coordinada con sus productores. |
| `src/platform/windows/verified_update.rs` | Productor de copias verificadas con prefijo `nisoporte-verified-`, igual que el consumidor portátil. |
| `src/privacy_mode/win_topmost_window.rs` | Proceso `RuntimeBroker_NiSoporte.exe`, clase y nombre de ventana de privacidad NiSoporte. |
| `src/whiteboard/windows.rs` | Título de ventana de pizarra NiSoporte. |

Ficheros nuevos: `CREDITOS.md` y este documento
`docs/marca-total-nisoporte.md`.

No se modifica ningún otro fichero de `flutter/lib/nisoporte/`.
Los cambios en textos compartidos también aparecen cuando otras plataformas usan
las mismas traducciones o widgets. Los PNG de bandeja macOS se han inventariado
estáticamente; su apariencia monocroma requiere comprobación en macOS.

## Nombres internos conservados por compatibilidad

- Paquete Cargo `rustdesk`, crate/biblioteca `librustdesk`, artefactos de entrada
  `target/release/rustdesk.exe`, `rustdesk-portable-packer.exe`, DLL
  `librustdesk.dll` y sus equivalentes de otras plataformas. El ejecutable que se
  entrega/instala se renombra; la DLL sigue en el paquete y es visible si se
  inspeccionan sus archivos. Renombrarla exige coordinar carga dinámica y codegen.
- Símbolos/exportaciones `rustdesk_core_main_args`, `get_rustdesk_app_name`,
  `rustdesk_is_disable_installation`, nombres de tipos y funciones Rust/Dart,
  cabeceras, `project(rustdesk)` de CMake y nombres de los archivos WiX.
- Canales Flutter `org.rustdesk.rustdesk/host`, claves de configuración/eventos,
  `RUSTDESK_APPNAME`, pipes internos, etiquetas de scripts y firmas de metadatos.
  Son contratos entre componentes; no son etiquetas de la interfaz.
- Identificador binario `rustdesk` del formato del paquete portátil, compartido
  por `generate.py` y `bin_reader.rs`; cambiarlo rompería las plantillas existentes.
- Claves de traducción que contienen RustDesk. El traductor existente sustituye
  el nombre de aplicación en los textos de respaldo; no se renombran las claves.
- Comparaciones con la marca upstream para detectar clientes personalizados y
  bloquear sus servicios/actualizaciones públicas, pruebas y comentarios de origen.
- `DeleteRustDeskTestCertsW` y los identificadores de certificados de prueba
  upstream: se conserva su correspondencia con los objetos que deben detectar.
- Controladores externos firmados: `RustDeskIddDriver Device`,
  `RustDeskIddDriver/RustDeskIddDriver.inf`,
  `drivers/RustDeskPrinterDriver/RustDeskPrinterDriver.inf` y
  `RustDesk v4 Printer Driver`. La cola de impresión deriva de NiSoporte, pero
  **el nombre del controlador puede verse en el Administrador de dispositivos o
  las propiedades avanzadas de impresión**. Eliminar también esa marca exige
  paquetes de controladores propios y su firma; queda fuera de un cambio de textos.
- Licencias, copyrights, créditos y URLs de documentación técnica upstream,
  incluidos enlaces específicos de otras plataformas. Las páginas y rutas
  heredadas Sciter conservan enlaces de documentación upstream; la variante
  Windows actual utiliza Flutter y las pantallas NiSoporte.

## Recursos y límites de la comprobación

`loadIcon()` usa `Image.asset('assets/icon.png')` y conserva un SVG de respaldo
válido. No se crean referencias a `flutter/assets/logo.svg` ni
`flutter/assets/logo-header.svg`, que no existen ni se cargan. Los logos de tema
opcionales `logo_light.png`/`logo_dark.png` se comprueban antes de usarlos y caen
al `logo.png` existente; no son dependencias obligatorias ausentes.

No se migran datos o instalaciones antiguas de RustDesk ni se renombran
controladores firmados. Sin compilación ni una sesión Windows no puede asegurarse
la ausencia absoluta de marca en todos los diálogos del sistema o dependencias.

## Comprobaciones realizadas

- `rg` sobre marcas, usos SVG/PNG, bandeja, títulos, EXE, servicio, registro y rutas.
- `git diff --check` y revisión de minimización de todos los archivos modificados.
- Parseo AST de los tres Python modificados, sin importar ni ejecutar sus builds.
- Parseo XML de SVG y recursos WiX modificados; SVG sin enlaces externos.
- Comparación de traducciones con HEAD: claves, placeholders y escapes intactos;
  solo sustituciones de marca en los valores.
- Identidad binaria de los ICO y estructura/dimensiones de los PNG de bandeja.
- Conversión de licencia MSI ejecutada con escritura interceptada en memoria:
  AGPL completa, copyright FSF, crédito y fuente NiSoporte presentes; caracteres
  españoles codificados en RTF. No se modifica la plantilla durante la prueba.
- Orquestación de empaquetado Flutter Windows simulada con y sin portable,
  interceptando todos los comandos y operaciones de archivos; entrada y salida
  NiSoporte coherentes, sin SDK ni builds.
- Coincidencia de nombres del proceso auxiliar y prefijos de actualización entre
  productores, consumidores y limpieza MSI; existencia de recursos referenciados.
- Verificación de que `LICENCE` y el submódulo no cambian, y de que en la carpeta
  NiSoporte solo cambia `tech_settings.dart`.

No se ha usado la red, instalado paquetes, compilado, desplegado ni publicado.
