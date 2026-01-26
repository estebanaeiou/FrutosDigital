# Instalar las dependencias 
import xml.etree.ElementTree as ET
import pandas as pd
import unicodedata
import re

# Función para eliminar tildes y diéresis
def remove_accents(text):
    return ''.join(c for c in unicodedata.normalize('NFD', text) if unicodedata.category(c) != 'Mn')

# Mecánica para los cambios morfológicos
def morphological_change(base, reading):
    b = remove_accents(base.lower()).split()
    r = remove_accents(reading.lower()).split()
    if len(b) != len(r):
        return False
    for tb, tr in zip(b, r):
        if tb == tr:
            continue
        # Singular/plural
        if tb.rstrip('s') == tr.rstrip('s'):
            continue
        if tb.rstrip('es') == tr.rstrip('es') or tr.rstrip('es') == tb.rstrip('es'):
            continue
        # Género (terminaciones -a, -o)
        if len(tb) > 1 and len(tr) > 1 and tb[:-1] == tr[:-1] and tb[-1] in 'oa' and tr[-1] in 'oa':
            continue

        # Flexiones verbales
        prefix_length = min(len(tb), len(tr), 3)
        if tb[:prefix_length] == tr[:prefix_length] and abs(len(tb) - len(tr)) <= 2:
            continue
        return False
    return True

# Clasificar la operación y el nivel de lengua
def classify_variant(base, reading):
    # Casos de adición u omisión
    if base.strip() == '' and reading.strip() != '':
        return 'Adición', 'Semántica'
    if base.strip() != '' and reading.strip() == '':
        return 'Omisión', 'Semántica'
    # Normalización y tokenización
    base_tokens = remove_accents(base.lower()).split()
    reading_tokens = remove_accents(reading.lower()).split()
    # Operación: transmutación si son las mismas palabras en distinto orden
    if sorted(base_tokens) == sorted(reading_tokens) and base_tokens != reading_tokens:
        operation = 'Transmutación'
    else:
        operation = 'Inmutación'
    # Nivel ortográfico: mismo lexema al quitar signos y acentos
    base_nopunct = re.sub(r'[\W_]', '', remove_accents(base.lower()))
    reading_nopunct = re.sub(r'[\W_]', '', remove_accents(reading.lower()))
    if base_nopunct == reading_nopunct:
        level = 'Ortográfica'
    elif sorted(base_tokens) == sorted(reading_tokens) and base_tokens != reading_tokens:
        level = 'Sintáctica'
    elif morphological_change(base, reading):
        level = 'Morfológica'
    else:
        level = 'Semántica'
    return operation, level

# Procesar el archivo TEI y obtener DataFrame de variantes
def process_tei_collation(xml_path):
    tree = ET.parse(xml_path)
    root = tree.getroot()
    ns = {'tei': 'http://www.tei-c.org/ns/1.0'}
    # Obtener testigos de <listWit>
    witnesses = []
    for wit in root.findall('.//tei:listWit/tei:witness', ns):
        sig = wit.get('{http://www.w3.org/XML/1998/namespace}id') or wit.get('n')
        if sig:
            witnesses.append('#' + sig if not sig.startswith('#') else sig)
    if '#A' not in witnesses:
        witnesses.insert(0, '#A')
    records = []
    # Recorrer los aparatos críticos
    for app in root.findall('.//tei:app', ns):
        readings = {wit: '' for wit in witnesses}
        for rdg in app.findall('tei:rdg', ns):
            text = ''.join(rdg.itertext()).strip()
            for w in (rdg.get('wit') or '').split():
                if w in readings:
                    readings[w] = text
        base_reading = readings.get('#A', '')
        # Comparar cada testimonio con la base
        for w in witnesses:
            if w == '#A':
                continue
            reading = readings.get(w, '')
            if reading != base_reading:
                op, lvl = classify_variant(base_reading, reading)
                records.append({
                    'witness': w.lstrip('#'),
                    'operation': op,
                    'level': lvl
                })
    return pd.DataFrame(records)

# --- Colab ---

# Permitir cargar el XML desde tu máquina
from google.colab import files
uploaded = files.upload()
# Tomar el primer archivo cargado
xml_file = next(iter(uploaded))
# Procesar el archivo y crear el DataFrame
df_variants = process_tei_collation(xml_file)
# Guardar el CSV
df_variants.to_csv('variant_records.csv', index=False)
print(f'Se generaron {len(df_variants)} variantes.')
# Descargar el CSV a tu ordenador
files.download('variant_records.csv')
