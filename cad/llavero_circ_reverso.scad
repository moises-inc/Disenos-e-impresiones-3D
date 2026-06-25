// ==========================================
// LLAVERO PARAMÉTRICO - CENTRO DE ESTUDIANTES "bit a bit 3.0"
// Ecosistema: Disenos-e-impresiones-3D
// ==========================================

// --- PARÁMETROS CONFIGURABLES ---

// 1. Tipo de Base y Geometría General
tipo_base = "circ";          // [rect: Rectangular, oval: Elíptica, circ: Circular]
ancho_llavero = 55.0;       // Ancho total del llavero (en mm) - Aumentado para dar espacio al agujero interno
largo_llavero = 55.0;       // Largo total del llavero (en mm) - Aumentado para dar espacio al agujero interno
esquinas_r = 6.0;           // Radio de las esquinas (solo para tipo_base = "rect")

// 2. Alturas y Espesores (en mm)
espesor_base = 2.2;         // Grosor de la placa base
espesor_logo = 1.0;         // Altura del relieve del logo (frontal)
espesor_borde = 1.0;        // Altura del relieve del borde protector (frontal)
espesor_texto = 1.0;        // Altura del relieve de los textos (frontal)
borde_ancho = 1.6;          // Ancho de la pared del borde protector

// 3. Orificio de la Argolla (Ahora INTERNO en todos los llaveros)
anillo_d_int = 4.2;         // Diámetro del agujero para la argolla
anillo_d_ext = 8.5;         // Diámetro exterior del rim protector
anillo_pos = "top_left";    // [top_left, top_right, top_center, left_center]

// 4. Configuración del Logo y Texto
// "reverso"         -> Frente: Logo engranaje centrado. Reverso: "icif" grabado
// "frontal_replace" -> Frente: "icif" arriba, Logo engranaje centrado (Simétrico Split)
// "frontal_add"     -> Frente: Logo engranaje centrado, "icif" abajo adicional en relieve
tipo_texto_icif = "reverso"; 
logo_escala = 0.35;         // Escala del logo de engranaje "bit a bit 3.0" (ajustado para centrado y no colisión con agujero)
texto_icif = "icif";        // Sigla de la carrera
size_icif = 5.5;            // Tamaño de fuente para "icif"

// Resolución de curvas
$fn = $preview ? 12 : 72;

// --- MÓDULOS DE SOPORTE ---

// Base 2D según el tipo
module base_2d() {
    if (tipo_base == "rect") {
        hull() {
            translate([-ancho_llavero/2 + esquinas_r, -largo_llavero/2 + esquinas_r]) circle(r=esquinas_r);
            translate([ ancho_llavero/2 - esquinas_r, -largo_llavero/2 + esquinas_r]) circle(r=esquinas_r);
            translate([-ancho_llavero/2 + esquinas_r,  largo_llavero/2 - esquinas_r]) circle(r=esquinas_r);
            translate([ ancho_llavero/2 - esquinas_r,  largo_llavero/2 - esquinas_r]) circle(r=esquinas_r);
        }
    } else if (tipo_base == "oval") {
        scale([ancho_llavero/100, largo_llavero/100, 1]) circle(d=100);
    } else if (tipo_base == "circ") {
        circle(d=max(ancho_llavero, largo_llavero));
    }
}

// Borde protector 2D
module borde_borde_2d() {
    difference() {
        base_2d();
        offset(r=-borde_ancho) base_2d();
    }
}

// Función paramétrica para calcular la posición exacta del orificio del llavero.
// Ubica el orificio en el interior, de forma que su rim exterior quede exactamente tangente
// a la parte interna del borde protector de la base.
function get_hole_pos() = 
    let(
        w_ref = (tipo_base == "circ") ? max(ancho_llavero, largo_llavero) : ancho_llavero,
        l_ref = (tipo_base == "circ") ? max(ancho_llavero, largo_llavero) : largo_llavero,
        ang = (anillo_pos == "top_left") ? 135 :
              (anillo_pos == "top_right") ? 45 :
              (anillo_pos == "left_center") ? 180 : 90
    )
    (tipo_base == "rect") ? [
        ((anillo_pos == "top_left" || anillo_pos == "left_center") ? -w_ref/2 + borde_ancho + anillo_d_ext/2 : 
         (anillo_pos == "top_right") ? w_ref/2 - borde_ancho - anillo_d_ext/2 : 0),
        ((anillo_pos == "top_left" || anillo_pos == "top_right" || anillo_pos == "top_center") ? l_ref/2 - borde_ancho - anillo_d_ext/2 : 0)
    ] : [
        // Para óvalos y círculos, calculamos el punto en el perímetro elíptico en el ángulo seleccionado
        let(
            a = w_ref / 2,
            b = l_ref / 2,
            R_theta = 1 / sqrt( pow(cos(ang)/a, 2) + pow(sin(ang)/b, 2) ),
            d = R_theta - borde_ancho - anillo_d_ext / 2
        )
        d * cos(ang),
        let(
            a = w_ref / 2,
            b = l_ref / 2,
            R_theta = 1 / sqrt( pow(cos(ang)/a, 2) + pow(sin(ang)/b, 2) ),
            d = R_theta - borde_ancho - anillo_d_ext / 2
        )
        d * sin(ang)
    ];

// Rim o reborde protector elevado del orificio del llavero (en 2D)
module rim_agujero_2d() {
    pos = get_hole_pos();
    translate(pos)
    difference() {
        circle(d=anillo_d_ext);
        circle(d=anillo_d_int);
    }
}

// Logo completo del engranaje central (ya binarizado y centrado en (0,0) nativo)
module logo_engranaje_2d() {
    import("logo.svg", center=true);
}

// --- ENSAMBLE GENERAL ---

module llavero_final() {
    pos_hole = get_hole_pos();
    difference() {
        // Modelo base (Cuerpo + Borde + Elementos frontales)
        union() {
            // 1. Placa Base (Sólida, sin oreja exterior)
            linear_extrude(height=espesor_base) {
                base_2d();
            }
            
            // 2. Borde Protector Frontal y Rim del Agujero Interno
            translate([0, 0, espesor_base])
            linear_extrude(height=espesor_borde) {
                borde_borde_2d();
                rim_agujero_2d();
            }
            
            // 3. Elementos Frontales en Relieve
            translate([0, 0, espesor_base]) {
                if (tipo_texto_icif == "reverso") {
                    // Frente: Engranaje del logo centrado en Y=0
                    linear_extrude(height=espesor_logo) {
                        scale([logo_escala, logo_escala, 1]) logo_engranaje_2d();
                    }
                } 
                else if (tipo_texto_icif == "frontal_replace") {
                    // Frente Split: "icif" arriba y Logo engranaje desplazado ligeramente abajo
                    
                    // Texto "icif" arriba
                    translate([0, largo_llavero/3.2, 0])
                    linear_extrude(height=espesor_texto) {
                        text(texto_icif, size=size_icif, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    }
                    
                    // Logo central
                    translate([0, -3.0, 0])
                    linear_extrude(height=espesor_logo) {
                        scale([logo_escala * 0.88, logo_escala * 0.88, 1]) logo_engranaje_2d();
                    }
                }
                else if (tipo_texto_icif == "frontal_add") {
                    // Frente Adicional: Logo engranaje desplazado arriba e "icif" abajo en relieve
                    
                    translate([0, 3.5, 0])
                    linear_extrude(height=espesor_logo) {
                        scale([logo_escala * 0.88, logo_escala * 0.88, 1]) logo_engranaje_2d();
                    }
                    
                    // Texto "icif" abajo
                    translate([0, -largo_llavero/3.2, 0])
                    linear_extrude(height=espesor_texto) {
                        text(texto_icif, size=size_icif, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    }
                }
            }
        }
        
        // 4. Subtraer Orificio del Llavero (a través de la base y del rim)
        translate([pos_hole[0], pos_hole[1], -1])
        cylinder(d=anillo_d_int, h=espesor_base + espesor_borde + 2);
        
        // 5. Grabado en el reverso: "icif" en bajorrelieve (Solo para opción reverso)
        if (tipo_texto_icif == "reverso") {
            translate([0, 0, -0.1])
            linear_extrude(height=0.9) {
                // Espejado en X para lectura correcta al dar vuelta la pieza física
                mirror([1, 0, 0]) {
                    text(texto_icif, size=size_icif * 1.3, font="Liberation Sans:style=Bold", halign="center", valign="center");
                }
            }
        }
    }
}

// Invocación final
llavero_final();
