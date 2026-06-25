---
tipo: bitacora_pieza
proyecto: USS Spiderbot
pieza: pieza_prueba
scad_source: cad/pieza_prueba.scad
stl_output: cad/stl/pieza_prueba.stl
fecha_creacion: 2026-06-25
---

# Bitácora de Diseño y Fabricación: pieza_prueba

[[Disenos-e-impresiones-3D]] | [[Impresión 3D]]

## 1. Parámetros Paramétricos (OpenSCAD)
Valores de diseño extraídos automáticamente del archivo de origen:

| Parámetro | Valor por Defecto | Descripción / Función |
| :--- | :--- | :--- |
| `base_r` | `15.0` | Radio de la base circular |
| `altura` | `20.0` | Altura total de la pieza de prueba |
| `agujero_d` | `3.2` | Diámetro del orificio central para tornillo M3 |
| `soporte_espesor` | `2.0` | Espesor del nervio de refuerzo triangular |

## 2. Planificación de Fabricación y Slicing
Selecciona la impresora utilizada y completa los parámetros específicos para el rebanado (CrealityPrint):

### Impresora de Destino:
- [ ] **Creality K1** (CoreXY - Klipper. Velocidad recomendada: 250-300 mm/s)
- [ ] **Ender V3 KE** (Cartesiana - Klipper. Velocidad recomendada: 150-200 mm/s)
- [ ] **Ender V3 SE** (Cartesiana - Marlin. Velocidad recomendada: 50-80 mm/s)

### Parámetros Genéricos de Impresión:

| Parámetro de Corte | Valor Sugerido (PLA) | Ajuste Utilizado | Notas / Justificación |
| :--- | :--- | :--- | :--- |
| **Temperatura de Boquilla** | 200 - 220 °C | | |
| **Temperatura de Cama** | 60 °C | | |
| **Densidad de Infill (Relleno)** | 20 % | | Estructural, aumentar a 30-40% si sufre carga mecánica |
| **Patrón de Relleno** | Giroide (Gyroid) | | Mayor resistencia multidireccional |
| **Altura de Capa** | 0.20 mm | | Equilibrio entre velocidad y acabado |
| **Soportes** | No / Según Geometría | | Evitar si es posible para mantener el acabado superficial |
| **Adherencia a Cama** | Falda (Skirt) | | Borde (Brim) si hay riesgo de warping |

## 3. Control de Calidad y Ajustes Mecánicos (Tolerancias)
Valores críticos de tolerancia de impresión a validar después de fabricar (comparar con pie de metro):

| Característica / Ajuste | Dimensión Modelada | Dimensión Real Medida | Desviación (mm) | Estado (Ajusta / OK) |
| :--- | :--- | :--- | :--- | :--- |
| **Orificios M3 (Tornillería)** | r = 1.6 mm (Ø 3.2 mm) | | | |
| **Paso de Tornillo M2 (Rosca)** | r = 1.0 mm (Ø 2.0 mm) | | | |
| **Caja de Servomotor SG90** | Ancho 25.0 mm | | | |
| **Acople de Horn (Corona)** | r = 4.0 mm (Ø 8.0 mm) | | | |
| **Brazo Rectangular de Horn** | 16.0 x 5.2 mm | | | |

## 4. Métricas de Impresión y Post-Procesado
- **Tiempo Estimado (Slicer):** `__h __m`
- **Tiempo Real de Impresión:** `__h __m`
- **Consumo de Filamento:** `____ gramos` / `____ metros`
- **Post-Procesado Realizado:**
  - [ ] Remoción de soportes
  - [ ] Limpieza de rebabas / lijado suave
  - [ ] Roscado directo preliminar de tornillos
- **Observaciones Generales:** (Anotar si hubo warping, problemas de adherencia, hilachas o defectos estéticos)

---
**Historial del Grafo:** [USS Spiderbot Docs](file:///mnt/9b846436-0407-4e80-b8af-5417ffbdee8e/Github/USS%20SPIDERBOT%20(solemne%203)/docs/)