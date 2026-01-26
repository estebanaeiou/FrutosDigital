# 1) Instalar lxml, si no está instalado
!pip install lxml

# 2) Subir el archivo TEI
from google.colab import files
uploaded = files.upload()  # Sube tu archivo TEI, por ejemplo "mi_texto.xml"

import lxml.etree as ET

# Tomamos el nombre del archivo subido
nombre_xml = list(uploaded.keys())[0]

# 3) Mapear el TEI con lxml
doc = ET.parse(nombre_xml)

# Definir namespace TEI (por si hace falta en búsquedas XPATH)
TEI_NS = {"tei": "http://www.tei-c.org/ns/1.0"}

# 4) Remplazar <lg><l> por <p>
for lg in doc.xpath("//tei:lg", namespaces=TEI_NS):
    parent = lg.getparent()  # El padre de <lg>
    idx = parent.index(lg)   # Posición de <lg> en el padre

    # Recorremos cada <l> dentro de <lg>
    for l in lg.xpath("./tei:l", namespaces=TEI_NS):
        # Creamos un nuevo <p>
        p = ET.Element("{http://www.tei-c.org/ns/1.0}p")

        # Mover todos los nodos hijos de <l> a <p>
        for node in list(l):
            p.append(node)   # Transplanta sub-elementos, manteniendo marcas

        # Si quieres mantener también el texto suelto que <l> pudiera tener (fuera de sub-etiquetas), haz:
        if l.text:
            if p.text is None:
                p.text = l.text
            else:
                p.text += l.text

        # Insertamos <p> antes de <lg>
        parent.insert(idx, p)
        idx += 1

    # Eliminamos <lg>
    parent.remove(lg)

# 5) Guardar y descargar el nuevo archivo
output_file = "salida_prosa.xml"
doc.write(output_file, encoding="UTF-8", pretty_print=True, xml_declaration=True)
print(f"Se ha generado '{output_file}' con <p> en vez de <lg>/<l>.")

files.download(output_file)
