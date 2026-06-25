#!/usr/bin/env python3
import os
import sys
import re
import argparse
from datetime import datetime

def parse_scad_variables(scad_path):
    """Analiza el archivo .scad para extraer variables globales parametrizadas al inicio."""
    variables = []
    
    if not os.path.exists(scad_path):
        print(f"[-] Error: Archivo fuente no encontrado para analizar: {scad_path}")
        return variables

    # Patrón Regex para identificar variables globales de OpenSCAD
    # Captura: nombre = valor; // comentario descriptivo opcional
    var_pattern = re.compile(r'^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*([^;]+);(?:\s*\/\/\s*(.*))?')

    with open(scad_path, 'r', encoding='utf-8') as f:
        for line in f:
            line_str = line.strip()
            
            # Detener el análisis si encontramos la definición de un módulo o función
            if line_str.startswith("module ") or line_str.startswith("function "):
                break
                
            # Omitir comentarios de bloque o líneas comentadas completas
            if line_str.startswith("//") or line_str.startswith("/*") or not line_str:
                continue
                
            match = var_pattern.match(line_str)
            if match:
                var_name = match.group(1).strip()
                var_val = match.group(2).strip()
                var_desc = match.group(3).strip() if match.group(3) else "Parámetro de diseño."
                
                # Ignorar variables de control como $fn o variables locales de control
                if not var_name.startswith("$"):
                    variables.append({
                        "name": var_name,
                        "value": var_val,
                        "description": var_desc
                    })
                    
    return variables

def generate_markdown_log(scad_path, output_dir, variables):
    """Genera el archivo markdown de bitácora en la carpeta de bitácoras."""
    base_name = os.path.splitext(os.path.basename(scad_path))[0]
    output_path = os.path.join(output_dir, f"{base_name}.md")
    
    current_date = datetime.now().strftime("%Y-%m-%d")
    
    scad_rel = os.path.relpath(scad_path, start=os.path.dirname(output_dir))
    stl_rel = f"cad/stl/{base_name}.stl"
    
    # Construir contenido Markdown
    lines = [
        "---",
        "tipo: bitacora_pieza",
        "proyecto: USS Spiderbot",
        f"pieza: {base_name}",
        f"scad_source: {scad_rel}",
        f"stl_output: {stl_rel}",
        f"fecha_creacion: {current_date}",
        "---",
        "",
        f"# Bitácora de Diseño y Fabricación: {base_name}",
        "",
        "[[Disenos-e-impresiones-3D]] | [[Impresión 3D]]",
        "",
        "## 1. Parámetros Paramétricos (OpenSCAD)",
        "Valores de diseño extraídos automáticamente del archivo de origen:",
        "",
        "| Parámetro | Valor por Defecto | Descripción / Función |",
        "| :--- | :--- | :--- |"
    ]
    
    if variables:
        for var in variables:
            lines.append(f"| `{var['name']}` | `{var['value']}` | {var['description']} |")
    else:
        lines.append("| (Ninguno) | - | No se detectaron variables globales paramétricas en el archivo. |")
        
    lines.extend([
        "",
        "## 2. Planificación de Fabricación y Slicing",
        "Selecciona la impresora utilizada y completa los parámetros específicos para el rebanado (CrealityPrint):",
        "",
        "### Impresora de Destino:",
        "- [ ] **Creality K1** (CoreXY - Klipper. Velocidad recomendada: 250-300 mm/s)",
        "- [ ] **Ender V3 KE** (Cartesiana - Klipper. Velocidad recomendada: 150-200 mm/s)",
        "- [ ] **Ender V3 SE** (Cartesiana - Marlin. Velocidad recomendada: 50-80 mm/s)",
        "",
        "### Parámetros Genéricos de Impresión:",
        "",
        "| Parámetro de Corte | Valor Sugerido (PLA) | Ajuste Utilizado | Notas / Justificación |",
        "| :--- | :--- | :--- | :--- |",
        "| **Temperatura de Boquilla** | 200 - 220 °C | | |",
        "| **Temperatura de Cama** | 60 °C | | |",
        "| **Densidad de Infill (Relleno)** | 20 % | | Estructural, aumentar a 30-40% si sufre carga mecánica |",
        "| **Patrón de Relleno** | Giroide (Gyroid) | | Mayor resistencia multidireccional |",
        "| **Altura de Capa** | 0.20 mm | | Equilibrio entre velocidad y acabado |",
        "| **Soportes** | No / Según Geometría | | Evitar si es posible para mantener el acabado superficial |",
        "| **Adherencia a Cama** | Falda (Skirt) | | Borde (Brim) si hay riesgo de warping |",
        "",
        "## 3. Control de Calidad y Ajustes Mecánicos (Tolerancias)",
        "Valores críticos de tolerancia de impresión a validar después de fabricar (comparar con pie de metro):",
        "",
        "| Característica / Ajuste | Dimensión Modelada | Dimensión Real Medida | Desviación (mm) | Estado (Ajusta / OK) |",
        "| :--- | :--- | :--- | :--- | :--- |",
        "| **Orificios M3 (Tornillería)** | r = 1.6 mm (Ø 3.2 mm) | | | |",
        "| **Paso de Tornillo M2 (Rosca)** | r = 1.0 mm (Ø 2.0 mm) | | | |",
        "| **Caja de Servomotor SG90** | Ancho 25.0 mm | | | |",
        "| **Acople de Horn (Corona)** | r = 4.0 mm (Ø 8.0 mm) | | | |",
        "| **Brazo Rectangular de Horn** | 16.0 x 5.2 mm | | | |",
        "",
        "## 4. Métricas de Impresión y Post-Procesado",
        "- **Tiempo Estimado (Slicer):** `__h __m`",
        "- **Tiempo Real de Impresión:** `__h __m`",
        "- **Consumo de Filamento:** `____ gramos` / `____ metros`",
        "- **Post-Procesado Realizado:**",
        "  - [ ] Remoción de soportes",
        "  - [ ] Limpieza de rebabas / lijado suave",
        "  - [ ] Roscado directo preliminar de tornillos",
        "- **Observaciones Generales:** (Anotar si hubo warping, problemas de adherencia, hilachas o defectos estéticos)",
        "",
        "---",
        "**Historial del Grafo:** [USS Spiderbot Docs](file:///mnt/9b846436-0407-4e80-b8af-5417ffbdee8e/Github/USS%20SPIDERBOT%20(solemne%203)/docs/)"
    ])
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("\n".join(lines))
        
    print(f"[+] Bitácora creada exitosamente en: {output_path}")
    return True

def main():
    parser = argparse.ArgumentParser(description="Generador automático de Bitácoras de Impresión 3D para Obsidian.")
    parser.add_argument("-i", "--input", required=True, help="Ruta del archivo de diseño .scad del cual extraer parámetros.")
    parser.add_argument("-o", "--output-dir", default="bitacoras", help="Directorio de destino para la bitácora (por defecto 'bitacoras')")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        print(f"[-] Error: El archivo fuente .scad especificado no existe: {args.input}")
        sys.exit(1)
        
    os.makedirs(args.output_dir, exist_ok=True)
    
    # Extraer variables
    variables = parse_scad_variables(args.input)
    print(f"[*] Escaneando '{os.path.basename(args.input)}'... Encontradas {len(variables)} variables paramétricas.")
    
    # Generar bitácora
    success = generate_markdown_log(args.input, args.output_dir, variables)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
