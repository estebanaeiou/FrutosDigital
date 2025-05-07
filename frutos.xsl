<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei">

    <xsl:output method="html" indent="yes" encoding="UTF-8"/>

    <xsl:key name="glossary" match="tei:item" use="tei:term/@xml:id"/>
    <xsl:key name="notes" match="tei:note" use="@xml:id"/>
    <xsl:key name="apparatus" match="tei:app" use="@xml:id"/>


    <xsl:template match="/">
        <html lang="es">
            <head>
                <meta charset="UTF-8"/>
                <title>Frutos de mi tierra</title>
                <link rel="stylesheet" href="frutos.css"/>
                <link
                    href="https://fonts.googleapis.com/css2?family=Playfair+Display&amp;family=Raleway&amp;display=swap"
                    rel="stylesheet"/>
            </head>

            <body>
                <header>
                    <h1>Frutos de mi tierra</h1>
                    <img src="C:\Users\esteb\Desktop\TEI TESIS\UM\Logo.png" alt="Logo" id="logo"/>
                </header>

                <!-- Menú de la izquierda -->
                <div id="sidebar">
                    <h2>Índice</h2>
                    <nav>
                        <ul>
                            <li>
                                <a href="#chap_1">Capítulo I – Por la mañana</a>
                            </li>
                            <li>
                                <a href="#chap_2">Capítulo II – Historia antigua</a>
                            </li>
                            <li>
                                <a href="#chap_3">Capítulo III – Historia de la edad media</a>
                            </li>
                            <li>
                                <a href="#chap_4">Capítulo IV - Las queseras del medio </a>
                            </li>
                            <li>
                                <a href="#chap_5">Capítulo V - "Un cuarto alegre" </a>
                            </li>
                            <li>
                                <a href="#chap_6">Capítulo VI - Otro idem</a>
                            </li>
                            <li>
                                <a href="#chap_7">Capítulo VII – La Venganza</a>
                            </li>
                            <li>
                                <a href="#chap_8">Capítulo VIII – </a>
                            </li>
                            <li>
                                <a href="#chap_9">Capítulo IX – ...</a>
                            </li>
                            <li>
                                <a href="#chap_10">Capítulo X – </a>
                            </li>
                            <li>
                                <a href="#chap_11">Capítulo XI – </a>
                            </li>
                            <li>
                                <a href="#chap_12">Capítulo XII – ...</a>
                            </li>
                            <li>
                                <a href="#chap_13">Capítulo XIII – </a>
                            </li>
                            <li>
                                <a href="#chap_14">Capítulo XIV – </a>
                            </li>
                            <li>
                                <a href="#chap_15">Capítulo XV – ...</a>
                            </li>
                            <li>
                                <a href="#chap_16">Capítulo XVI – </a>
                            </li>
                            <li>
                                <a href="#chap_17">Capítulo XVII – </a>
                            </li>
                            <li>
                                <a href="#chap_18">Capítulo XVII – ...</a>
                            </li>
                            <li>
                                <a href="#chap_19">Capítulo XIX – </a>
                            </li>
                            <li>
                                <a href="#chap_20">Capítulo XX – </a>
                            </li>
                            <li>
                                <a href="#chap_21">Capítulo XXI – ...</a>
                            </li>
                            <li>
                                <a href="#chap_22">Capítulo XXII – </a>
                            </li>
                            <li>
                                <a href="#chap_23">Capítulo XXIII – </a>
                            </li>
                            <li>
                                <a href="#chap_24">Capítulo XXIV – ...</a>
                            </li>
                            <li>
                                <a href="#chap_25">Capítulo XXV – </a>
                            </li>
                            <li>
                                <a href="#chap_26">Capítulo XXVI – </a>
                            </li>
                            <li>
                                <a href="#chap_27">Capítulo XXVII – ...</a>
                            </li>
                            <li>
                                <a href="#chap_28">Capítulo XXVIII – </a>
                            </li>
                            <li>
                                <a href="#chap_29">Capítulo XXIX – </a>
                            </li>
                            <li>
                                <a href="#chap_30">Capítulo XXX – ...</a>
                            </li>

                            <li>
                                <a href="#notes">Notas explicativas</a>
                            </li>
                            <li>
                                <a href="#apparatus">Aparato crítico</a>
                            </li>
                            <li>
                                <a href="#glossary">Glosario</a>
                            </li>
                            <li>
                                <a href="#bibliography">Bibliografía</a>
                            </li>
                        </ul>
                    </nav>
                    <button class="toggle-btn" id="toggleNotes">Ocultar notas</button>
                </div>

                <main>
                    <!-- Apply templates to main chapters in <body> -->
                    <xsl:apply-templates select="//tei:text/tei:body/tei:div"/>

                    <!-- Apply templates to back matter (notes, glossary, etc.) -->
                    <xsl:apply-templates select="//tei:text/tei:back/tei:div"/>


                </main>

                <footer>
                    <p>Doctorado en Literatura (2025). Universidad de Antioquia (Colombia).<a href="https://scholar.google.com/citations?user=Mog-3swAAAAJ&amp;hl=es"
                        target="_blank"> Juan Esteban Hincapié Atehortúa</a></p>
                </footer>
                <script>
                    const btnNotes = document.getElementById('toggleNotes');
                    let notesHidden = false;
                    btnNotes.addEventListener('click', () => {
                    document.querySelectorAll('.note').forEach(el => {
                    el.style.display = notesHidden ? 'inline' : 'none';
                    });
                    notesHidden = !notesHidden;
                    btnNotes.textContent = notesHidden ? 'Mostrar notas' : 'Ocultar notas';
                    });
                </script>
            </body>
        </html>
    </xsl:template>

    <!-- Capítulos y secciones -->
    <xsl:template match="tei:div[@type = 'chap']">
        <section id="{@xml:id}">
            <h2>
                <xsl:value-of select="tei:head[@type = 'level2']"/>
            </h2>

            <xsl:for-each select="tei:div[@type = 'sec']">
                <div class="section" id="{@xml:id}">
                    <h3>
                        <xsl:value-of select="tei:head[@type = 'level3']"/>
                    </h3>
                    <xsl:apply-templates select="tei:p"/>
                </div>
            </xsl:for-each>
        </section>
    </xsl:template>


    <!-- SECCIÓN NOTAS EXPLICATIVAS -->
    <xsl:template match="tei:div[@xml:id = 'notes' and @place = 'foot']">
        <section id="{@xml:id}">
            <h2>Notas explicativas</h2>
            <xsl:apply-templates/>
        </section>
    </xsl:template>

    <xsl:template match="tei:note">
        <p id="{@xml:id}">
            <a href="{@target}">
                <b><xsl:value-of select="@n"/>.</b>
            </a>
            <xsl:text> </xsl:text>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <!-- Notes with dynamic tooltip -->
    <xsl:template match="tei:ref">
        <xsl:variable name="noteId" select="substring-after(@target, '#')"/>
        <a href="#{$noteId}" class="tooltip note" id="{@xml:id}">
            <!-- Arreglar: back/div/note -->
            <xsl:value-of select="."/>
            <span class="tooltiptext">
                <xsl:value-of select="key('notes', $noteId)"/>
            </span>
        </a>
    </xsl:template>

    <!-- SECCIÓN APARATO CRÍTICO -->
    <xsl:template match="tei:div[@xml:id = 'apparatus']">
        <section id="apparatus">
            <h2>
                <xsl:value-of select="tei:head"/>
            </h2>
            <xsl:apply-templates select="tei:listApp/tei:app"/>
        </section>
    </xsl:template>

    <xsl:template match="tei:app">
        <p id="{@xml:id}">
            <a href="#a_{@xml:id}">
                <b>
                    <xsl:value-of select="tei:lem"/>
                    <xsl:text></xsl:text>
                    <xsl:value-of select="tei:lem/@wit"/>
                </b>: </a>
            <xsl:for-each select="tei:rdg">
                <xsl:text> </xsl:text>
                <xsl:value-of select="@wit"/>: <xsl:value-of select="."/>
                <xsl:if test="position() != last()"> / </xsl:if>
            </xsl:for-each>
        </p>
    </xsl:template>

    <!-- Anchor with tooltip for critical apparatus -->
    <xsl:template match="tei:seg[@type = 'app']">
        <xsl:variable name="appId" select="substring-after(@corresp, '#')"/>
        <xsl:variable name="app" select="key('apparatus', $appId)"/>

        <a href="#{$appId}" class="tooltip crit-app" id="{@xml:id}">
            <xsl:apply-templates/>
            <!-- visible word like 'dio' -->
            <span class="tooltiptext">
                <strong>
                    <xsl:value-of select="$app/tei:lem/@wit"/>
                </strong>
                <xsl:text/>
                <!--xsl:value-of select="$app/tei:lem"/!-->
                <!-- La suprimí para que el lema no aparezca en el tooltip -->
                <xsl:for-each select="$app/tei:rdg">
                    <xsl:text> / </xsl:text>
                    <strong><xsl:value-of select="@wit"/>:</strong>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="."/>
                </xsl:for-each>
            </span>
        </a>
    </xsl:template>


    <!-- Glossary section -->
    <xsl:template match="tei:div[@type = 'glossary']">
        <section id="glossary">
            <h2>Glosario</h2>
            <xsl:apply-templates/>
        </section>
    </xsl:template>

    <xsl:template match="tei:item">
        <p id="{tei:term/@xml:id}">
            <b><xsl:value-of select="tei:term"/></b>: <xsl:value-of select="tei:gloss"/>
        </p>
    </xsl:template>

    <!-- Glossary terms with dynamic tooltip -->
    <xsl:template match="tei:term">
        <a href="{@corresp}">
            <span class="tooltip gloss">
                <xsl:apply-templates/>
                <span class="tooltiptext">
                    <xsl:variable name="id" select="substring-after(@corresp, '#')"/>
                    <xsl:value-of select="key('glossary', $id)/tei:gloss"/>
                </span>
            </span>
        </a>
    </xsl:template>

    <!-- Bibliography section -->
    <xsl:template match="tei:div[@type = 'bibliography']">
        <section id="bibliography">
            <h2>Bibliografía</h2>
            <xsl:apply-templates/>
        </section>
    </xsl:template>

    <xsl:template match="tei:listBibl/tei:bibl">
        <p id="{@xml:id}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    
    <!-- Instrucciones para el enlace de la bibliografía -->
    <xsl:template match="tei:div[@type='bibliography']//tei:ref">
        <a href="{@target}" target="_blank">
            <xsl:text>Enlace</xsl:text>
            <xsl:apply-templates/>
        </a>
    </xsl:template>
  


    <!-- Paragraphs -->
    <xsl:template match="tei:p">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="tei:title">
        <i>
            <xsl:apply-templates/>
        </i>
    </xsl:template>

    <!-- Line breaks -->
    <xsl:template match="tei:lb">
        <br/>
    </xsl:template>

</xsl:stylesheet>
