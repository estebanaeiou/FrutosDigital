"""Diagnostica El_rifle.xml y genera index.html.  Uso: python construir.py"""
from pathlib import Path
from lxml import etree

AQUI = Path(__file__).parent
T = {'tei': 'http://www.tei-c.org/ns/1.0'}
XID = '{http://www.w3.org/XML/1998/namespace}id'

xml = etree.parse(str(AQUI / 'El_rifle.xml'))
ids = [e.get(XID) for e in xml.iter() if e.get(XID)]
errores = [f'xml:id repetido: {i}' for i in sorted(set(ids)) if ids.count(i) > 1]
ids = set(ids)

def apunta(xpath, attr):
    for e in xml.xpath(xpath, namespaces=T):
        for v in e.get(attr, '').split():
            if v.startswith('#') and v[1:] not in ids:
                errores.append(f'línea {e.sourceline}: {attr}="{v}" no apunta a ningún xml:id')

apunta('//tei:pb', 'facs'); apunta('//tei:seg', 'corresp'); apunta('//tei:app', 'corresp')
apunta('//tei:ref', 'target'); apunta('//tei:note', 'target'); apunta('//tei:note', 'resp')
apunta('//tei:lem', 'wit'); apunta('//tei:rdg', 'wit')
for l in xml.xpath('//tei:lem[not(@wit)]', namespaces=T):
    errores.append(f'línea {l.sourceline}: lem sin @wit')
usadas = {p.get('facs', '')[1:] for p in xml.xpath('//tei:pb', namespaces=T)}
for s in xml.xpath('//tei:surface', namespaces=T):
    if s.get(XID) not in usadas:
        errores.append(f'línea {s.sourceline}: surface {s.get(XID)} sin pb que la llame')
nn = [p.get('n') for p in xml.xpath('//tei:pb', namespaces=T)]
if nn != [str(i + 1) for i in range(len(nn))]:
    errores.append(f'numeración de pb no consecutiva: {nn}')

if errores:
    raise SystemExit('DIAGNÓSTICO CON ERRORES\n' + '\n'.join(errores))
print(f'Diagnóstico en verde: {len(nn)} pb, '
      f'{len(xml.xpath("//tei:app", namespaces=T))} app, '
      f'{len(xml.xpath("//tei:back//tei:note[@n]", namespaces=T))} notas.')

html = etree.XSLT(etree.parse(str(AQUI / 'plantilla_edicion.xsl')))(xml)
(AQUI / 'index.html').write_bytes(etree.tostring(html, method='html', encoding='UTF-8', doctype='<!DOCTYPE html>'))
print('index.html generado.')
