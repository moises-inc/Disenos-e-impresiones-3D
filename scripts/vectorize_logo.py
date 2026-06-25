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
    
    if width / height > 1.5:
        # Binarizar: el logo es blanco puro
        binary_full = img_np > threshold
        
        # Usar análisis de componentes conectados para extraer el logo central
        # y filtrar de forma inteligente montañas a los lados y abajo.
        from scipy.ndimage import label
        labeled, num_features = label(binary_full)
        
        binary = np.zeros_like(binary_full)
        
        keep_count = 0
        for i in range(1, num_features + 1):
            y_indices, x_indices = np.where(labeled == i)
            if len(x_indices) == 0:
                continue
            min_x, max_x = np.min(x_indices), np.max(x_indices)
            min_y, max_y = np.min(y_indices), np.max(y_indices)
            cx = np.mean(x_indices)
            cy = np.mean(y_indices)
            
            # Filtro de componentes para el logo "bit a bit 3.0" en un banner de 1024x341:
            # 1. El centro X debe estar en la franja central (X entre 340 y 684)
            # 2. No debe tocar el fondo inferior (Y máximo debe ser < 282, donde empiezan las montañas)
            # 3. No debe ser parte de los bordes laterales decorativos del banner (min_x > 320 y max_x < 700)
            if 340 <= cx <= 684 and max_y < 282 and min_x > 320 and max_x < 700:
                # 4. Excluir fragmentos residuales de picos de montaña que se filtran en la zona inferior-derecha
                if cx > 610 and cy > 240:
                    continue
                binary[labeled == i] = True
                keep_count += 1
                
        print(f"[*] Segmentación por componentes: conservados {keep_count} componentes del logo.")
    else:
        # Para imágenes no anchas, conservar compatibilidad original (binarizado simple)
        binary = img_np > threshold
    
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
        
    # Normalizar coordenadas para que sean estrictamente positivas
    all_vertices = np.array(all_vertices)
    min_x, min_y = np.min(all_vertices[:, 0]), np.min(all_vertices[:, 1])
    max_x, max_y = np.max(all_vertices[:, 0]), np.max(all_vertices[:, 1])
    
    scale_y = max_y - min_y
    scale_x = max_x - min_x
    max_dim = max(scale_x, scale_y)
    scale_factor = 100.0 / max_dim
    
    # Dimensiones de la caja delimitadora normalizada
    view_w = scale_x * scale_factor
    view_h = scale_y * scale_factor
    
    print(f"[+] Ajuste de escala: Original {scale_x:.1f}x{scale_y:.1f}px -> Normalizado a {view_w:.1f}x{view_h:.1f} unidades.")
    
    # Escribir el SVG
    # El viewBox e importación ahora usan coordenadas estrictamente positivas para compatibilidad con OpenSCAD
    svg_header = (
        f'<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n'
        f'<svg width="{view_w:.1f}mm" height="{view_h:.1f}mm" viewBox="0 0 {view_w:.3f} {view_h:.3f}"\n'
        f'     xmlns="http://www.w3.org/2000/svg" version="1.1">\n'
        f'  <g fill="black" fill-rule="evenodd" stroke="none">\n'
    )
    
    svg_footer = "  </g>\n</svg>\n"
    
    all_d_cmds = []
    for vertices in svg_paths:
        # Trasladar y escalar los vértices a coordenadas positivas e invertir Y para orientarlo correctamente
        norm_v = np.zeros_like(vertices)
        norm_v[:, 0] = (vertices[:, 0] - min_x) * scale_factor
        norm_v[:, 1] = (vertices[:, 1] - min_y) * scale_factor
        
        # Construir sub-camino
        sub_d = []
        sub_d.append(f"M {norm_v[0][0]:.3f} {norm_v[0][1]:.3f}")
        for pt in norm_v[1:]:
            sub_d.append(f"L {pt[0]:.3f} {pt[1]:.3f}")
        sub_d.append("Z")
        all_d_cmds.append(" ".join(sub_d))
        
    # Concatenar todos los sub-caminos en un único tag <path>
    # Esto es crucial para que OpenSCAD cale correctamente los huecos interiores de las circunvoluciones
    single_path = f'    <path d="{" ".join(all_d_cmds)}" />'
        
    with open(svg_out_path, "w", encoding="utf-8") as f:
        f.write(svg_header)
        f.write(single_path)
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
