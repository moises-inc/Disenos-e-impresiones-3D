// ==========================================
// LLAVERO PARAMÉTRICO - CENTRO DE ESTUDIANTES "bit a bit"
// Ecosistema: Disenos-e-impresiones-3D
// ==========================================

// --- PARÁMETROS CONFIGURABLES ---

// 1. Tipo de Base y Geometría General
tipo_base = "circ";          // [rect: Rectangular, oval: Elíptica, circ: Circular]
ancho_llavero = 45.0;       // Ancho total del llavero (en mm)
largo_llavero = 45.0;       // Largo total del llavero (en mm)
esquinas_r = 6.0;           // Radio de las esquinas (solo para tipo_base = "rect")

// 2. Alturas y Espesores (en mm)
espesor_base = 2.2;         // Grosor de la placa base (2.2 mm da excelente rigidez)
espesor_logo = 1.0;         // Altura del relieve del logo (frontal)
espesor_borde = 1.0;        // Altura del relieve del borde protector (frontal)
espesor_texto = 1.0;        // Altura del relieve de los textos (frontal)
borde_ancho = 1.6;          // Ancho de la pared del borde protector

// 3. Orificio de la Argolla
anillo_d_int = 4.2;         // Diámetro del agujero para la argolla (holgado)
anillo_d_ext = 8.5;         // Diámetro exterior de la oreja
anillo_pos = "top_left";    // [top_left, top_right, top_center, left_center]

// 4. Configuración del Logo y Texto
// "reverso"         -> Frente: Cerebro centrado + "bit a bit". Reverso: "icif" grabado
// "frontal_replace" -> Frente: "icif" arriba, Cerebro al centro, "bit a bit" abajo (Simétrico Split)
// "frontal_add"     -> Frente: Cerebro centrado, "bit a bit" abajo, "icif" en segunda línea abajo
tipo_texto_icif = "frontal_replace"; 
logo_escala = 0.35;         // Escala del cerebro (ajustado para centrado exacto)
texto_bit = "bit a bit";    // Nombre del centro en minúsculas
texto_icif = "icif";        // Sigla de la carrera
size_bit = 4.8;             // Tamaño de fuente para "bit a bit"
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

// Oreja para la argolla del llavero (en 2D)
module oreja_2d() {
    w_ref = (tipo_base == "circ") ? max(ancho_llavero, largo_llavero) : ancho_llavero;
    l_ref = (tipo_base == "circ") ? max(ancho_llavero, largo_llavero) : largo_llavero;
    
    // Determinar posición del centro de la oreja
    offset_x = (anillo_pos == "top_left") ? -w_ref/2 + 2 : 
               (anillo_pos == "top_right") ? w_ref/2 - 2 : 
               (anillo_pos == "left_center") ? -w_ref/2 + 2 : 0;
               
    offset_y = (anillo_pos == "top_left" || anillo_pos == "top_right" || anillo_pos == "top_center") ? l_ref/2 - 2 : 0;
    
    // Ángulo de inclinación según posición
    rot_ang = (anillo_pos == "top_left") ? 135 :
              (anillo_pos == "top_right") ? 45 :
              (anillo_pos == "left_center") ? 180 : 90;

    translate([offset_x, offset_y, 0])
    rotate([0, 0, rot_ang])
    translate([0, anillo_d_ext/2, 0])
    difference() {
        circle(d=anillo_d_ext);
        circle(d=anillo_d_int);
    }
}

// Cerebro recortado y centrado matemáticamente en (0,0)
module logo_cerebro_centrado_2d() {
    // El cerebro del SVG normalizado a 100 está desplazado en Y.
    // Un offset de Y=-16 lo centra perfectamente en el origen (0,0).
    translate([0, -16, 0]) {
        intersection() {
            import("logo.svg", center=true);
            // Rectángulo de recorte para excluir las letras vectorizadas del SVG original
            translate([-60, -20]) square([120, 80]);
        }
    }
}

// --- ENSAMBLE GENERAL CON COMPENSACIÓN DE CENTRADO ---

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
                    // Frente: Cerebro centrado desplazado ligeramente hacia arriba y "bit a bit" abajo
                    translate([0, 3.0, 0])
                    linear_extrude(height=espesor_logo) {
                        scale([logo_escala, logo_escala, 1]) logo_cerebro_centrado_2d();
                    }
                    
                    // Texto "bit a bit" abajo
                    translate([0, -largo_llavero/3.5, 0])
                    linear_extrude(height=espesor_texto) {
                        text(texto_bit, size=size_bit, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    }
                } 
                else if (tipo_texto_icif == "frontal_replace") {
                    // Frente Simétrico Split: "icif" arriba, Cerebro en el medio, "bit a bit" abajo
                    
                    // Texto "icif" arriba
                    translate([0, largo_llavero/3.4, 0])
                    linear_extrude(height=espesor_texto) {
                        text(texto_icif, size=size_icif, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    }
                    
                    // Cerebro al centro (Y = -1.0 para equilibrio visual)
                    translate([0, -1.0, 0])
                    linear_extrude(height=espesor_logo) {
                        scale([logo_escala * 0.9, logo_escala * 0.9, 1]) logo_cerebro_centrado_2d();
                    }
                    
                    // Texto "bit a bit" abajo
                    translate([0, -largo_llavero/3.4, 0])
                    linear_extrude(height=espesor_texto) {
                        text(texto_bit, size=size_bit * 0.95, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    }
                }
                else if (tipo_texto_icif == "frontal_add") {
                    // Frente Compacto: Cerebro arriba y doble línea de texto abajo ("bit a bit" e "icif")
                    translate([0, 4.0, 0])
                    linear_extrude(height=espesor_logo) {
                        scale([logo_escala * 0.9, logo_escala * 0.9, 1]) logo_cerebro_centrado_2d();
                    }
                    
                    // Texto "bit a bit" (Línea 1 abajo)
                    translate([0, -largo_llavero/4.2, 0])
                    linear_extrude(height=espesor_texto) {
                        text(texto_bit, size=size_bit * 0.9, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    }
                    
                    // Texto "icif" (Línea 2 abajo)
                    translate([0, -largo_llavero/2.75, 0])
                    linear_extrude(height=espesor_texto) {
                        text(texto_icif, size=size_icif * 0.8, font="Liberation Sans:style=Bold", halign="center", valign="center");
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
