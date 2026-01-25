# Instalar las librerias necesarias
!pip install collatex
!pip install python-Levenshtein

from collatex import Collation, collate

# Crear una colación
collation = Collation()

# Añadir testimonios (witnesses)
collation.add_plain_witness("A", "Zapato") #Aquí insertan el testimonio A
collation.add_plain_witness("B", "zapato") #Aquí insertan el testimonio B
                                            #Aquí puede ir el testomio C solo
                                            #deben repetir la instrucción anterior

# Ejecutar la colación y obtener el resultado en tabla
result_table = collate(collation, output="table")
print(result_table)

# Obtener el aparato crítico en TEI
result_tei = collate(collation, output="tei")
print(result_tei)