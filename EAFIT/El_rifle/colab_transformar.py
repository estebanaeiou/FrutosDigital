# ════════════════════════════════════════════════════════════════════
#  PLANTILLA: TEI → HTML con facsímil (XSLT 1.0 con lxml, sin Saxon ni Java)
#  Pegar en UNA celda de Google Colab y ejecutar.
#
#  Sirve para cualquier edición con esta arquitectura:
#    · texto en <body>, dividido en <div>, con <pb n="…" facs="#…"/>
#    · aparato (<app>) y notas (<note>) en el <back>
#    · testimonios en <listWit> y, si hay imágenes, <facsimile> con una
#      <surface xml:id="…"> por página
#
#  Lo que el XML no traiga se omite. Los enlaces rotos se informan con su
#  línea, pero no impiden la transformación (salvo con ESTRICTO = True).
#
#  La celda muestra tres botones de subida, en este orden:
#    1. el XML de la edición
#    2. la hoja plantilla_edicion.xsl
#    3. las imágenes del facsímil (opcional: se puede cancelar)
# ════════════════════════════════════════════════════════════════════
import sys, glob, os, re, io, base64, mimetypes
from pathlib import Path

try:
    from lxml import etree
except ImportError:
    import subprocess
    subprocess.run([sys.executable, '-m', 'pip', 'install', '-q', 'lxml'], check=True)
    from lxml import etree

try:
    from google.colab import files          # solo existe dentro de Colab
    EN_COLAB = True
except ImportError:
    EN_COLAB = False

ESTRICTO = False     # True: no transforma mientras el diagnóstico tenga errores

TEI = 'http://www.tei-c.org/ns/1.0'
T = {'tei': TEI}
XID = '{http://www.w3.org/XML/1998/namespace}id'


# ── 1. Archivos ─────────────────────────────────────────────────────
def pedir(extension, descripcion):
    """Sube un archivo en Colab; fuera de Colab toma el más reciente de la carpeta."""
    if EN_COLAB:
        print(f'▶ Sube {descripcion} ({extension})')
        subidos = files.upload()
        nombres = [n for n in subidos if n.lower().endswith(extension)]
        if not nombres:
            raise SystemExit(f'No se subió ningún archivo {extension}.')
        return nombres[0]
    candidatos = sorted(glob.glob('*' + extension), key=os.path.getmtime)
    if not candidatos:
        raise SystemExit(f'No hay archivos {extension} en {os.getcwd()}.')
    return candidatos[-1]

ruta_xml = pedir('.xml', 'el XML-TEI de la edición')
ruta_xsl = pedir('.xsl', 'la hoja de transformación plantilla_edicion.xsl')

FORMATOS = ('.jpg', '.jpeg', '.png', '.webp', '.gif')
ANCHO_MAXIMO = 1600      # píxeles; las imágenes más anchas se reducen para aligerar el HTML

def pedir_imagenes():
    """Botón de subida de las imágenes del facsímil. Devuelve {nombre: bytes}."""
    if EN_COLAB:
        print('▶ Sube las imágenes del facsímil, todas a la vez (una por página).\n'
              '  Nómbralas en orden de página: p1.jpg, p2.jpg… o con el xml:id de su surface.\n'
              '  Si las imágenes ya están en línea y el XML tiene sus direcciones, pulsa «Cancelar».')
        try:
            subidas = files.upload()
        except Exception:
            subidas = {}
        return {n: b for n, b in subidas.items() if n.lower().endswith(FORMATOS)}
    carpeta = Path('imagenes')
    return {f.name: f.read_bytes() for f in sorted(carpeta.glob('*')) if f.suffix.lower() in FORMATOS}

imagenes = pedir_imagenes()


# ── 2. XML bien formado ─────────────────────────────────────────────
try:
    xml = etree.parse(ruta_xml)
except etree.XMLSyntaxError as e:
    raise SystemExit(f'✗ El XML no está bien formado.\n  Línea {e.lineno}, columna {e.offset}: {e.msg}')

raiz = xml.getroot()
if raiz.tag != f'{{{TEI}}}TEI':
    raise SystemExit('✗ La raíz no es <TEI> en el espacio de nombres TEI.\n'
                     '  La primera etiqueta debe ser:\n'
                     '  <TEI xmlns="http://www.tei-c.org/ns/1.0" xml:lang="es">')


# ── 3. Diagnóstico de enlaces ───────────────────────────────────────
errores, avisos = {}, []      # errores agrupados por clase: {clase: [mensajes]}

def error(clase, mensaje):
    errores.setdefault(clase, []).append(mensaje)

vistos = {}
for e in xml.iter():
    i = e.get(XID)
    if i is None:
        continue
    if i in vistos:
        error('xml:id repetido', f'línea {e.sourceline}: "{i}" (ya está en la línea {vistos[i]})')
    else:
        vistos[i] = e.sourceline
ids = set(vistos)

def apunta(xpath, atributo):
    for e in xml.xpath(xpath, namespaces=T):
        for v in e.get(atributo, '').split():
            if v.startswith('#') and v[1:] not in ids:
                error(f'<{etree.QName(e).localname}> con {atributo} que no apunta a ningún xml:id',
                      f'línea {e.sourceline}: {atributo}="{v}"')

apunta('//tei:pb', 'facs')
apunta('//tei:seg[@type="app"]', 'corresp')
apunta('//tei:app', 'corresp')
apunta('//tei:ref', 'target')
apunta('//tei:note', 'target')
apunta('//tei:note', 'resp')
apunta('//tei:lem', 'wit')
apunta('//tei:rdg', 'wit')

for l in xml.xpath('//tei:lem[not(@wit)]', namespaces=T):
    error('<lem> sin @wit', f'línea {l.sourceline}')

pbs = xml.xpath('//tei:text//tei:pb', namespaces=T)
sin_facs = []
for p in pbs:
    if not p.get('facs') and not (imagenes and not xml.xpath('//tei:facsimile', namespaces=T)):
        sin_facs.append(p.sourceline)
llamadas = {p.get('facs', '')[1:] for p in pbs}
for s in xml.xpath('//tei:facsimile/tei:surface', namespaces=T):
    if s.get(XID) not in llamadas:
        avisos.append(f'línea {s.sourceline}: la surface "{s.get(XID)}" no tiene ningún <pb> que la llame')
    g = s.find('tei:graphic', T)
    if (g is None or not g.get('url')) and not imagenes:
        error('<surface> sin <graphic url="…">', f'línea {s.sourceline}: "{s.get(XID)}"')
if sin_facs and xml.xpath('//tei:facsimile', namespaces=T):
    avisos.append(f'{len(sin_facs)} <pb> sin @facs (no abrirán ninguna imagen); primera en la línea {sin_facs[0]}')
numeros = [p.get('n') for p in pbs]
if None in numeros:
    if any(numeros):
        avisos.append('algunos <pb> tienen @n y otros no; los que no, se numeran por orden')
elif numeros != [str(i + 1) for i in range(len(numeros))]:
    avisos.append(f'la numeración de los <pb> no es consecutiva: {numeros[:15]}')
if not xml.xpath('//tei:facsimile', namespaces=T) and not imagenes:
    avisos.append('el XML no tiene <facsimile>; la página saldrá sin visor de imágenes')

for a in avisos:
    print('⚠', a)
if errores:
    total = sum(len(v) for v in errores.values())
    print(f'\n✗ DIAGNÓSTICO: {total} errores en el XML.')
    for clase, lista in errores.items():
        print(f'  · {clase}: {len(lista)}')
        for m in lista[:5]:
            print(f'      {m}')
        if len(lista) > 5:
            print(f'      … y {len(lista) - 5} más')
    if ESTRICTO:
        raise SystemExit('Corrige el XML y vuelve a ejecutar la celda.')
    print('  Se transforma de todos modos; esos lugares saldrán sin enlace o sin ficha.\n')
print(f'{"✓ Diagnóstico en verde" if not errores else "→ Contenido"}: {len(pbs)} páginas, '
      f'{len(xml.xpath("//tei:back//tei:app", namespaces=T))} variantes, '
      f'{len(xml.xpath("//tei:back//tei:note[not(ancestor::tei:app)]", namespaces=T))} notas.')


# ── 4. Imágenes subidas → incrustadas en el HTML ────────────────────
def orden_natural(nombre):
    return [int(t) if t.isdigit() else t.lower() for t in re.split(r'(\d+)', nombre)]

def incrustar(nombre, datos):
    """Devuelve la imagen como dirección data:, reducida si es muy ancha."""
    tipo = mimetypes.guess_type(nombre)[0] or 'image/jpeg'
    try:
        from PIL import Image
        im = Image.open(io.BytesIO(datos))
        if im.width > ANCHO_MAXIMO:
            im = im.resize((ANCHO_MAXIMO, round(im.height * ANCHO_MAXIMO / im.width)))
            salida = io.BytesIO()
            im.convert('RGB').save(salida, 'JPEG', quality=82)
            datos, tipo = salida.getvalue(), 'image/jpeg'
    except Exception:
        pass                      # sin Pillow, o formato raro: se incrusta tal cual
    return f'data:{tipo};base64,' + base64.b64encode(datos).decode('ascii')

if imagenes:
    superficies = xml.xpath('//tei:facsimile/tei:surface', namespaces=T)
    if not superficies:
        # El XML no declara facsímil: se crea uno y se reparte por los <pb>, en orden.
        fac = etree.Element(f'{{{TEI}}}facsimile')
        raiz.insert(list(raiz).index(raiz.find('tei:text', T)), fac)
        for k, nombre in enumerate(sorted(imagenes, key=orden_natural), 1):
            s = etree.SubElement(fac, f'{{{TEI}}}surface', {XID: f'facs_{k}', 'n': str(k)})
            etree.SubElement(s, f'{{{TEI}}}graphic', url=nombre)
            superficies.append(s)
        for p, s in zip(pbs, superficies):
            p.set('facs', '#' + s.get(XID))
        print(f'⚠ El XML no tenía <facsimile>: se crearon {len(superficies)} páginas y se '
              f'enlazaron con los {len(pbs)} <pb> en orden. Conviene declararlo en el XML.')

    libres = dict(imagenes)
    asignadas = {}
    # 1.º por nombre: coincide con el xml:id de la surface o con el archivo de su graphic/@url
    for s in superficies:
        g = s.find('tei:graphic', T)
        url = g.get('url', '') if g is not None else ''
        claves = {s.get(XID, '').lower(), Path(url.split('?')[0]).stem.lower()} - {''}
        for nombre in list(libres):
            if Path(nombre).stem.lower() in claves:
                asignadas[s] = (nombre, libres.pop(nombre))
                break
    # 2.º las demás, en orden de nombre de archivo
    resto = sorted(libres, key=orden_natural)
    for s in superficies:
        if s not in asignadas and resto:
            nombre = resto.pop(0)
            asignadas[s] = (nombre, libres.pop(nombre))

    for s in superficies:
        if s not in asignadas:
            print(f'⚠ La página "{s.get(XID)}" se quedó sin imagen subida; conserva la dirección del XML.')
            continue
        nombre, datos = asignadas[s]
        g = s.find('tei:graphic', T)
        if g is None:
            g = etree.SubElement(s, f'{{{TEI}}}graphic')
        g.set('url', incrustar(nombre, datos))
        print(f'  {s.get(XID):>10}  ←  {nombre}')
    for nombre in libres:
        print(f'⚠ Sobró la imagen {nombre}: hay más imágenes que páginas.')
    print(f'✓ {len(asignadas)} imágenes incrustadas en el HTML.')


# ── 5. Transformación ───────────────────────────────────────────────
try:
    transformar = etree.XSLT(etree.parse(ruta_xsl))
    resultado = transformar(xml)
except (etree.XMLSyntaxError, etree.XSLTParseError, etree.XSLTApplyError) as e:
    raise SystemExit(f'✗ Falló la transformación con {ruta_xsl}:\n  {e}')

ruta_html = Path(ruta_xml).with_suffix('.html')
ruta_html.write_bytes(etree.tostring(resultado, method='html', encoding='UTF-8',
                                     doctype='<!DOCTYPE html>'))
print(f'✓ {ruta_html} generado ({ruta_html.stat().st_size // 1024} KB). '
      'Es un solo archivo: lleva dentro estilos, guion e imágenes subidas.')


# ── 6. Vista previa y descarga ──────────────────────────────────────
if EN_COLAB:
    from IPython.display import HTML, display
    import html as _html
    display(HTML('<iframe style="width:100%;height:700px;border:1px solid #ccc" srcdoc="'
                 + _html.escape(ruta_html.read_text(encoding='utf-8')) + '"></iframe>'))
    files.download(str(ruta_html))
