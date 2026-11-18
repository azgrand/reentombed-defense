# Aceptación

## Automatizada

Ejecutar importación headless, pruebas GDScript y arranque corto:

```bash
python3 tools/check_project.py
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --quit-after 120
```

Las pruebas cubren 1000 semillas (determinismo, continuidad, portales, ausencia de duplicados, plataformas y 1000 rutas distintas), bloqueo de compras inválidas, aparición, llegada a la base, fin de oleada, victoria, derrota, daño de las siete torres, área y ralentización. Salida requerida: cero fallos y código 0.

## Manual

- Abrir F5: mapa y panel legibles, sin errores en Debugger.
- Elegir las siete torres; el círculo cambia de alcance y las compras descuentan el coste.
- Construir durante combate y vender con clic derecho; comprobar devolución del 65 %.
- Iniciar oleada con Espacio; no iniciar otra mientras esté activa.
- Pausar con P; movimiento y ataques se congelan; volver a continuar.
- Escuchar sonidos de construcción y de inicio de oleada.
- Repetir semilla: mismo terreno; Nuevo mapa: otro terreno y estado inicial.
- Cerrar y volver a abrir: nueva semilla y nuevo trazado. Comprobar que entrada y longitud también varían.
- Enemigos y banderas animados; torres, proyectiles, césped y plataformas visibles y nítidos. Pausar congela las animaciones.
- Diez oleadas terminadas con vidas: victoria; cero vidas: derrota.
- Ventana redimensionada: controles y tablero conservan su disposición por escalado.

El balance y la presentación visual se validan con juego manual; las pruebas headless no sustituyen esa revisión.

## Captura reproducible

Con pantalla disponible (o Xvfb):

```bash
godot --path . --audio-driver Dummy --script tools/capture_preview.gd -- 42 /tmp/reentombed-preview.png
```

Genera un fixture visual con las tres torres y seis enemigos. Este fixture usa 220 de oro para permitir mostrar todo el arsenal; no altera el balance de la partida normal. La captura necesita renderer real, no `--headless`.

## Milestone 3

Ejecutar `python3 tools/verify_project.py --godot godot`. Pruebas dedicadas: test_tower_behaviors.gd, test_upgrades.gd, test_navigation.gd, test_preferences.gd y test_forecast_placement.gd. No se eliminan las verificaciones anteriores de 1000 semillas y combate.

Revisión visual: menú; ajustes ES; tienda EN con hover; semillas 0–17,42,2026; nivel 4 y combate con efectos. Comprobar también ventana escalada, selección por foco/teclas y salida de overlays. Revisar continuidad de camino y que ningún árbol cubra rutas o plataformas. Guardar ejemplos en specs/previews/milestone-3.

Revisión interactiva pendiente: sonido real, comodidad de controles, campaña jugada por una persona, exports con plantillas. La política de compra automatizada de tools/balance_review.gd solo informa sobre viabilidad con un comportamiento concreto.
