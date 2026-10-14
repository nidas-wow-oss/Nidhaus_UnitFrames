# Pruebas

Simulaciones del addon fuera del juego. Cada una monta un WoW de mentira
(`CreateFrame`, `UnitBuff`, `GetTime`…), carga los `.lua` de verdad del addon
y comprueba lo que tiene que pasar.

No reemplazan probar en el juego: comprueban la **lógica**, no cómo se ve.
Lo que sí atrapan es la familia de errores que más apareció en este addon —
"la opción se guarda pero no se aplica", "lo muevo y al reloguear vuelve",
"apago el módulo y sigue andando" — que son justo los que no se notan hasta
dos semanas después.

## Correrlas

Hace falta **lua5.1** (es el Lua del cliente 3.3.5a):

```sh
apt install lua5.1      # Debian / Ubuntu / WSL
brew install lua@5.1    # macOS
```

Desde la raíz del repo:

```sh
./Tests/run.sh
```

Devuelve 0 si pasa todo y 1 si algo falla, así que sirve tal cual para CI.
Una sola prueba, para ver el detalle:

```sh
lua5.1 Tests/t_partypet.lua .
```

## Qué cubre cada una

| Prueba | Qué comprueba |
|---|---|
| `t_partypet` | Marco de la mascota del grupo: zonas, el CC en el retrato, los tres estilos de borde, los relojes de las auras, el resaltado de dispel, el color del dueño, el rango y la vista previa |
| `t_partypet_panel` | La hoja "Mascotas" del panel: las casillas existen, guardan, y el desplegable abre y cierra |
| `t_arena_timers` | Los timers de arena: el botón Mover arrastra sin Alt, Fijar los deja quietos de verdad y `/nuftimers` sigue andando |
| `t_timer_fonts` | Los tres timers usan la misma letra y el número del Círculo del Valor va por encima del reloj |
| `t_turnevil_glow` | El borde verde de Turn Evil gira de corrido y no se reinicia en cada repaso |
| `t_petframe_position` | El marco de la mascota se mueve, se guarda y vuelve al mismo lugar después de reloguear |
| `t_partycast_style` | El estilo guardado de las barras de casteo del grupo se aplica al entrar, no solo al tocar el botón |
| `t_defaults` | Los valores de fábrica de DR y DoT, qué limpia el "Restablecer todo" y las guardas de los comandos |
| `t_ownpos` | "Mover todo" no le pisa la posición a los módulos que guardan la suya, y sí guarda la de los que no |
| `t_arena_lod` | Los módulos de arena están en el addon aparte, el cargador los pide cuando toca, y el que se registra tarde igual arranca |

## Agregar una

Copiá la más parecida y cambiale el final. Tres reglas:

1. **Una prueba, un archivo, sin dependencias.** Cada archivo trae sus
   propios stubs. Es repetitivo a propósito: así tocar una no rompe las
   otras, y se lee entera de arriba abajo.
2. **La última línea tiene que ser `PASS n  FAIL n`.** Es lo que lee
   `run.sh`. Los fallos se imprimen como `FAIL: <explicación>`.
3. **Probá que la prueba falla con el código viejo.** Si pasa con el bug
   puesto, no está comprobando nada. Durante el desarrollo se corre contra
   las dos versiones y se compara.

El archivo recibe la raíz del repo en `arg[1]`, y arma las rutas desde ahí.
