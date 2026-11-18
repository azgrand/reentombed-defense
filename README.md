# Reentombed Defense · v0.3

Tower defense 2D con **Godot 4.6 estable**, GDScript y renderer Compatibility. Sin addons ni dependencias externas de ejecución. Abre `project.godot` y pulsa F5: el menú permite jugar, ajustar idioma/sonido/pantalla y salir.

## Jugar

- Cada partida usa una nueva semilla. Repetir semilla reproduce el mapa con el generador actual; Nuevo mapa descarta la partida y genera otra.
- Teclas 1–7 o tarjetas: seleccionar torre. Hover o foco de teclado: estadísticas y descripción.
- Clic izquierdo en plataforma: construir; en torre existente: detalles y mejoras. La previsualización verde/roja valida terreno, ocupación y oro.
- Mejora hasta nivel 4. Vender en el panel o con clic derecho devuelve el 65% de la inversión total.
- Espacio inicia oleada; P pausa/continúa. Esc cierra detalles o abre pausa. En ajustes, Esc vuelve al contexto anterior.
- El castillo rojo es entrada; el azul, objetivo. Resiste 10 oleadas conservando vidas. Estado inicial: 180 oro y 20 vidas.

Aguja ataca rápido; Mortero daña en área; Escarcha ralentiza; Veneno causa daño periódico sin acumulación; Tormenta encadena hasta cuatro impactos; Balista perfora hasta tres enemigos; Estandarte acelera aliados, con aura más fuerte sin acumulación.

El HUD anuncia enemigos y grandes de la próxima oleada con los contadores reales. Los ajustes se guardan en `user://settings.cfg`; no se guarda la partida. Inglés y español se pueden cambiar sin reiniciar.

## Generación y assets

El generador conserva el contexto de cinco bits inspirado en Entombed y DFS aleatorio. v0.3 selecciona entre 16 candidatos, distribuye 30–44 plataformas y agrupa decoración fuera de zonas protegidas. Semillas de versiones anteriores producen mapas distintos. No se presenta como reproducción del cartucho. Véase `specs/map-generator.md`.

Los PNG originales de Simple Tower Defense aportados por el usuario no se modifican. `assets/README.md` detalla procedencia y mappings. `scripts/game/art.gd` cataloga arte por IDs. Sonidos e icono originales del prototipo siguen incluidos.

## Arquitectura y comprobación

Estado/coordinación en `main.gd`; combate/estadísticas en `tower_system.gd`; mapa estático en `map_layer.gd`; entidades dinámicas en `map_renderer.gd`; controles en `scripts/ui/`; preferencias en `scripts/services/`. Balance y progresión autoritativos en `data/balance.json`.

```bash
python3 tools/verify_project.py --godot godot
```

El verificador importa, ejecuta la suite de 1000 semillas, todas las pruebas de efectos/mejoras/navegación/preferencias/UI y arranca el menú. Detecta errores de script aunque el motor devuelva código 0. Si el binario se llama godot4, pásalo en `--godot`.

```bash
python3 tools/check_project.py
python3 tools/check_localization.py
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --script tools/balance_review.gd
```

La revisión de balance es una política automática reproducible, no una prueba de habilidad humana. Las capturas de QA están en `specs/previews/milestone-3/` y el informe por fases en `specs/milestone-3-progress.md`.

## Exportar

Instala plantillas de exportación de Godot 4.6. Hay presets para Linux y Windows:

```bash
mkdir -p exports
godot --headless --path . --export-release Linux exports/reentombed-defense.x86_64
godot --headless --path . --export-release Windows exports/reentombed-defense.exe
```

No hay multijugador, guardado de runs ni navegación dinámica. Colocar/mejorar/vender nunca altera la ruta. La escucha de audio, comodidad de controles y dificultad requieren revisión interactiva; las pruebas headless no sustituyen esa aceptación.
