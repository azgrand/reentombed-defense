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
