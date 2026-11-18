# Assets

## Simple Tower Defense

`simple_tower_defense/` contiene los 46 PNG originales extraídos del archivo `Simple Tower Defense.rar` aportado por el usuario. El archivo se conserva sin modificar. No se ha recibido autoría ni licencia en su contenido; no se atribuye al proyecto la creación de estos sprites.

Integración en `scripts/game/art.gd` y `main.gd`:

- Aguja → archer, Mortero → cannon, Escarcha → ice wizard, con sus proyectiles.
- Enemigos normales → slime, goblin y skeleton según oleada; grandes → king slime.
- Enemigos y castillos → hojas horizontales de cuatro fotogramas, sin recortar ni modificar los PNG. Animación a 8 y 6 fps respectivamente; congelada en pausa.
- Entrada → castillo rojo; objetivo → castillo azul.
- Césped, atlas de suelo/piedra, árboles, rocas y setas → escenario. Decoración estable por semilla y restringida a celdas no construibles.
- Texturas con filtro nearest heredado de la raíz para conservar bordes nítidos.

Los demás sprites del paquete quedan disponibles para futuras ampliaciones. No se utilizan recursos de Atari ni del juego Entombed.

## Assets originales del prototipo

`icons/icon.svg` es un vector original; `audio/build.wav` y `audio/wave.wav` son tonos sintetizados mediante `tools/generate_audio.py`. Barras de vida, indicadores de alcance e impactos se dibujan con CanvasItem. La tipografía usa la fuente por defecto de Godot.
