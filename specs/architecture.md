# Arquitectura v0.3

Versión objetivo validada: Godot 4.6 estable, Compatibility, 1280×800 con canvas_items. Arranque `scenes/main_menu.tscn`; juego `scenes/main.tscn`.

- `scripts/game/main.gd`: único propietario de estado de run, transacciones, input y coordinación. Mantiene API para pruebas anteriores.
- `tower_system.gd`: estadísticas de nivel y aura, costes/reembolso, targeting y dispatch de siete comportamientos. No acredita recompensas: se retiran bajas una vez en el coordinador.
- `scripts/core/entombed_mapper.gd`, `map_quality.gd`: generación pura con RNG local, selección acotada de candidatos, plataformas y metadatos deterministas.
- `map_layer.gd`: comandos estáticos registrados al crear mapa; renderer dinámico separado en `map_renderer.gd`.
- `art.gd`: texturas por ID, fallback explícito de torre a Aguja, hojas de cuatro frames para enemigos/castillos/Estandarte. Los assets originales no se modifican.
- `scripts/ui/tower_shop.gd`: GridContainer de dos columnas y detalles por hover/foco. `tower_details.gd`: estado actual/futuro y transacciones sobre instancia seleccionada.
- `scripts/ui/navigation.gd`, `main_menu.gd`, `settings_panel.gd`: menús, overlays, confirmaciones y ajustes reutilizados; escenas antiguas se liberan al cambiar.
- Autoload `Preferences` (`settings_store.gd`): solo preferencias nativas, sin run; defaults seguros y validación de tipo/locale. Gettext PO nativo, sin traductor JSON.

Las definiciones y progresión viven en `data/balance.json`; instancias contienen celda, kind, cooldown, aim, level y total_invested. Enemigos conservan tiempos de slow/poison. Las auras se calculan desde instancias activas para evitar caches obsoletas. El HUD se actualiza por fingerprint de cambios relevantes, no reconstruye tarjetas en cada frame. Un cambio de locale reconstruye controles de forma diferida, conservando inspección y selección.

Orden de tick: efectos visuales, spawn, slow/DOT y movimiento, ataques, bajas/llegadas, derrota/fin de oleada. Pausa y resultado impiden ticks completos. Interpolación y dibujo no cambian geometría. Ataques aplican daño instantáneo con proyectiles/impactos representativos.

`tools/verify_project.py` valida recursos/locales/datos, importación, todas las suites y arranque; fallan también errores de motor con salida 0. Las capturas requieren renderer real y están separadas de las pruebas headless.
