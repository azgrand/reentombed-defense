# Arquitectura y configuración

Godot 4.3+, GDScript tipado cuando aporta claridad, renderer Compatibility. Resolución lógica 1280 × 800 con escalado canvas_items. La escena raíz carga el balance y genera una partida con una semilla elegida mediante RNG local aleatorizado. No hay autoloads, addons ni recursos de red.

`EntombedMapper` es RefCounted con generación estática y RNG local. `main.gd` mantiene enemigos, torres y efectos como diccionarios, simula con delta y dibuja con CanvasItem usando texturas del catálogo `art.gd`. Los enemigos y castillos animan cuatro fotogramas horizontales; decorado determinista por celda. Las posiciones enemigas interpolan los segmentos de `route` en unidades de celdas. La UI usa controles nativos con eventos; los clics consumidos por estos no construyen en el mapa.

Orden de tick: expirar rayos → aparición → movimiento/efectos → selección y daño → retirar bajas/llegadas → derrota o fin de oleada. Un enemigo muerto no ataca ni concede recompensa dos veces. Victoria y derrota detienen la simulación hasta reiniciar.

`data/balance.json` es configuración interna de desarrollo. Debe contener valores positivos y tres torres; no es entrada de usuario ni se admite edición en caliente. Validación estructural: `python3 tools/check_project.py`. El contrato JSON está en `specs/balance.schema.json`. Cambiar el número de torres exige revisar teclas y disposición de la UI.

Los sonidos WAV se generan de forma original y se reproducen al construir/iniciar oleada. No se requiere importación manual; Godot importa SVG y WAV al abrir el proyecto. Exportación requiere plantillas correspondientes al motor instalado.
