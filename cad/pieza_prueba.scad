// Pieza de Prueba Paramétrica
base_r = 15.0; // Radio de la base circular
altura = 20.0; // Altura total de la pieza de prueba
agujero_d = 3.2; // Diámetro del orificio central para tornillo M3
soporte_espesor = 2.0; // Espesor del nervio de refuerzo triangular

$fn = $preview ? 12 : 72;

difference() {
    union() {
        // Cuerpo principal
        cylinder(r=base_r, h=altura);
        
        // Nervio de refuerzo
        translate([0, -soporte_espesor/2, 0])
        cube([base_r + 10, soporte_espesor, altura]);
    }
    
    // Agujero pasante central para tornillo M3
    translate([0, 0, -1])
    cylinder(d=agujero_d, h=altura + 2);
}
