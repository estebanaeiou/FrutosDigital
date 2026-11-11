# ════════════════════════════════════════════════════════════════════
#  TEI → HTML con facsímil (XSLT 1.0 con lxml, sin Saxon ni Java)
#  Pegar en UNA celda de Google Colab y ejecutar.
#  Pide dos archivos: el XML de la edición y la hoja el_rifle.xsl.
# ════════════════════════════════════════════════════════════════════
import sys, glob, os
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
ruta_xsl = pedir('.xsl', 'la hoja de transformación el_rifle.xsl')


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
errores, avisos = [], []

vistos = {}
for e in xml.iter():
    i = e.get(XID)
    if i is None:
        continue
    if i in vistos:
        errores.append(f'línea {e.sourceline}: xml:id="{i}" repetido (ya está en la línea {vistos[i]})')
    else:
        vistos[i] = e.sourceline
ids = set(vistos)

def apunta(xpath, atributo):
    for e in xml.xpath(xpath, namespaces=T):
        for v in e.get(atributo, '').split():
            if v.startswith('#') and v[1:] not in ids:
                errores.append(f'línea {e.sourceline}: <{etree.QName(e).localname}> {atributo}="{v}" '
                               f'no apunta a ningún xml:id')

apunta('//tei:pb', 'facs')
apunta('//tei:seg[@type="app"]', 'corresp')
apunta('//tei:app', 'corresp')
apunta('//tei:ref', 'target')
apunta('//tei:note', 'target')
apunta('//tei:note', 'resp')
apunta('//tei:lem', 'wit')
apunta('//tei:rdg', 'wit')

for l in xml.xpath('//tei:lem[not(@wit)]', namespaces=T):
    errores.append(f'línea {l.sourceline}: <lem> sin @wit')

pbs = xml.xpath('//tei:text//tei:pb', namespaces=T)
for p in pbs:
    if not p.get('facs'):
        avisos.append(f'línea {p.sourceline}: <pb n="{p.get("n")}"> sin @facs; no abrirá ninguna imagen')
llamadas = {p.get('facs', '')[1:] for p in pbs}
for s in xml.xpath('//tei:facsimile/tei:surface', namespaces=T):
    if s.get(XID) not in llamadas:
        avisos.append(f'línea {s.sourceline}: la surface "{s.get(XID)}" no tiene ningún <pb> que la llame')
    g = s.find('tei:graphic', T)
    if g is None or not g.get('url'):
        errores.append(f'línea {s.sourceline}: la surface "{s.get(XID)}" no tiene <graphic url="…">')
numeros = [p.get('n') for p in pbs]
if numeros != [str(i + 1) for i in range(len(numeros))]:
    avisos.append(f'la numeración de los <pb> no es consecutiva: {numeros}')
if not xml.xpath('//tei:facsimile', namespaces=T):
    avisos.append('el XML no tiene <facsimile>; la página saldrá sin visor de imágenes')

for a in avisos:
    print('⚠', a)
if errores:
    print('\n✗ DIAGNÓSTICO CON ERRORES: corrige el XML y vuelve a ejecutar la celda.\n')
    for e in errores:
        print('  ·', e)
    raise SystemExit
print(f'✓ Diagnóstico en verde: {len(pbs)} páginas, '
      f'{len(xml.xpath("//tei:back//tei:app", namespaces=T))} variantes, '
      f'{len(xml.xpath("//tei:back//tei:note[@n]", namespaces=T))} notas.')


# ── 4. Transformación ───────────────────────────────────────────────
try:
    transformar = etree.XSLT(etree.parse(ruta_xsl))
    resultado = transformar(xml)
except (etree.XMLSyntaxError, etree.XSLTParseError, etree.XSLTApplyError) as e:
    raise SystemExit(f'✗ Falló la transformación con {ruta_xsl}:\n  {e}')

ruta_html = Path(ruta_xml).with_suffix('.html')
ruta_html.write_bytes(etree.tostring(resultado, method='html', encoding='UTF-8',
                                     doctype='<!DOCTYPE html>'))
print(f'✓ {ruta_html} generado ({ruta_html.stat().st_size // 1024} KB).')


# ── 5. Vista previa y descarga ──────────────────────────────────────
if EN_COLAB:
    from IPython.display import HTML, display
    import html as _html
    display(HTML('<iframe style="width:100%;height:700px;border:1px solid #ccc" srcdoc="'
                 + _html.escape(ruta_html.read_text(encoding='utf-8')) + '"></iframe>'))
    files.download(str(ruta_html))
