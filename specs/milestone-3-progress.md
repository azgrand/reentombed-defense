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
