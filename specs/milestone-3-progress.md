# Ejecución de milestone 3 · 18/11/2026

## Fase A — Foundation

Implementado: separación de responsabilidades sin sustituir el bucle del juego.

- `scripts/game/tower_system.gd`: ataques existentes extraídos a un único ejecutor.
- `scripts/game/map_renderer.gd`: dibujo extraído; observa el estado del coordinador.
- `scripts/game/main.gd`: conserva interfaz de tests y estado, delega ataques y render, valida índices y coordenadas.
- `scripts/game/art.gd`: mapas explícitos por IDs `bolt`, `blast`, `frost` para torres/proyectiles; mismos PNG.
- `tools/check_project.py`, `specs/balance.schema.json`: catálogo ampliable, conservando tres como mínimo durante foundation.
- `README.md`: versión objetivo confirmada con binario 4.6.stable.official.89cea1439; se conserva configuración de Godot 4.6 del usuario.

Pruebas: validador Python OK; importación realizada; suite original de 1000 semillas y combate con cero fallos en Godot 4.6. La importación headless emite avisos de sockets del sandbox. No se han añadido torres todavía ni modificado balance. Mapeo sin sustituciones: archer, cannon, ice_wizard y sus proyectiles. Revisión manual: F5; probar semillas 42 y 2026, construir, iniciar oleada, pausar y vender. Preparada para la fase B; revisión visual conjunta con el siguiente cambio de render.

Riesgo/deuda: el estado continúa en diccionarios con un solo propietario; UI aún en el coordinador hasta C/D. No se ha tocado el spec no versionado del usuario en `specs/upgrade/`.

## Fase B — MAP-01

Archivos: `entombed_mapper.gd` selecciona candidatos y distribuye plataformas; `map_quality.gd` puntúa longitud, giros y separación; `map_layer.gd` almacena dibujo estático y usa cuadrantes del atlas; `map_renderer.gd` conserva entidades dinámicas; `main.gd` invalida la capa al regenerar. `tests/run_tests.gd` añade versión, densidad y exclusión de decoración. `tools/capture_preview.gd` usa el renderer extraído. `specs/map-generator.md` documenta algoritmo y compatibilidad.

Resultados Godot 4.6: 1000 rutas distintas, 10 entradas, 45 longitudes; cero fallos en suite completa. Revisadas las 20 capturas de semillas 0–17, 42 y 2026 en `specs/previews/milestone-3/contact-sheet.png`. Los PNG originales no cambian. No hay assets nuevos ni fallback. Confirmada continuidad visual, menor densidad de piedra y decoración fuera de áreas protegidas; hay claros amplios en algunas semillas, conservados para variar densidad. Renderer OpenGL/Mesa sobre Xvfb, con avisos de VSync y método de entrada no disponibles.

Smoke manual: repetir semillas 0, 10, 42 y 2026, construir en piedra marcada, comprobar que césped colindante no permite construir. Preparada para C. Balance de nuevas longitudes sigue pendiente de partidas completas.

## Fase C — MENU-01 / I18N-01

Archivos nuevos: `scripts/services/settings_store.gd` (preferencias nativas ConfigFile), `scripts/ui/navigation.gd` (menú/pausa/resultado/confirmación), `settings_panel.gd`, `main_menu.gd`, `scenes/main_menu.tscn`, `localization/en.po`, `es.po`, `README.md`, `tools/check_localization.py`, `tools/capture_ui.gd`, `tests/test_preferences.gd`, `test_navigation.gd`. Modificados: arranque y traducciones en `project.godot`; claves semánticas en balance y schema; coordinador con pausa/transiciones e interfaz retraducible diferida; validador invoca comprobación de catálogos.

Resultados: 40 claves completas con paridad de placeholders; preferencias/persistencia/defaults corruptos, menú, pausa sin avance de simulación y cambio ES/EN con partida abierta: OK. Suite de 1000 semillas y combate: cero fallos. Arranque real del menú y capturas revisadas: `menu.png`, `settings.png` (ES), `game.png` (EN). Se corrigió la reconstrucción de controles durante notificación de traducción usando actualización diferida. La confirmación protege la vuelta al menú; Esc en ajustes regresa al contexto anterior. Sin nuevos assets, castillo verde original para portada.

Smoke: F5 → ajustes → alternar idioma/sonido → Jugar → P → ajustes → volver → continuar; probar derrota/victoria y acciones de repetir/nuevo/menú. Preparada para D. La tienda sigue siendo la de tres tarjetas hasta la fase siguiente. Pendientes: escuchar audio en dispositivo real y revisión completa de dificultad.

## Fase D — UI-01 / TWR-01 / QOL-01

Archivos: balance y schema con siete comportamientos y parámetros; `tower_system.gd` dispatch de ataques/efectos, aura dinámica más fuerte; `tower_shop.gd` GridContainer dos columnas con hover/foco y detalles; `main.gd` valida compras con el mismo contrato de previsualización; `map_renderer.gd` ghosts positivos/negativos, veneno visible y rayos encadenados; `art.gd` mappings explícitos; catálogos/validador y pruebas ampliados. Captura revisada `shop.png` (EN): siete tarjetas y panel dentro del viewport.

Assets sin fallback: Veneno→poison_wizard, Tormenta→lightning_tower, Balista→crossbow, Estandarte→normal_tower_01_green (cuatro frames). Proyectiles correspondientes para atacantes; Estandarte no dispara.

Pruebas: suite de 1000 semillas/combate generalizada a siete torres, cero fallos. Test específico comprueba poison refresh/no-stack, expiración con delta grande, pausa, recompensa única, cadena de cuatro impactos con caída 70%, perforación de tres, aura strongest-only y exclusión propia. Navegación e idioma continúan OK. Validador: 51 claves, referencias, balance y parámetros. Smoke: teclas 1–7, comprar cada tipo, hover/foco con poco oro; revisar efectos con semilla 42. Preparada para E. No se ha cambiado economía ni precios base.

## Fase E — TWR-02

Archivos: `balance.json` y schema contienen progresión autoritativa; `tower_system.gd` comparte cálculo de estadísticas efectivas, coste y reembolso; `main.gd` añade transacciones atómicas y selección independiente de instancia; `tower_details.gd` muestra nivel, stats actuales/siguientes, Upgrade/Sell; renderer dibuja pips y aura; catálogos incluyen acciones y feedback; `test_upgrades.gd` valida las siete torres.

Pruebas: cero fallos en todas las fórmulas, inversión acumulada, máximo, oro insuficiente, venta pausada rechazada, ventas repetidas/referencias obsoletas, ausencia de arbitraje, mejoras durante oleadas, limpieza al reset y geometría intacta. Pruebas de efectos y navegación siguen pasando. Captura de nivel 4 revisada; se reforzó fondo del panel para lectura sobre el mapa. No cambian sprites ni escala; nivel 4 usa pips dorados.

Smoke: semilla 42, construir Aguja, seleccionarla, mejorar con oro de oleadas y vender; Estandarte nivel 4 muestra aura 30%. Las operaciones no se permiten en pausa/resultado. Preparada para F. No se ha reajustado balance sin evidencia de partidas completas.

## Fase F — QOL-02 / QOL-03 y cierre de implementación

Archivos: `main.gd` calcula forecast desde contador real y actualiza HUD por fingerprint; `map_renderer.gd` limita barras a [0,1]; `test_forecast_placement.gd` verifica pronóstico, geometría/compra y tienda; pruebas de navegación y comportamientos amplían confirmación, liberación y aura dinámica. `tools/verify_project.py` ejecuta todos los controles y detecta errores de motor aunque retorne 0. `tools/balance_review.gd` registra una política de compra reproducible. Capturas/tooling actualizados; README, specs funcionales/arquitectura/aceptación, assets y validation reflejan v0.3.

Resultado final: **All project checks passed**, salida 0 en Godot 4.6. 65 traducciones; todos los tests dedicados y 1000 mapas pasan. Revisadas imágenes finales de menú, ajustes ES, hover EN, nivel 4, combate y escalado 1024×640; semillas de mapas 0–17,42,2026. La simulación de compra completa las diez oleadas en 0/42/2026 con 20 vidas, 19 torres y 140 oro. No cambia el balance base. No hay nuevos assets ni fallback utilizado.

Smoke recomendado: F5, cambiar ES/EN, jugar semilla 42, seleccionar 1–7 y construir; mejorar/vender; P/Esc, ajustes y confirmación de regreso; repetir con 2026. Riesgos y aceptación pendiente: audio real, gamepad, campaña humana y plantillas de exportación no probados. Implementación A–F terminada; **no se marca la aceptación interactiva total como completada**. No se hace push ni publicación. Se conserva sin tocar el master spec no versionado del usuario.

## Commits y archivos por fase

### A: `48c1879`

- `README.md`
- `scripts/game/art.gd`
- `scripts/game/main.gd`
- `scripts/game/map_renderer.gd`
- `scripts/game/tower_system.gd`
- `specs/balance.schema.json`
- `specs/milestone-3-progress.md`
- `tools/check_project.py`

### B: `0f4a62c`

- `scripts/core/entombed_mapper.gd`
- `scripts/core/map_quality.gd`
- `scripts/game/main.gd`
- `scripts/game/map_layer.gd`
- `scripts/game/map_renderer.gd`
- `scripts/game/map_renderer.gd.uid`
- `scripts/game/tower_system.gd.uid`
- `specs/map-generator.md`
- `specs/milestone-3-progress.md`
- `specs/previews/milestone-3/contact-sheet.png`
- `specs/previews/milestone-3/map-0.png`
- `specs/previews/milestone-3/map-1.png`
- `specs/previews/milestone-3/map-10.png`
- `specs/previews/milestone-3/map-11.png`
- `specs/previews/milestone-3/map-12.png`
- `specs/previews/milestone-3/map-13.png`
- `specs/previews/milestone-3/map-14.png`
- `specs/previews/milestone-3/map-15.png`
- `specs/previews/milestone-3/map-16.png`
- `specs/previews/milestone-3/map-17.png`
- `specs/previews/milestone-3/map-2.png`
- `specs/previews/milestone-3/map-2026.png`
- `specs/previews/milestone-3/map-3.png`
- `specs/previews/milestone-3/map-4.png`
- `specs/previews/milestone-3/map-42.png`
- `specs/previews/milestone-3/map-5.png`
- `specs/previews/milestone-3/map-6.png`
- `specs/previews/milestone-3/map-7.png`
- `specs/previews/milestone-3/map-8.png`
- `specs/previews/milestone-3/map-9.png`
- `tests/run_tests.gd`
- `tools/capture_preview.gd`

### C: `198e626`

- `.gitignore`
- `data/balance.json`
- `localization/README.md`
- `localization/en.po`
- `localization/es.po`
- `project.godot`
- `scenes/main_menu.tscn`
- `scripts/core/map_quality.gd.uid`
- `scripts/game/main.gd`
- `scripts/game/map_layer.gd.uid`
- `scripts/services/settings_store.gd`
- `scripts/services/settings_store.gd.uid`
- `scripts/ui/main_menu.gd`
- `scripts/ui/main_menu.gd.uid`
- `scripts/ui/navigation.gd`
- `scripts/ui/navigation.gd.uid`
- `scripts/ui/settings_panel.gd`
- `scripts/ui/settings_panel.gd.uid`
- `specs/balance.schema.json`
- `specs/milestone-3-progress.md`
- `specs/previews/milestone-3/game.png`
- `specs/previews/milestone-3/menu.png`
- `specs/previews/milestone-3/settings.png`
- `tests/test_navigation.gd`
- `tests/test_preferences.gd`
- `tools/capture_ui.gd`
- `tools/check_localization.py`
- `tools/check_project.py`

### D: `5a834f1`

- `data/balance.json`
- `localization/en.po`
- `localization/es.po`
- `scripts/game/art.gd`
- `scripts/game/main.gd`
- `scripts/game/map_renderer.gd`
- `scripts/game/tower_system.gd`
- `scripts/ui/tower_shop.gd`
- `specs/balance.schema.json`
- `specs/milestone-3-progress.md`
- `specs/previews/milestone-3/shop.png`
- `tests/run_tests.gd`
- `tests/test_tower_behaviors.gd`
- `tools/capture_ui.gd`
- `tools/check_project.py`

### E: `5a52eb5`

- `data/balance.json`
- `localization/en.po`
- `localization/es.po`
- `scripts/game/main.gd`
- `scripts/game/map_renderer.gd`
- `scripts/game/tower_system.gd`
- `scripts/ui/tower_details.gd`
- `specs/balance.schema.json`
- `specs/milestone-3-progress.md`
- `specs/previews/milestone-3/upgrade.png`
- `tests/test_upgrades.gd`
- `tools/capture_ui.gd`
- `tools/check_project.py`
