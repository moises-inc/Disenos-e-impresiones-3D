#!/usr/bin/env python3
import os
import sys
import subprocess
import time

def check_openscad():
    import shutil
    return shutil.which("openscad") is not None

def run_cmd(cmd):
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return res.returncode == 0, res.stderr
    except Exception as e:
        return False, str(e)

def main():
    if not check_openscad():
        print("[-] Error: 'openscad' no está en el PATH.")
        sys.exit(1)

    # Definir combinaciones
    bases = ["rect", "oval", "circ"]
    textos = ["reverso", "frontal_replace", "frontal_add"]

    stl_dir = "cad/stl"
    render_dir = "cad/renders"

    os.makedirs(stl_dir, exist_ok=True)
    os.makedirs(render_dir, exist_ok=True)

    print("[*] Iniciando generación de STLs y Renders a partir de archivos individuales (9 en total)...")
    start_total = time.time()
    
    # Parámetros de cámara para OpenSCAD CLI: translate_x,y,z,rot_x,y,z,distancia
    # Vista frontal isométrica premium
    camera_front = "0,0,0,35,0,30,120"
    # Vista trasera para ver el grabado reverso
    camera_back = "0,0,0,145,0,30,120"

    count = 0
    for base in bases:
        for texto in textos:
            count += 1
            print(f"\n[{count}/9] Procesando archivo individual: llavero_{base}_{texto}.scad")
            
            scad_file = f"cad/llavero_{base}_{texto}.scad"
            if not os.path.exists(scad_file):
                print(f"    [-] Error: El archivo individual no existe: {scad_file}")
                continue
                
            # Nombres de archivo de salida
            file_base = f"llavero_{base}_{texto}"
            stl_path = os.path.join(stl_dir, f"{file_base}.stl")
            render_front_path = os.path.join(render_dir, f"{file_base}_front.png")
            render_back_path = os.path.join(render_dir, f"{file_base}_back.png")
            
            # Forzar resolución alta ($fn=72)
            defines = ["$fn=72"]
            
            # --- 1. Generar STL ---
            print(f"    -> Exportando STL...")
            cmd_stl = ["openscad", "-o", stl_path]
            for df in defines:
                cmd_stl.extend(["-D", df])
            cmd_stl.append(scad_file)
            
            ok, err = run_cmd(cmd_stl)
            if not ok:
                print(f"    [-] Error exportando STL: {err}")
                continue
                
            # --- 2. Generar Render Frontal ---
            print(f"    -> Renderizando Vista Frontal...")
            cmd_render_front = [
                "openscad", "-o", render_front_path,
                "--colorscheme=DeepOcean",
                f"--camera={camera_front}",
                "--imgsize=800,800"
            ]
            for df in defines:
                cmd_render_front.extend(["-D", df])
            cmd_render_front.append(scad_file)
            
            ok, err = run_cmd(cmd_render_front)
            if not ok:
                print(f"    [-] Error render frontal: {err}")
                
            # --- 3. Generar Render Trasero (Solo si es tipo reverso) ---
            if texto == "reverso":
                print(f"    -> Renderizando Vista Trasera (Grabado icif)...")
                cmd_render_back = [
                    "openscad", "-o", render_back_path,
                    "--colorscheme=DeepOcean",
                    f"--camera={camera_back}",
                    "--imgsize=800,800"
                ]
                for df in defines:
                    cmd_render_back.extend(["-D", df])
                cmd_render_back.append(scad_file)
                
                ok, err = run_cmd(cmd_render_back)
                if not ok:
                    print(f"    [-] Error render trasero: {err}")

    elapsed = time.time() - start_total
    print(f"\n[+] ¡Éxito! Proceso completado en {elapsed:.2f} segundos.")
    print(f"[+] Archivos STL guardados en: {stl_dir}/")
    print(f"[+] Capturas de render guardadas en: {render_dir}/")

if __name__ == "__main__":
    main()
