#!/usr/bin/env python3
import os
import sys
import argparse
from PIL import Image
import numpy as np

# Configurar matplotlib para modo sin GUI antes de importar pyplot
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

def vectorize_png(png_path, svg_out_path, threshold=200, min_points=5):
    """Convierte un PNG de logo en blanco/azul a un archivo SVG limpio y centrado."""
    if not os.path.exists(png_path):
        print(f"[-] Error: Archivo de entrada no existe: {png_path}")
        return False
        
    print(f"[*] Cargando imagen: {png_path}")
    img = Image.open(png_path).convert('L')
    width, height = img.size
    img_np = np.array(img)
    
    # Binarizar: el logo es blanco puro (>200) y el fondo es azul oscuro (~50)
    # Invertir verticalmente la imagen para que el origen (0,0) de OpenSCAD quede abajo-izquierda como en cartesianas
    # o mantener la orientación normal. En OpenSCAD, Y aumenta hacia arriba, y en imágenes Y aumenta hacia abajo.
    # Así que invertiremos el eje Y para que no salga de cabeza en OpenSCAD.
    binary = img_np[::-1, :] > threshold
    
    print("[*] Detectando contornos con matplotlib...")
    # Obtener isolíneas para el umbral 0.5 en la matriz binaria
    fig, ax = plt.subplots()
    contours = ax.contour(binary, levels=[0.5])
    
    # Extraer caminos de contorno
    svg_paths = []
    all_vertices = []
    
    # Los contornos se encuentran en get_paths() en matplotlib moderno, o en collections en versiones antiguas
    if hasattr(contours, 'get_paths'):
        paths = contours.get_paths()
    elif hasattr(contours, 'collections') and contours.collections:
        paths = contours.collections[0].get_paths()
    else:
        print("[-] Error: No se detectó una estructura de contornos compatible en la imagen.")
        plt.close(fig)
        return False
        
    from matplotlib.path import Path
    print(f"[*] Analizando {len(paths)} caminos iniciales...")
    
    for path in paths:
        vertices = path.vertices
        codes = path.codes
        if codes is None:
            # Camino simple sin subcaminos
            if len(vertices) >= min_points:
                svg_paths.append(vertices)
                all_vertices.extend(vertices)
        else:
            # Camino compuesto, dividir por Path.MOVETO
            current = []
            for v, code in zip(vertices, codes):
                if code == Path.MOVETO:
                    if len(current) >= min_points:
                        current_arr = np.array(current)
                        svg_paths.append(current_arr)
                        all_vertices.extend(current_arr)
                    current = [v]
                else:
                    current.append(v)
            if len(current) >= min_points:
                current_arr = np.array(current)
                svg_paths.append(current_arr)
                all_vertices.extend(current_arr)
                
    plt.close(fig) # Liberar memoria de matplotlib
    
    if not svg_paths:
        print("[-] Error: Todos los contornos fueron filtrados por tamaño.")
        return False
        
    # Normalizar coordenadas para centrar el logo en (0,0) y ajustarlo a una escala uniforme
    all_vertices = np.array(all_vertices)
    min_x, min_y = np.min(all_vertices[:, 0]), np.min(all_vertices[:, 1])
    max_x, max_y = np.max(all_vertices[:, 0]), np.max(all_vertices[:, 1])
    
    center_x = (min_x + max_x) / 2.0
    center_y = (min_y + max_y) / 2.0
    
    # Queremos que la altura máxima del SVG normalizado sea de 100 unidades (mm de referencia en CAD)
    scale_y = max_y - min_y
    scale_x = max_x - min_x
    max_dim = max(scale_x, scale_y)
    scale_factor = 100.0 / max_dim
    
    print(f"[+] Ajuste de escala: Original {scale_x:.1f}x{scale_y:.1f}px -> Normalizado a 100.0 unidades.")
    
    # Escribir el SVG
    # El viewBox irá de -60 a 60 en X y Y para dejar margen de centrado
    view_w = 120
    view_h = 120
    
    svg_header = (
        f'<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n'
        f'<svg width="100mm" height="100mm" viewBox="-60 -60 {view_w} {view_h}"\n'
        f'     xmlns="http://www.w3.org/2000/svg" version="1.1">\n'
        f'  <g fill="black" fill-rule="evenodd" stroke="none">\n'
    )
    
    svg_footer = "  </g>\n</svg>\n"
    
    path_elements = []
    for vertices in svg_paths:
        # Centrar y escalar los vértices
        norm_v = (vertices - [center_x, center_y]) * scale_factor
        
        # Construir comandos SVG d="M x0 y0 L x1 y1 ... Z"
        # Nota: Matplotlib Y invertido ya compensa el sentido de OpenSCAD.
        d_cmds = []
        d_cmds.append(f"M {norm_v[0][0]:.3f} {norm_v[0][1]:.3f}")
        for pt in norm_v[1:]:
            d_cmds.append(f"L {pt[0]:.3f} {pt[1]:.3f}")
        d_cmds.append("Z")
        
        path_str = f'    <path d="{" ".join(d_cmds)}" />'
        path_elements.append(path_str)
        
    with open(svg_out_path, "w", encoding="utf-8") as f:
        f.write(svg_header)
        f.write("\n".join(path_elements))
        f.write("\n")
        f.write(svg_footer)
        
    print(f"[+] Archivo SVG vectorial generado exitosamente en: {svg_out_path}")
    return True

def main():
    parser = argparse.ArgumentParser(description="Conversor/Vectorizador de PNG a SVG para OpenSCAD.")
    parser.add_argument("-i", "--input", required=True, help="Imagen PNG de entrada.")
    parser.add_argument("-o", "--output", default="cad/logo.svg", help="Archivo SVG de salida (por defecto cad/logo.svg).")
    parser.add_argument("-t", "--threshold", type=int, default=200, help="Umbral de brillo para binarizar (0-255, por defecto 200).")
    parser.add_argument("-m", "--min-points", type=int, default=5, help="Filtrar contornos con menos puntos (ruido, por defecto 5).")
    
    args = parser.parse_args()
    
    # Crear directorio si no existe
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    
    success = vectorize_png(args.input, args.output, args.threshold, args.min_points)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
