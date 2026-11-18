# Validación realizada · 14 de noviembre de 2026

Motor: Godot 4.3 stable oficial, Linux x86_64, ejecutado desde /tmp (no se incluye el binario en el proyecto). Se conserva la configuración del usuario marcada como Godot 4.6; la ejecución también se comprueba con 4.3.

- `python3 tools/check_project.py`: OK, balance, referencias de recursos y WAV.
- Importación del editor headless: PNG del paquete importados, sin errores de scripts o importación. El sandbox produce avisos de escucha TCP del editor.
- `--headless --path . --script tests/run_tests.gd`: 1000 semillas y reglas de juego, cero fallos, salida 0.
- Variedad medida: 1000 rutas diferentes, 10 filas de entrada y 97 longitudes de recorrido. Comprobadas también 25 regeneraciones y repetición exacta de la semilla escrita.
- Se conservan las pruebas de continuidad, ocupación de plataformas, compras, oleadas, derrota/victoria, daño directo, área y ralentización.
- Las hojas de animación utilizadas tienen anchura divisible entre cuatro.
- Render real en Xvfb + OpenGL/Mesa: revisadas capturas de semillas 42 y 2026. Torres, enemigos, castillos, terreno, decoración y UI visibles y legibles. Capturas de referencia en `specs/previews/`; fixture regenerable con `tools/capture_preview.gd`. La pantalla virtual emite avisos de métodos de entrada y VSync no disponibles.

En este entorno se usan XDG_DATA_HOME, XDG_CACHE_HOME y XDG_CONFIG_HOME bajo /tmp para no escribir fuera del workspace. No son necesarios en una instalación normal. Los fixtures visuales desactivan audio y usan 220 de oro para mostrar las tres torres.

Pendiente: escucha de audio, revisión interactiva completa, equilibrio de diez oleadas con los nuevos recorridos y exportación con las plantillas instaladas. El cambio de generador modifica el mapa de semillas de la versión anterior.
