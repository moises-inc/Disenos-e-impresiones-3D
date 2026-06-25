#!/usr/bin/env python3
import os
import sys
import subprocess
import time
import argparse
import shutil

def check_openscad():
    """Verifica si openscad está instalado en el sistema."""
    return shutil.which("openscad") is not None

def compile_scad(scad_path, output_dir, fn_val=None, extra_defines=None):
    """Compila un único archivo .scad a .stl."""
    if not os.path.exists(scad_path):
        print(f"[-] Error: El archivo fuente no existe: {scad_path}")
        return False

    # Determinar nombre del archivo de salida
    base_name = os.path.splitext(os.path.basename(scad_path))[0]
    output_path = os.path.join(output_dir, f"{base_name}.stl")
    
    # Construir comando
    cmd = ["openscad", "-o", output_path]
    
    # Agregar variables definidas en caliente
    if fn_val is not None:
        cmd.extend(["-D", f"$fn={fn_val}"])
    
    if extra_defines:
        for define in extra_defines:
            cmd.extend(["-D", define])
            
    cmd.append(scad_path)
    
    print(f"[*] Compilando: {os.path.basename(scad_path)} -> {os.path.basename(output_path)}")
    if fn_val:
        print(f"    - Parámetro de resolución inyectado: $fn={fn_val}")
    if extra_defines:
        print(f"    - Definiciones extra: {', '.join(extra_defines)}")
        
    # Medir tiempo
    start_time = time.time()
    try:
        # Ejecutar openscad CLI
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        elapsed_time = time.time() - start_time
        
        if result.returncode == 0:
            file_size = os.path.getsize(output_path) / 1024 # KB
            print(f"[+] Éxito en {elapsed_time:.2f} segundos. Tamaño STL: {file_size:.2f} KB")
            return True
        else:
            print(f"[-] Error al compilar {scad_path}")
            print(result.stderr)
            return False
    except Exception as e:
        print(f"[-] Excepción durante la ejecución de OpenSCAD: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Compilador automatizado de OpenSCAD a STL.")
    parser.add_argument("-i", "--input", help="Ruta del archivo .scad individual. Si se omite, compila todos los de la carpeta cad/.")
    parser.add_argument("-o", "--output-dir", default="cad/stl", help="Directorio de salida para los archivos .stl (por defecto cad/stl/)")
    parser.add_argument("-f", "--fn", type=int, help="Sobrescribe el valor de resolución de curvas ($fn) en el renderizado.")
    parser.add_argument("-D", "--define", action="append", help="Inyecta variables adicionales (ej. -D 'cuerpo_r=55'). Puede usarse varias veces.")
    
    args = parser.parse_args()
    
    if not check_openscad():
        print("[-] Error: 'openscad' no está disponible en el PATH de tu sistema.")
        print("    Asegúrate de tener OpenSCAD instalado y accesible mediante la CLI.")
        sys.exit(1)
        
    # Asegurar que el directorio de salida existe
    os.makedirs(args.output_dir, exist_ok=True)
    
    if args.input:
        # Compilar archivo individual
        success = compile_scad(args.input, args.output_dir, args.fn, args.define)
        sys.exit(0 if success else 1)
    else:
        # Compilar por lotes
        cad_dir = "cad"
        if not os.path.exists(cad_dir):
            print(f"[-] Error: Directorio por defecto '{cad_dir}' no encontrado. Especifica un archivo de entrada con -i.")
            sys.exit(1)
            
        scad_files = [os.path.join(cad_dir, f) for f in os.listdir(cad_dir) if f.endswith(".scad")]
        
        if not scad_files:
            print(f"[-] No se encontraron archivos .scad en '{cad_dir}/'")
            sys.exit(0)
            
        print(f"[*] Detectados {len(scad_files)} archivos .scad para procesar.")
        successful = 0
        for scad_file in scad_files:
            # Para evitar compilar ensambles completos por error (que tardan mucho y no son piezas únicas),
            # podemos filtrarlos o simplemente advertir.
            if "ensamble" in os.path.basename(scad_file).lower():
                print(f"[!] Omitiendo archivo de ensamblaje por defecto: {os.path.basename(scad_file)} (Compilar manualmente con -i si es necesario)")
                continue
            if compile_scad(scad_file, args.output_dir, args.fn, args.define):
                successful += 1
                
        print(f"\n[+] Proceso finalizado. Compilados con éxito: {successful}/{len(scad_files) - 1 if len(scad_files) > 1 else len(scad_files)}")

if __name__ == "__main__":
    main()
