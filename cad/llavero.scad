// ==========================================
// LLAVERO PARAMÉTRICO - CENTRO DE ESTUDIANTES "bit a bit 3.0"
// Ecosistema: Disenos-e-impresiones-3D
// ==========================================

// --- PARÁMETROS CONFIGURABLES ---

// 1. Tipo de Base y Geometría General
tipo_base = "rect";          // [rect: Rectangular, oval: Elíptica, circ: Circular]
ancho_llavero = 50.0;       // Ancho total del llavero (en mm) - Aumentado para legibilidad
largo_llavero = 50.0;       // Largo total del llavero (en mm) - Aumentado para legibilidad
esquinas_r = 6.0;           // Radio de las esquinas (solo para tipo_base = "rect")

// 2. Alturas y Espesores (en mm)
espesor_base = 2.2;         // Grosor de la placa base
espesor_logo = 1.0;         // Altura del relieve del logo (frontal)
espesor_borde = 1.0;        // Altura del relieve del borde protector (frontal)
espesor_texto = 1.0;        // Altura del relieve de los textos (frontal)
borde_ancho = 1.6;          // Ancho de la pared del borde protector

// 3. Orificio de la Argolla
anillo_d_int = 4.2;         // Diámetro del agujero para la argolla
anillo_d_ext = 8.5;         // Diámetro exterior de la oreja
anillo_pos = "top_left";    // [top_left, top_right, top_center, left_center]

// 4. Configuración del Logo y Texto
// "reverso"         -> Frente: Logo engranaje centrado. Reverso: "icif" grabado
// "frontal_replace" -> Frente: "icif" arriba, Logo engranaje centrado (Simétrico Split)
// "frontal_add"     -> Frente: Logo engranaje centrado, "icif" abajo adicional en relieve
tipo_texto_icif = "reverso"; 
logo_escala = 0.38;         // Escala del logo de engranaje (ajustado para centrado exacto)
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

// Oreja para la argolla del llavero (en 2D) con corrección geométrica para óvalos/círculos
module oreja_2d() {
    w_ref = (tipo_base == "circ") ? max(ancho_llavero, largo_llavero) : ancho_llavero;
    l_ref = (tipo_base == "circ") ? max(ancho_llavero, largo_llavero) : largo_llavero;
    
    // Ángulo de posicionamiento de la oreja en coordenadas polares
    ang = (anillo_pos == "top_left") ? 135 :
          (anillo_pos == "top_right") ? 45 :
          (anillo_pos == "left_center") ? 180 : 90;
          
    // Orientación para que apunte hacia afuera radialmente
    rot_ang = (anillo_pos == "top_left") ? 135 :
              (anillo_pos == "top_right") ? 45 :
              (anillo_pos == "left_center") ? 180 : 90;

    if (tipo_base == "rect") {
        // Posición tradicional en la esquina del rectángulo
        offset_x = (anillo_pos == "top_left") ? -w_ref/2 + 2 : 
                   (anillo_pos == "top_right") ? w_ref/2 - 2 : 
                   (anillo_pos == "left_center") ? -w_ref/2 + 2 : 0;
                   
        offset_y = (anillo_pos == "top_left" || anillo_pos == "top_right" || anillo_pos == "top_center") ? l_ref/2 - 2 : 0;
        
        translate([offset_x, offset_y, 0])
        rotate([0, 0, rot_ang])
        translate([0, anillo_d_ext/2 - 1.2, 0]) // Solape controlado
        difference() {
            circle(d=anillo_d_ext);
            circle(d=anillo_d_int);
        }
    } else {
        // CÁLCULO ELÍPTICO CORRECTO: Evita que la oreja quede flotando en el aire.
        // Mapea el punto exacto en el perímetro de la elipse usando cos/sin paramétricos.
        a = w_ref / 2;
        b = l_ref / 2;
        
        // Coordenadas cartesianas sobre la elipse restando un pequeño margen de solapamiento
        offset_x = (a - 1.5) * cos(ang);
        offset_y = (b - 1.5) * sin(ang);
        
        translate([offset_x, offset_y, 0])
        rotate([0, 0, rot_ang])
        translate([0, anillo_d_ext/2 - 1.0, 0]) // Fusión sólida con el borde curvo
        difference() {
            circle(d=anillo_d_ext);
            circle(d=anillo_d_int);
        }
    }
}

// Logo completo del engranaje central (ya binarizado y centrado en (0,0) nativo)
module logo_engranaje_2d() {
    import("logo.svg", center=true);
}

// --- ENSAMBLE GENERAL ---

module llavero_final() {
    difference() {
        // Modelo base (Cuerpo + Borde + Elementos frontales)
        union() {
            // 1. Placa Base e Implante de Oreja
            linear_extrude(height=espesor_base) {
                union() {
                    base_2d();
                    oreja_2d();
                }
            }
            
            // 2. Borde Protector Frontal
            translate([0, 0, espesor_base])
            linear_extrude(height=espesor_borde) {
                borde_borde_2d();
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
        
        // Grabado en el reverso: "icif" en bajorrelieve (Solo para opción reverso)
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
