*[Read in English](README.md)*

# Nidhaus UnitFrames (NUF)

Addon de interfaz orientado a PvP para World of Warcraft WotLK 3.3.5a (Warmane Blackrock y otros servidores privados).

NUF combina y reescribe varios addons existentes — entre ellos Eazy Frames y sArena — con funciones propias, en un solo paquete enfocado en interfaz y PvP y configurable desde un único panel dentro del juego.

> ## Descarga
>
> **Última versión: 3.9** — es la build actual, la recomendada y la que está en uso.
>
> **[Descargar v3.9 (última release)](../../releases/latest)**
>
> Una sola descarga, todo incluido: el addon y su panel de opciones.

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-blue)
![Cliente](https://img.shields.io/badge/Client-WotLK-orange)
![Licencia](https://img.shields.io/badge/License-All%20Rights%20Reserved-red)

## Funciones

<img src="images/panel.png" width="559" alt="Panel de opciones de NUF" />

- **Marcos de unidad** — jugador, objetivo, foco, grupo y boss, con skins propias, colores de clase y escala por marco.
- **Arena** — marcos de arena en dos estilos (Default y Flat) con trinkets, iconos de especialización y cuenta regresiva, y un modo de prueba para ubicarlos fuera de una partida.
- **Grupo** — disposición 3v3 para arena con escala por miembro, y un modo de prueba para acomodar el grupo estando solo.
- **Move Everything** — arrastrá cualquier marco y cambiale el tamaño con Ctrl + rueda.
- **Módulos opcionales** — barras de acción, trackers de clase, tooltip, chat y extras de comodidad, cada uno se prende o apaga desde el panel.
- **Character Setup** — copiá barras de acción, macros y bindeos entre personajes (nExtraBars incluido).
- **Perfiles** — exportá e importá toda tu configuración.

<img width="215" alt="Arena" src="https://github.com/user-attachments/assets/ace03d46-ccb9-4952-b3c1-bdbd25d2b891" /> <img width="220" alt="Arena" src="https://github.com/user-attachments/assets/ba6e5101-b017-4d48-a4bc-9b57ba7d2023" /> <img width="212" alt="Arena" src="https://github.com/user-attachments/assets/431c3a78-f485-40e2-b942-b1a4e6202e0c" />

| Marcos de grupo | Objetivos del grupo | NiceDamage |
|:-:|:-:|:-:|
| <img width="75" alt="NewPartyFrame" src="https://github.com/user-attachments/assets/79210886-68ca-4a54-adaf-a69cfa139953" /> | <img width="100" alt="PartyTargets" src="https://github.com/user-attachments/assets/6ac41efa-3557-4d9f-aeb2-bbe5dc4608d0" /> | <img width="200" alt="NiceDamage" src="https://github.com/user-attachments/assets/fcb8a2a1-1adb-40fc-be00-0c09d2f801ec" /> |

## Instalación

1. Descargá la **v3.9** desde la [página de releases](../../releases/latest).
2. Extraé el archivo. Vas a obtener dos carpetas: `Nidhaus_UnitFrames` y `Nidhaus_UnitFrames_Config`.
3. Copiá **las dos** carpetas a tu directorio `Interface/AddOns/` de WoW.
4. Reiniciá el cliente, o escribí `/reload` si ya estás en el juego.
5. Activá los dos addons en la pantalla de selección de personaje.

> **¿Venís de una versión anterior?** Borrá la carpeta vieja `Nidhaus_UnitFrames` antes de copiar la nueva, en vez de superponerla: entre releases se reorganizan archivos y los restos de una build anterior pueden dar errores. Tu configuración vive en la carpeta `WTF` y se conserva.

> Si bajás el repositorio con el botón verde *Code* en vez de la release, la carpeta extraída se va a llamar `Nidhaus_UnitFrames-main` y va a tener las dos carpetas adentro. Copiá esas dos carpetas a `Interface/AddOns/` — no copies `Nidhaus_UnitFrames-main` en sí.

## Comandos

| Comando | Acción |
|---------|--------|
| `/nuf` | Abre el panel de opciones |
| `/nuf config` | Muestra las variables guardadas en el chat |
| `/nuf arena` | Activa el modo de prueba de arena |
| `/nuf boss` | Activa el modo de prueba de marcos de boss |
| `/nuf reset` | Restablece toda la configuración |
| `/nuf modules` | Lista los módulos y su estado |
| `/move` o `/nufmove` | Modo desbloquear todo: mové cualquier marco arrastrándolo |

El botón del minimapa también sirve de atajo: click izquierdo abre las opciones, click derecho activa el mover de arena.

## Compatibilidad

- **Cliente:** WoW 3.3.5a (WotLK)
- **Probado en:** Warmane Blackrock
- **API:** compatible con el sandbox Lua de 3.3.5a (sin HTTP, sin llamadas de hardware)

## Créditos

NUF está construido sobre el trabajo de mucha gente. El motor y varios módulos son ports o adaptaciones, y el crédito de esos es de sus autores originales:

| Proyecto original | Autor | Usado para |
|---|---|---|
| Eazy Frames, Sarena | — | Base del trabajo de marcos de unidad |
| pw_unitframes | — | Bordes de auras, barras de casteo, PartyFramePW, estilo Square de PartyTargets |
| RE/TabBinder | Veev, AcidWeb | TabBinder |
| TipTacTalents | Aezay | Talentos en el tooltip |
| PvPRating | Fernir | Experiencia de arena en el tooltip |
| AuraSource | Renstrom | Quien lanzo el buff, en el tooltip |
| FriskesUI | Friskes | MiniBar (FriskesBar) |
| RougeUI | — | ClassOutline |
| MageNuggets | — | ClassTimers |
| MySlot | tg123 | SlotProfiles |
| MobileEnergy | B-Buck | PowerBar |
| ZAutoShot | — | AutoShotTimer |
| ShieldWatch | — | ShieldWatch |
| !ComboWatch | — | ComboWatch |
| DisplayDungeon | Smokey | DungeonRoles |
| PartyFramesImproved | SoupsBelly, que viene de UnitFramesImproved (kiforsbe) y PartyTarget (Valconeye) | PartyFramesImproved |
| Abbreviated Status Text | RomanSpector | AbbreviatedStatus (reimplementado) |
| Arena Points Calculator | — | ArenaPointsCalc |
| AutoSell, ErrorHide | FatalEntity | Ambos módulos |
| Varias WeakAuras | — | PaladinAuras, SacredShield, SacredShieldTracker, SeductionAlert, EnemySpellAlert, temporizador de Dalaran |

Integración, port a 3.3.5a, corrección de bugs y todo lo demás: **Nidhaus**.

## Changelog

### v3.9
- Pestana Pet: checkbox de Pet Buffs, un boton Move que destraba solo el marco de la mascota (sin los marcos de prueba del grupo, el de arena ni la consola) y un Reset que toca solo la mascota. Antes le cambiaba el tamano a los marcos del grupo con el 3v3 puesto: la escala del grupo tenia un tercer dueno escondido en las posiciones del modo mover. Los valores viejos guardados se borran solos.
- Modo party 3v3: la escala ya no se rompe al volver a prenderlo despues de usar Party Frame Scale, los marcos del grupo que arrastras con el 3v3 puesto quedan donde los soltas, y el checkbox y los cuatro sliders por miembro estan tambien en Frames > General.
- Un solo boton "Reiniciar escalas y posiciones" para los marcos de unidad: escala y posicion juntas, sliders del 3v3 incluidos, respetando el 3v3 y sin /reload.
- Focus Scale se aplica en vivo mientras arrastras. Una entrada muerta en la tabla de escalas hacia que el slider se saltara el camino en vivo.
- Cambiar el estilo de los marcos o la textura custom se aplica al instante en vez de pedir /reload.
- Frames > General reorganizado: escalas arriba en dos columnas parejas (Player / Target / Focus y 3v3), posicion abajo con Unlock y Reset lado a lado.
- Character Setup ahora incluye nExtraBars: los 24 botones de los dos talentos, sus macros, que barras estan prendidas, cantidad de botones y bloqueo. Clear Bars y Undo tambien las cubren. Cada personaje se guarda ademas al salir, asi se copia lo que armaste durante la sesion. Con nExtraBars 2.2.3 la config de las barras se aplica sin /reload.
- Party Casting Bars: mover una barra mueve las cuatro, y su reset devuelve las cuatro.
- Hide Action Bar Textures y el "Hide bar background" de MiniBar ya no se pelean al prenderlos y apagarlos.
- Contador de municion: boton Lock / Unlock, `/arrowcount lock | unlock`, y se traba solo en combate.
- Los resets ya no escriben en el chat.

### v3.8
- El nombre de los companeros de party ya no se desliza sobre la barra de vida en plena pelea. Blizzard lo reancla en cada actualizacion del grupo, y el reestilado se cortaba en combate.
- Character Setup lista solo personajes de tu clase. Las otras cuentas de WoW siguen siendo Exportar / Importar: el juego nunca carga sus datos.
- El Gargoyle Tracker anda en cualquier idioma. El nombre de la criatura se aprende del evento de invocacion en vez de venir fijo en ingles, y se recuerda por idioma.
- Se fue la franja gris que quedaba debajo de las barras de accion. Se la buscaba por un nombre que no existe, asi que nunca se ocultaba nada y nunca saltaba ningun error.
- Arena: test de 2, 3 y 5 marcos como sArena; Pet Style solo en el estilo Flat; ancho por defecto de Flat en 100.
- El Arena Points Calculator aparece al primer toggle en vez de necesitar un cambio de pestana, y su posicion quedo fija.
- El modo de party 3v3 no tenia ninguna guarda de combate; ahora si.
- Lorti UI vuelve a tenir el marco del objetivo de party.
- La pestana de perfiles ahora se llama "Perfiles / MySlot", y el boton del pie se mide segun su texto en vez de un ancho fijo.

### v3.7
- En vehiculo, los marcos de party vuelven a la barra de vida y al fondo propios de Blizzard.
- MiniBar ya no pelea con la barra del vehiculo mientras manejas (demoledores, canones).
- El micromenu queda por encima de la barra del vehiculo en vez de dibujarse detras de su chapa.
- Los tiempos de control del Gargoyle Tracker respetan la duracion en PvP (Turn Evil marca 10s, no 20s).
- Move Everything solo ofrece el marco de mascota a las clases que realmente tienen una.
- La barra de casteo mantiene escala y posicion al encenderla y apagarla, y sigue andando con Move Everything.
- El desplegable de perfiles agrupa los personajes por reino en vez de irse de pantalla.
- Marcos de mascota para party1-4, solo en arena por defecto (`/ppf arena`).
- Las pestanas de la ventana de opciones se achican y se juntan al achicar la ventana.
- Minimapa: la forma cuadrada ahora carga la textura del borde default de Blizzard.
- La casilla de marcos de arena y las sub-opciones de Lorti UI llamaban a funciones que no existian; las dos andan.
- Sacados los comandos de diagnostico que habian quedado.
- Traduccion al espanol completa: no queda ninguna cadena sin su version en ambos idiomas.

### v3.6
- Arregladas las opciones del menú de estilos
- Arreglados problemas de visualización de texto
- Arreglados varios bugs de marcos
- El panel de opciones ahora viene junto al addon, en la misma descarga

## Licencia

Todos los derechos reservados. Este addon se provee tal cual, para uso personal.
