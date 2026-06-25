// ==========================================
// LLAVERO PARAMÉTRICO - CENTRO DE ESTUDIANTES
// Ecosistema: Disenos-e-impresiones-3D
// ==========================================

// --- PARÁMETROS CONFIGURABLES ---

// 1. Tipo de Base y Geometría General
tipo_base = "rect";          // [rect: Rectangular, oval: Elíptica, circ: Circular]
ancho_llavero = 45.0;       // Ancho total del llavero (en mm)
largo_llavero = 45.0;       // Largo total del llavero (en mm)
esquinas_r = 5.0;           // Radio de las esquinas (solo para tipo_base = "rect")

// 2. Alturas y Espesores (en mm)
espesor_base = 2.0;         // Grosor de la placa base
espesor_logo = 1.0;         // Altura del relieve del logo (frontal)
espesor_borde = 1.0;        // Altura del relieve del borde protector (frontal)
espesor_texto = 1.0;        // Altura del relieve del texto "icif" (frontal o reverso)
borde_ancho = 1.5;          // Ancho de la pared del borde protector

// 3. Orificio de la Argolla
anillo_d_int = 4.0;         // Diámetro del agujero para la argolla
anillo_d_ext = 8.0;         // Diámetro exterior de la oreja
anillo_pos = "top_left";    // [top_left, top_right, top_center, left_center]

// 4. Configuración del Logo y Texto
// "reverso"         -> Logo completo en el frente, "icif" grabado atrás
// "frontal_replace" -> Cerebro solo arriba, "icif" abajo reemplazando "BIT A BIT"
// "frontal_add"     -> Logo completo arriba, "icif" abajo adicional
tipo_texto_icif = "reverso"; 
logo_escala = 0.32;         // Escala del logo (ajustar según el tamaño del llavero)
logo_offset_y = 2.0;        // Desplazamiento en Y para centrar visualmente el logo
texto_icif = "icif";        // Texto de la carrera/centro
texto_size = 6.0;           // Tamaño de la fuente para el texto

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

// Recorte del cerebro solo (sin el texto BIT A BIT)
module logo_cerebro_solo_2d() {
    intersection() {
        import("logo.svg", center=true);
        // El cerebro en el SVG normalizado a 100 está en la mitad superior (Y > -20)
        translate([-60, -20]) square([120, 80]);
    }
}

// Logo completo con el texto "BIT A BIT"
module logo_completo_2d() {
    import("logo.svg", center=true);
}

// --- ENSAMBLE GENERAL ---

union() {
    // 1. Cuerpo Principal del Llavero (Base y Oreja)
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
    
    // 3. Detalles Frontales (Logo y Texto según configuración)
    translate([0, logo_offset_y, espesor_base]) {
        if (tipo_texto_icif == "reverso") {
            // Frente: Logo completo ("Cerebro" + "BIT A BIT")
            linear_extrude(height=espesor_logo) {
                scale([logo_escala, logo_escala, 1]) {
                    logo_completo_2d();
                }
            }
        } 
        else if (tipo_texto_icif == "frontal_replace") {
            // Frente: Cerebro arriba y texto "icif" abajo
            linear_extrude(height=espesor_logo) {
                scale([logo_escala, logo_escala, 1]) {
                    // Elevar el cerebro para dar espacio al texto
                    translate([0, 8, 0]) logo_cerebro_solo_2d();
                }
            }
            // Escribir "icif" abajo
            translate([0, -largo_llavero/3.5, 0])
            linear_extrude(height=espesor_texto) {
                text(texto_icif, size=texto_size, font="Liberation Sans:style=Bold", halign="center", valign="center");
            }
        }
        else if (tipo_texto_icif == "frontal_add") {
            // Frente: Logo completo escalado más pequeño + texto "icif" en la base
            linear_extrude(height=espesor_logo) {
                scale([logo_escala * 0.85, logo_escala * 0.85, 1]) {
                    translate([0, 10, 0]) logo_completo_2d();
                }
            }
            // Escribir "icif" abajo en relieve
            translate([0, -largo_llavero/3.2, 0])
            linear_extrude(height=espesor_texto) {
                text(texto_icif, size=texto_size * 0.8, font="Liberation Sans:style=Bold", halign="center", valign="center");
            }
        }
    }
    
    // 4. Detalles Traseros (Bajorrelieve invertido de "icif" si es tipo "reverso")
    if (tipo_texto_icif == "reverso") {
        // Para bajorrelieve restamos la geometría al cuerpo base
        // Nota: En OpenSCAD para grabados físicos se usa difference sobre todo el modelo,
        // pero para evitar modificar el ensamble superior, aplicamos una substracción en Z del cuerpo base
        // al reverso de la pieza (espejado en X para que al dar vuelta el llavero se lea al derecho)
        // Haremos esto de forma segura.
    }
}

// Si la opción es reverso, aplicamos la sustracción en un difference final
// para lograr el bajorrelieve en la cara inferior (Z=0).
// Para no romper la modularidad, envolvemos todo en una diferencia lógica condicional.
// (Esta es la forma estándar e infalible de hacer bajorrelieves en OpenSCAD)
module llavero_final() {
    difference() {
        // Modelo base (Cuerpo + Borde + Logo frontal)
        union() {
            linear_extrude(height=espesor_base) {
                union() {
                    base_2d();
                    oreja_2d();
                }
            }
            
            translate([0, 0, espesor_base])
            linear_extrude(height=espesor_borde) {
                borde_borde_2d();
            }
            
            translate([0, logo_offset_y, espesor_base]) {
                if (tipo_texto_icif == "reverso") {
                    linear_extrude(height=espesor_logo) {
                        scale([logo_escala, logo_escala, 1]) {
                            logo_completo_2d();
                        }
                    }
                } 
                else if (tipo_texto_icif == "frontal_replace") {
                    linear_extrude(height=espesor_logo) {
                        scale([logo_escala, logo_escala, 1]) {
                            translate([0, 8, 0]) logo_cerebro_solo_2d();
                        }
                    }
                    translate([0, -largo_llavero/3.5, 0])
                    linear_extrude(height=espesor_texto) {
                        text(texto_icif, size=texto_size, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    }
                }
                else if (tipo_texto_icif == "frontal_add") {
                    linear_extrude(height=espesor_logo) {
                        scale([logo_escala * 0.85, logo_escala * 0.85, 1]) {
                            translate([0, 10, 0]) logo_completo_2d();
                        }
                    }
                    translate([0, -largo_llavero/3.2, 0])
                    linear_extrude(height=espesor_texto) {
                        text(texto_icif, size=texto_size * 0.8, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    }
                }
            }
        }
        
        // Grabado en el reverso (Z=0, entra 0.8 mm en la base)
        if (tipo_texto_icif == "reverso") {
            translate([0, 0, -0.1])
            linear_extrude(height=0.9) {
                // Espejado en X para que al girar la pieza física se lea correctamente
                mirror([1, 0, 0]) {
                    text(texto_icif, size=texto_size * 1.2, font="Liberation Sans:style=Bold", halign="center", valign="center");
                }
            }
        }
    }
}

// Invocar el módulo final
llavero_final();
