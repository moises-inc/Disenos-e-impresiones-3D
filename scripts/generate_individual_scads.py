#!/usr/bin/env python3
import os
import sys
import re

def main():
    scad_master = "cad/llavero.scad"
    if not os.path.exists(scad_master):
        print(f"[-] Error: No se encontró el archivo maestro: {scad_master}")
        sys.exit(1)
        
    print(f"[*] Leyendo archivo maestro: {scad_master}")
    with open(scad_master, "r", encoding="utf-8") as f:
        content = f.read()
        
    bases = ["rect", "oval", "circ"]
    textos = ["reverso", "frontal_replace", "frontal_add"]
    
    # Expresiones regulares para buscar y reemplazar las asignaciones
    # tipo_base = "rect";
    # tipo_texto_icif = "reverso";
    base_pattern = re.compile(r'(tipo_base\s*=\s*")[^"]+("\s*;)')
    texto_pattern = re.compile(r'(tipo_texto_icif\s*=\s*")[^"]+("\s*;)')
    
    count = 0
    for base in bases:
        for texto in textos:
            count += 1
            # Modificar contenido
            new_content = base_pattern.sub(f'\\1{base}\\2', content)
            new_content = texto_pattern.sub(f'\\1{texto}\\2', new_content)
            
            # Nombre de archivo
            out_name = f"cad/llavero_{base}_{texto}.scad"
            
            with open(out_name, "w", encoding="utf-8") as f_out:
                f_out.write(new_content)
                
            print(f"[{count}/9] Creado archivo individual: {out_name}")
            
    print(f"[+] ¡Éxito! Generados los 9 archivos .scad individuales en cad/")

if __name__ == "__main__":
    main()
