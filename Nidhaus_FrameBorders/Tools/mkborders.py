# Genera los edgeFile de Nidhaus_UnitFrames desde cero (geometria pura).
# Tira 8 casillas: izq, der, arriba, abajo, sup-izq, sup-der, inf-izq, inf-der.
# En WoW las casillas 2 y 3 (arriba/abajo) son copias de 0 y 1: el motor las rota.
import math, struct, os

def write_tga(path, w, h, rows):          # rows[0] = fila de ARRIBA
    hdr = struct.pack('<BBBHHBHHHHBB', 0,0,2, 0,0,0, 0,0, w,h, 32, 0x08)
    out = bytearray(hdr)
    for y in range(h-1, -1, -1):          # TGA: origen abajo-izquierda
        for (r,g,b,a) in rows[y]:
            out += bytes((b,g,r,a))
    open(path,'wb').write(bytes(out))

def build(S, profile, origin, glow=False):
    """profile(d)->0..1 ; origin = punto donde el borde se redondea."""
    W = S*8
    rows = [[(255,255,255,0)]*W for _ in range(S)]
    def alpha(dx, dy, has_x, has_y):
        # dx/dy = distancia al filo EXTERIOR en ese eje (None si ese eje no es filo)
        if has_x and has_y:
            if dx < origin and dy < origin:
                d = origin - math.hypot(origin-dx, origin-dy)
                if d < 0: d = 0.0
            elif dx < origin: d = dx
            elif dy < origin: d = dy
            else:             d = min(dx, dy)
        elif has_x: d = dx
        else:       d = dy
        return max(0.0, min(1.0, profile(d)))
    for y in range(S):
        for x in range(S):
            L = x + 0.5;  R = S - x - 0.5      # dist. al filo izq / der
            T = y + 0.5;  B = S - y - 0.5      # dist. al filo sup / inf
            vals = [
                alpha(L, 0, True,  False),     # 0 izquierda
                alpha(R, 0, True,  False),     # 1 derecha
                alpha(L, 0, True,  False),     # 2 arriba  (= 0, el motor rota)
                alpha(R, 0, True,  False),     # 3 abajo   (= 1, el motor rota)
                alpha(L, T, True,  True),      # 4 sup-izq
                alpha(R, T, True,  True),      # 5 sup-der
                alpha(L, B, True,  True),      # 6 inf-izq
                alpha(R, B, True,  True),      # 7 inf-der
            ]
            for s, a in enumerate(vals):
                rows[y][s*S + x] = (255,255,255, int(round(a*255)))
    return W, S, rows

# ---- perfiles -------------------------------------------------------------
def p_light(d):                    # hilo fino, 16 texeles / edgeSize 14
    return max(0.0, 1.0 - abs(d-3.5)/3.0) ** 1.6
def p_soft(d):                     # 1 px macizo + pluma, 32 tex / edgeSize 12
    t = abs(d-2.2)
    if t <= 1.4: return 1.0
    return max(0.0, 1.0 - (t-1.4)/2.8) ** 1.3
def p_pixel(d):                    # 1 px duro, sin pluma, 32 tex / edgeSize 10
    return 1.0 if d < 3.2 else 0.0
def p_glow(d):                     # halo: nulo afuera, lleno contra el marco
    return (d/16.0) ** 1.4

OUT = os.path.expanduser("~/mnt/addons/Nidhaus_FrameBorders/Media/Border/")
# El cuarto valor es "origin": el centro del arco de la esquina, medido en
# texeles desde el filo. origin - (centro de la linea) es el RADIO.
#
#   Soft  -> 2.2 + 12 : radio de 12 texeles. Con casillas de 32 dibujadas a
#            10 px eso son ~3.7 px de redondeo, que es lo que se ve en las
#            barras de accion. Antes era 3 (menos de un pixel) y las
#            esquinas salian practicamente en escuadra.
#   Pixel -> sin redondeo: es el estilo recto a proposito, la alternativa.
#   Light -> 3.5 + 3.5 : el redondeo suave que ya tenia el minimapa.
jobs = [
    ("Border_Soft.tga",  32, p_soft,  2.2+12.0),
    ("Border_Glow.tga",  16, p_glow,  16.0),
]
for name, S, prof, origin in jobs:
    w,h,rows = build(S, prof, origin)
    write_tga(OUT+name, w, h, rows)
    print("escrito", name, w, "x", h, os.path.getsize(OUT+name), "bytes")
