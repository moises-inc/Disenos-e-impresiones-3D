---
tipo: bitacora_pieza
proyecto: bit a bit
pieza: llavero
scad_source: cad/llavero.scad
stl_output: cad/stl/llavero.stl
fecha_creacion: 2026-06-25
---

# Bitácora de Diseño y Fabricación: llavero

[[Disenos-e-impresiones-3D]] | [[Impresión 3D]]

## 1. Parámetros Paramétricos (OpenSCAD)
Valores de diseño extraídos automáticamente del archivo de origen:

| Parámetro | Valor por Defecto | Descripción / Función |
| :--- | :--- | :--- |
| `tipo_base` | `"rect"` | [rect: Rectangular, oval: Elíptica, circ: Circular] |
| `ancho_llavero` | `55.0` | Ancho total del llavero (en mm) - Aumentado para dar espacio al agujero interno |
| `largo_llavero` | `55.0` | Largo total del llavero (en mm) - Aumentado para dar espacio al agujero interno |
| `esquinas_r` | `6.0` | Radio de las esquinas (solo para tipo_base = "rect") |
| `espesor_base` | `2.2` | Grosor de la placa base |
| `espesor_logo` | `1.0` | Altura del relieve del logo (frontal) |
| `espesor_borde` | `1.0` | Altura del relieve del borde protector (frontal) |
| `espesor_texto` | `1.0` | Altura del relieve de los textos (frontal) |
| `borde_ancho` | `1.6` | Ancho de la pared del borde protector |
| `anillo_d_int` | `4.2` | Diámetro del agujero para la argolla |
| `anillo_d_ext` | `8.5` | Diámetro exterior del rim protector |
| `anillo_pos` | `"top_left"` | [top_left, top_right, top_center, left_center] |
| `tipo_texto_icif` | `"reverso"` | Parámetro de diseño. |
| `logo_escala` | `0.35` | Escala del logo de engranaje "bit a bit 3.0" (ajustado para centrado y no colisión con agujero) |
| `texto_icif` | `"icif"` | Sigla de la carrera |
| `size_icif` | `5.5` | Tamaño de fuente para "icif" |

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
**Historial del Grafo:** [bit a bit Bitácoras](file:///mnt/9b846436-0407-4e80-b8af-5417ffbdee8e/Impresi%C3%B3n%203D/bitacoras/)