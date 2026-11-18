# Reentombed Defense

Prototipo de tower defense 2D para **Godot 4.6 estable**, GDScript y renderizador Compatibility. Sin addons ni dependencias de ejecución externas.

## Ejecutar

1. Instala Godot 4.6 estable (edición estándar; no necesita .NET).
2. Importa `project.godot` y pulsa **F6/F5** para jugar.
3. Construye en las plataformas `+` junto al camino y pulsa Espacio para iniciar cada oleada.

```bash
godot --path . --editor
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run_tests.gd
```

Si tu ejecutable se llama `godot4`, sustituye `godot` en los comandos.

## Controles

- Clic izquierdo: construir la torre seleccionada; 1/2/3: seleccionar.
- Clic derecho sobre una torre: venderla y recuperar el 65 % (redondeado hacia abajo).
- Espacio: iniciar oleada. P: pausar simulación.
- Repetir semilla: reinicia toda la partida usando la semilla escrita.
- Nuevo mapa: empieza otra partida con semilla aleatoria.
- El círculo al pasar el ratón muestra el alcance de la torre seleccionada.

Castillo rojo: entrada; castillo azul: salida. Los enemigos siguen exclusivamente el camino de tierra con flechas. Conserva al menos una de las 20 vidas hasta completar las 10 oleadas. Las torres pueden construirse entre oleadas y durante el combate. Mortero causa daño de área; Escarcha ralentiza temporalmente. Los enemigos grandes tienen más vida y menos velocidad.

## Estructura

| Ruta | Contenido |
| --- | --- |
| `scenes/` | Escena inicial |
| `scripts/core/` | Generación independiente del juego |
| `scripts/game/` | Simulación, dibujo e interfaz del prototipo |
| `assets/icons/` | Icono SVG original |
| `assets/audio/` | Sonidos sintetizados originales |
| `assets/simple_tower_defense/` | Sprites del paquete aportado por el usuario |
| `data/balance.json` | Economía, torres y número de oleadas |
| `specs/` | Diseño, generación, arquitectura y aceptación |
| `tests/` | Pruebas headless con el motor real |

El tablero usa césped, caminos de tierra, plataformas de piedra y decoración del paquete Simple Tower Defense. Las torres, proyectiles, castillos y enemigos usan sus PNG originales; las hojas animadas se dividen en cuatro fotogramas. `scripts/game/art.gd` reúne las texturas y el filtrado nearest conserva el pixel art. No se requieren descargas adicionales. La UI y el render se concentran en `main.gd` para facilitar la primera iteración; se pueden extraer a escenas independientes al ampliar el juego.

## Entombed y alcance de esta versión

Se conserva la idea de generación por filas, vecindario de cinco bits y simetría. La tabla y los límites se adaptan al proyecto; no se presenta como reproducción exacta del algoritmo del cartucho. Ese terreno guía una segunda fase de generación de laberinto mediante búsqueda aleatoria en profundidad. Se elige la ruta hasta la salida inferior más lejana y se convierten sus vecinos en plataformas. El recorrido, la entrada y la longitud cambian por semilla; se ha eliminado el trazado fijo en seis franjas. Al abrir el juego se usa una semilla aleatoria, visible bajo el tablero. Repetir semilla reproduce el mapa con la versión actual del generador. Véase `specs/map-generator.md`.

Es un prototipo local: sin guardado, mejoras, multijugador, música ni navegación dinámica. Las torres no bloquean ni cambian el recorrido. El equilibrio inicial está preparado para iteración y requiere partidas de prueba.

## Exportar

Instala las plantillas de exportación de la misma versión de Godot. Los presets Linux y Windows están incluidos. Crea la carpeta de salida antes de exportar:

```bash
mkdir -p exports
godot --headless --path . --export-release Linux exports/reentombed-defense.x86_64
godot --headless --path . --export-release Windows exports/reentombed-defense.exe
```

Consulta `specs/acceptance.md` para los controles de aceptación y `assets/README.md` para la procedencia de assets.
