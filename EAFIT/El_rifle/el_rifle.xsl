<?xml version="1.0" encoding="UTF-8"?>
<!--
  Dispositio textus: TEI P5 → HTML de lectura con facsímil sinóptico.
  XSLT 1.0 (corre con lxml, xsltproc o cualquier navegador).
  El HTML resultante es autónomo: estilos y guion van dentro del archivo.
-->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">

  <xsl:output method="html" encoding="UTF-8" indent="no" doctype-system="about:legacy-compat"/>
  <xsl:strip-space elements="tei:TEI tei:teiHeader tei:text tei:body tei:back tei:div tei:listApp tei:app tei:choice tei:facsimile tei:surface tei:listWit tei:witness tei:bibl tei:list"/>

  <xsl:key name="porId" match="*[@xml:id]" use="@xml:id"/>

  <xsl:template match="/">
    <html lang="es">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title><xsl:value-of select="//tei:titleStmt/tei:title"/> · edición crítica digital</title>
        <style><xsl:value-of select="$css" disable-output-escaping="yes"/></style>
      </head>
      <body>
        <header class="cabecera">
          <div class="cabecera-titulo">
            <p class="autor"><xsl:value-of select="//tei:titleStmt/tei:author"/></p>
            <h1><xsl:value-of select="//tei:titleStmt/tei:title"/></h1>
          </div>
          <nav aria-label="Secciones">
            <a href="#texto">Texto</a>
            <a href="#aparato">Aparato</a>
            <a href="#notas">Notas</a>
            <a href="#testimonios">Testimonios</a>
            <a href="#criterios">Criterios</a>
          </nav>
          <div class="conmutador" role="group" aria-label="Modo de lectura">
            <button type="button" id="modo-critico" aria-pressed="true">Lectura crítica</button>
            <button type="button" id="modo-testimonio" aria-pressed="false">Testimonio 1915</button>
          </div>
        </header>

        <main class="mesa">
          <aside class="visor" id="facsimil" aria-label="Facsímil">
            <div class="visor-barra">
              <button type="button" id="facs-ant" aria-label="Página anterior">‹</button>
              <span id="facs-rotulo">Facsímil</span>
              <button type="button" id="facs-sig" aria-label="Página siguiente">›</button>
              <a id="facs-abrir" target="_blank" rel="noopener">Abrir imagen</a>
            </div>
            <div class="visor-lamina">
              <img id="facs-img" alt=""/>
              <p id="facs-aviso" hidden="hidden">No se pudo cargar la imagen. Compruebe que el archivo esté compartido como «cualquier persona con el enlace» o ábrala con el botón de arriba.</p>
            </div>
            <ol id="facs-lista" hidden="hidden">
              <xsl:apply-templates select="//tei:facsimile/tei:surface"/>
            </ol>
          </aside>

          <article class="pliego" id="texto">
            <xsl:apply-templates select="//tei:text/tei:body"/>
          </article>
        </main>

        <section class="bloque" id="aparato">
          <h2>Aparato crítico</h2>
          <p class="leyenda">Lema ] variantes. Las siglas remiten a la tabla de testimonios. En óxido, los lugares abiertos.</p>
          <xsl:apply-templates select="//tei:back//tei:app"/>
        </section>

        <section class="bloque" id="notas">
          <h2>Notas explicativas</h2>
          <xsl:apply-templates select="//tei:back//tei:div[@xml:id='notes']/tei:note"/>
        </section>

        <section class="bloque" id="testimonios">
          <h2>Testimonios</h2>
          <table>
            <thead><tr><th>Sigla</th><th>Testimonio</th><th>Año</th><th>Variantes propias</th></tr></thead>
            <tbody>
              <xsl:for-each select="//tei:listWit/tei:witness">
                <xsl:variable name="s" select="concat(' #', @xml:id, ' ')"/>
                <tr>
                  <td><span class="sigla"><xsl:value-of select="@xml:id"/></span></td>
                  <td>
                    <xsl:for-each select="tei:bibl/tei:title">
                      <xsl:if test="position() &gt; 1">, </xsl:if>
                      <xsl:choose>
                        <xsl:when test="@level='j'"><em><xsl:value-of select="."/></em></xsl:when>
                        <xsl:otherwise>«<xsl:value-of select="."/>»</xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each>
                    <xsl:if test="tei:bibl/tei:pubPlace">, <xsl:value-of select="tei:bibl/tei:pubPlace"/></xsl:if>
                    <xsl:if test="position() = 1"> (texto base)</xsl:if>
                  </td>
                  <td><xsl:value-of select="tei:bibl/tei:date"/></td>
                  <td><xsl:value-of select="count(//tei:rdg[contains(concat(' ', @wit, ' '), $s)])"/></td>
                </tr>
              </xsl:for-each>
            </tbody>
          </table>
        </section>

        <section class="bloque" id="criterios">
          <h2>Criterios de edición</h2>
          <p><xsl:apply-templates select="//tei:projectDesc/tei:p/node()"/></p>
          <ol>
            <xsl:for-each select="//tei:editorialDecl//tei:item">
              <li><xsl:value-of select="."/></li>
            </xsl:for-each>
          </ol>
          <h3>Tipología de variantes</h3>
          <ul>
            <xsl:for-each select="//tei:taxonomy/tei:category">
              <li><xsl:value-of select="tei:catDesc"/></li>
            </xsl:for-each>
          </ul>
          <h3>Responsables</h3>
          <ul>
            <xsl:for-each select="//tei:titleStmt/tei:respStmt">
              <li><xsl:value-of select="tei:resp"/>:
                <xsl:for-each select="tei:name">
                  <xsl:if test="position() &gt; 1">, </xsl:if>
                  <xsl:value-of select="."/>
                </xsl:for-each>
              </li>
            </xsl:for-each>
          </ul>
        </section>

        <div id="ficha" role="tooltip" hidden="hidden"></div>
        <script><xsl:value-of select="$js" disable-output-escaping="yes"/></script>
      </body>
    </html>
  </xsl:template>

  <!-- ───────── Facsímil ───────── -->
  <xsl:template match="tei:surface">
    <xsl:variable name="url" select="tei:graphic/@url"/>
    <xsl:variable name="id">
      <xsl:choose>
        <xsl:when test="contains($url, 'drive.google.com') and contains($url, 'id=')">
          <xsl:variable name="resto" select="substring-after($url, 'id=')"/>
          <xsl:choose>
            <xsl:when test="contains($resto, '&amp;')"><xsl:value-of select="substring-before($resto, '&amp;')"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="$resto"/></xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="contains($url, 'drive.google.com/file/d/')">
          <xsl:value-of select="substring-before(substring-after($url, '/file/d/'), '/')"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <li data-id="{@xml:id}">
      <xsl:attribute name="data-n">
        <xsl:choose>
          <xsl:when test="@n"><xsl:value-of select="@n"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="position()"/></xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="string($id) != ''">
          <xsl:attribute name="data-src">https://drive.google.com/thumbnail?id=<xsl:value-of select="$id"/>&amp;sz=w2000</xsl:attribute>
          <xsl:attribute name="data-alt">https://lh3.googleusercontent.com/d/<xsl:value-of select="$id"/>=w2000</xsl:attribute>
          <xsl:attribute name="data-enlace">https://drive.google.com/file/d/<xsl:value-of select="$id"/>/view</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="data-src"><xsl:value-of select="$url"/></xsl:attribute>
          <xsl:attribute name="data-enlace"><xsl:value-of select="$url"/></xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
    </li>
  </xsl:template>

  <xsl:template match="tei:pb">
    <xsl:variable name="destino" select="substring-after(@facs, '#')"/>
    <a class="pb" href="#facsimil" id="pb{@n}" data-facs="{$destino}" title="Ver la página {@n} del facsímil">
      <xsl:if test="not(parent::tei:p)"><xsl:attribute name="class">pb pb-bloque</xsl:attribute></xsl:if>
      <xsl:text>p. </xsl:text><xsl:value-of select="@n"/>
    </a>
  </xsl:template>

  <!-- ───────── Texto ───────── -->
  <xsl:template match="tei:body"><xsl:apply-templates/></xsl:template>

  <xsl:template match="tei:div[@type='chap']">
    <section class="capitulo" id="{@xml:id}"><xsl:apply-templates/></section>
  </xsl:template>

  <xsl:template match="tei:div/tei:head"><h2 class="cap-titulo"><xsl:apply-templates/></h2></xsl:template>

  <xsl:template match="tei:p"><p><xsl:apply-templates/></p></xsl:template>

  <xsl:template match="tei:hi[@rend='italic']"><em><xsl:apply-templates/></em></xsl:template>
  <xsl:template match="tei:hi[@rend='smallcaps']"><span class="versalitas"><xsl:apply-templates/></span></xsl:template>
  <xsl:template match="tei:title"><em><xsl:apply-templates/></em></xsl:template>

  <xsl:template match="tei:seg[@type='app']">
    <xsl:variable name="app" select="key('porId', substring-after(@corresp, '#'))"/>
    <a class="lugar" id="{@xml:id}" href="{@corresp}" data-ficha="{substring-after(@corresp, '#')}">
      <xsl:if test="$app/@cert='low'"><xsl:attribute name="class">lugar abierto</xsl:attribute></xsl:if>
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <xsl:template match="tei:ref[@target]">
    <sup><a class="llamada" id="{@xml:id}" href="{@target}" data-ficha="{substring-after(@target, '#')}">
      <xsl:if test="key('porId', substring-after(@target, '#'))/@cert='low'"><xsl:attribute name="class">llamada abierto</xsl:attribute></xsl:if>
      <xsl:apply-templates/>
    </a></sup>
  </xsl:template>

  <xsl:template match="tei:choice[tei:orig and tei:reg]">
    <span class="choice" tabindex="0">
      <xsl:attribute name="data-nota">
        <xsl:text>Testimonio A: «</xsl:text><xsl:value-of select="tei:orig"/>
        <xsl:text>» · Regularizado: «</xsl:text><xsl:value-of select="tei:reg"/><xsl:text>»</xsl:text>
        <xsl:if test="tei:reg/@cert='low'"> · Regularización dudosa: revisar.</xsl:if>
      </xsl:attribute>
      <xsl:if test="tei:reg/@cert='low'"><xsl:attribute name="class">choice abierto</xsl:attribute></xsl:if>
      <span class="reg"><xsl:apply-templates select="tei:reg/node()"/></span>
      <span class="orig"><xsl:apply-templates select="tei:orig/node()"/></span>
    </span>
  </xsl:template>

  <xsl:template match="tei:choice[tei:sic and tei:corr]">
    <span class="choice" tabindex="0" data-nota="Testimonio A: «{tei:sic}» · Enmendado: «{tei:corr}»">
      <span class="reg"><xsl:apply-templates select="tei:corr/node()"/></span>
      <span class="orig"><xsl:apply-templates select="tei:sic/node()"/></span>
    </span>
  </xsl:template>

  <xsl:template match="tei:supplied">
    <span class="choice supplied" tabindex="0" data-nota="Signo repuesto por el editor; falta en el testimonio A.">
      <span class="reg"><xsl:apply-templates/></span>
    </span>
  </xsl:template>

  <!-- ───────── Aparato y notas ───────── -->
  <xsl:template match="tei:app">
    <p class="entrada" id="{@xml:id}">
      <xsl:if test="@cert='low'"><xsl:attribute name="class">entrada abierto</xsl:attribute></xsl:if>
      <a class="volver" href="{@corresp}" title="Volver al texto"><xsl:value-of select="count(preceding::tei:app) + 1"/></a>
      <span class="cuerpo-ficha">
        <span class="lem"><xsl:value-of select="tei:lem"/></span>
        <xsl:text> </xsl:text><xsl:call-template name="siglas"><xsl:with-param name="wit" select="tei:lem/@wit"/></xsl:call-template>
        <xsl:text> ] </xsl:text>
        <xsl:for-each select="tei:rdg">
          <xsl:if test="position() &gt; 1"> ; </xsl:if>
          <span class="rdg"><xsl:value-of select="."/></span>
          <xsl:text> </xsl:text><xsl:call-template name="siglas"><xsl:with-param name="wit" select="@wit"/></xsl:call-template>
        </xsl:for-each>
        <span class="tipo">
          <xsl:call-template name="tipo"><xsl:with-param name="t" select="@type"/></xsl:call-template>
          <xsl:if test="@subtype"> · <xsl:call-template name="tipo"><xsl:with-param name="t" select="@subtype"/></xsl:call-template></xsl:if>
          <xsl:if test="@cert='low'"> · lugar abierto</xsl:if>
        </span>
        <xsl:if test="tei:note"><span class="app-nota"><xsl:value-of select="tei:note"/></span></xsl:if>
      </span>
    </p>
  </xsl:template>

  <xsl:template name="siglas">
    <xsl:param name="wit"/>
    <span class="sigla"><xsl:value-of select="translate($wit, '#', '')"/></span>
  </xsl:template>

  <xsl:template name="tipo">
    <xsl:param name="t"/>
    <xsl:choose>
      <xsl:when test="$t='orthographic'">ortográfica</xsl:when>
      <xsl:when test="$t='morphological'">morfológica</xsl:when>
      <xsl:when test="$t='syntactic'">sintáctica</xsl:when>
      <xsl:when test="$t='semantic'">semántica</xsl:when>
      <xsl:when test="$t='typographic'">tipográfica</xsl:when>
      <xsl:when test="$t='pragmatic'">pragmática</xsl:when>
      <xsl:otherwise><xsl:value-of select="$t"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:div[@xml:id='notes']/tei:note">
    <p class="entrada" id="{@xml:id}">
      <xsl:if test="@cert='low'"><xsl:attribute name="class">entrada abierto</xsl:attribute></xsl:if>
      <a class="volver" href="{@target}" title="Volver al texto"><xsl:value-of select="@n"/></a>
      <span class="cuerpo-ficha">
        <xsl:apply-templates/>
        <xsl:if test="@cert='low'"><span class="tipo">nota por completar o verificar</span></xsl:if>
      </span>
    </p>
  </xsl:template>

  <!-- ───────── Estilos ───────── -->
  <xsl:variable name="css"><![CDATA[
:root{
  --fondo:#e6e9ec; --panel:#fbfbf9; --tinta:#1d2226; --tenue:#5c666e; --linea:#cfd5da;
  --marca:#1f5673; --marca-suave:#dbe8ef; --oxido:#a5441c; --oxido-suave:#f6e3d9;
  --serif:"Iowan Old Style","Palatino Linotype",Palatino,"Book Antiqua",Georgia,serif;
  --sans:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;
  --mono:ui-monospace,"SF Mono",Menlo,Consolas,monospace;
}
@media (prefers-color-scheme:dark){
  :root{--fondo:#15191c;--panel:#1e2327;--tinta:#e7e9ea;--tenue:#9aa5ad;--linea:#343c42;
    --marca:#8cc3e0;--marca-suave:#24384a;--oxido:#eb946b;--oxido-suave:#40271c;}
}
*{box-sizing:border-box}
html{scroll-behavior:smooth;scroll-padding-top:4.5rem}
body{margin:0;background:var(--fondo);color:var(--tinta);font-family:var(--serif);font-size:1.0625rem;line-height:1.65;hyphens:none}
a{color:var(--marca)}
.cabecera{position:sticky;top:0;z-index:20;display:flex;flex-wrap:wrap;align-items:center;gap:.5rem 1.5rem;
  padding:.5rem 1rem;background:var(--panel);border-bottom:1px solid var(--linea);font-family:var(--sans)}
.cabecera-titulo{display:flex;align-items:baseline;gap:.6rem;margin-right:auto}
.cabecera h1{margin:0;font-family:var(--serif);font-size:1.25rem;font-style:italic}
.autor{margin:0;font-size:.8rem;color:var(--tenue);text-transform:uppercase;letter-spacing:.06em}
.cabecera nav{display:flex;flex-wrap:wrap;gap:.9rem;font-size:.85rem}
.cabecera nav a{text-decoration:none}
.cabecera nav a:hover{text-decoration:underline}
.conmutador{display:flex;border:1px solid var(--linea);border-radius:6px;overflow:hidden}
.conmutador button{font:inherit;font-size:.8rem;padding:.3rem .7rem;border:0;background:transparent;color:var(--tenue);cursor:pointer}
.conmutador button[aria-pressed="true"]{background:var(--marca);color:var(--panel)}

.mesa{display:grid;grid-template-columns:1fr;gap:1rem;max-width:90rem;margin:1rem auto;padding:0 1rem}
.visor{background:var(--panel);border:1px solid var(--linea);border-radius:6px;display:flex;flex-direction:column;min-width:0}
.visor-barra{display:flex;align-items:center;gap:.5rem;padding:.4rem .6rem;border-bottom:1px solid var(--linea);font-family:var(--sans);font-size:.85rem}
.visor-barra button{font:inherit;font-size:1.1rem;line-height:1;width:2rem;height:2rem;border:1px solid var(--linea);border-radius:4px;background:transparent;color:var(--tinta);cursor:pointer}
.visor-barra button:disabled{opacity:.35;cursor:default}
#facs-rotulo{flex:1;text-align:center;font-variant-numeric:tabular-nums}
#facs-abrir{font-size:.8rem;white-space:nowrap}
.visor-lamina{overflow:auto;max-height:60vh;padding:.5rem;text-align:center;background:var(--fondo)}
.visor-lamina img{max-width:100%;height:auto;cursor:zoom-in;background:#fff}
.visor-lamina.ampliada img{max-width:none;width:180%;cursor:zoom-out}
#facs-aviso{font-family:var(--sans);font-size:.85rem;color:var(--tenue);padding:2rem 1rem;margin:0}
@media (min-width:62rem){
  .mesa{grid-template-columns:minmax(0,5fr) minmax(0,6fr);align-items:start}
  .visor{position:sticky;top:4rem;height:calc(100vh - 5rem)}
  .visor-lamina{flex:1;max-height:none}
}

.pliego{background:var(--panel);border:1px solid var(--linea);border-radius:6px;padding:2rem clamp(1rem,4vw,3.5rem);min-width:0}
.pliego p{margin:0;text-indent:1.5em;text-align:left}
.capitulo>p:first-of-type{text-indent:0}
.cap-titulo{text-align:center;font-size:1.1rem;font-weight:normal;letter-spacing:.15em;margin:2.5rem 0 1rem}
.versalitas{font-variant:small-caps}

.pb{display:inline-block;margin:0 .25em;padding:0 .4em;font-family:var(--mono);font-size:.7rem;line-height:1.5;text-indent:0;vertical-align:.15em;
  border:1px solid var(--linea);border-radius:3px;color:var(--tenue);text-decoration:none;background:var(--fondo)}
.pb:hover,.pb.activa{border-color:var(--marca);color:var(--marca)}
.pb-bloque{display:block;width:max-content;margin:1rem auto}

.lugar{color:inherit;text-decoration:none;background:var(--marca-suave);border-bottom:1px solid var(--marca);padding:0 .1em;border-radius:2px 2px 0 0}
.lugar.abierto{background:var(--oxido-suave);border-bottom-color:var(--oxido)}
.llamada{font-family:var(--sans);font-size:.72rem;text-decoration:none;padding:0 .15em;font-weight:600}
.llamada.abierto{color:var(--oxido)}
.choice{border-bottom:1px dotted var(--tenue);cursor:help}
.choice.abierto{border-bottom:1px dotted var(--oxido);color:var(--oxido)}
.choice .orig{display:none}
body.testimonio .choice .reg{display:none}
body.testimonio .choice .orig{display:inline}
:focus-visible{outline:2px solid var(--marca);outline-offset:2px}

.bloque{max-width:52rem;margin:1rem auto;padding:1.5rem clamp(1rem,4vw,2.5rem);background:var(--panel);border:1px solid var(--linea);border-radius:6px}
@media (max-width:54rem){.bloque{margin-left:1rem;margin-right:1rem}}
.bloque h2{margin:0 0 .75rem;font-size:1.3rem;font-weight:normal}
.bloque h3{font-size:1rem;margin:1.5rem 0 .4rem}
.leyenda{font-family:var(--sans);font-size:.82rem;color:var(--tenue);margin:0 0 1rem}
.entrada{display:grid;grid-template-columns:2.2rem 1fr;gap:.5rem;margin:0;padding:.5rem 0;border-top:1px solid var(--linea)}
.entrada:target{background:var(--marca-suave)}
.entrada.abierto{border-left:3px solid var(--oxido);padding-left:.5rem}
.volver{font-family:var(--mono);font-size:.8rem;text-decoration:none;text-align:right;padding-top:.15rem}
.lem{font-weight:600}
.sigla{font-family:var(--mono);font-size:.78rem;letter-spacing:.08em;color:var(--tenue)}
.tipo,.app-nota{display:block;font-family:var(--sans);font-size:.78rem;color:var(--tenue);margin-top:.15rem}
.abierto .tipo{color:var(--oxido)}
table{border-collapse:collapse;width:100%;font-size:.95rem}
th,td{text-align:left;padding:.4rem .6rem;border-top:1px solid var(--linea);vertical-align:top}
th{font-family:var(--sans);font-size:.75rem;text-transform:uppercase;letter-spacing:.05em;color:var(--tenue);border-top:0}
td:last-child,th:last-child{text-align:right;font-variant-numeric:tabular-nums}

#ficha{position:absolute;z-index:30;max-width:min(24rem,calc(100vw - 2rem));padding:.6rem .8rem;background:var(--panel);color:var(--tinta);
  border:1px solid var(--linea);border-left:3px solid var(--marca);border-radius:4px;box-shadow:0 6px 20px rgba(0,0,0,.18);font-size:.9rem;line-height:1.45}
#ficha.abierto{border-left-color:var(--oxido)}
@media (prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
@media print{
  .cabecera nav,.conmutador,.visor,#ficha{display:none}
  .cabecera{position:static}
  body{background:#fff}
  .mesa{display:block}
  .pliego,.bloque{border:0;max-width:none}
}
]]></xsl:variable>

  <!-- ───────── Guion ───────── -->
  <xsl:variable name="js"><![CDATA[
(function () {
  'use strict';

  /* ── Visor de facsímil ── */
  var laminas = [].map.call(document.querySelectorAll('#facs-lista li'), function (li) {
    return { id: li.dataset.id, n: li.dataset.n, src: li.dataset.src, alt: li.dataset.alt, enlace: li.dataset.enlace };
  });
  var img = document.getElementById('facs-img');
  var aviso = document.getElementById('facs-aviso');
  var rotulo = document.getElementById('facs-rotulo');
  var abrir = document.getElementById('facs-abrir');
  var ant = document.getElementById('facs-ant');
  var sig = document.getElementById('facs-sig');
  var lamina = document.querySelector('.visor-lamina');
  var marcas = [].slice.call(document.querySelectorAll('a.pb'));
  var actual = -1;

  function mostrar(i) {
    if (i < 0 || i >= laminas.length || i === actual) return;
    actual = i;
    var l = laminas[i];
    aviso.hidden = true;
    img.hidden = false;
    img.dataset.intento = '0';
    img.alt = 'Facsímil, página ' + l.n;
    img.src = l.src;
    rotulo.textContent = 'Facsímil · p. ' + l.n + ' de ' + laminas.length;
    abrir.href = l.enlace || l.src;
    ant.disabled = i === 0;
    sig.disabled = i === laminas.length - 1;
    lamina.classList.remove('ampliada');
    lamina.scrollTop = 0;
    marcas.forEach(function (m) { m.classList.toggle('activa', m.dataset.facs === l.id); });
  }
  function indiceDe(id) {
    for (var i = 0; i < laminas.length; i++) if (laminas[i].id === id) return i;
    return -1;
  }
  img.addEventListener('error', function () {
    var l = laminas[actual];
    if (l && l.alt && img.dataset.intento === '0') { img.dataset.intento = '1'; img.src = l.alt; return; }
    img.hidden = true; aviso.hidden = false;
  });
  img.addEventListener('click', function () { lamina.classList.toggle('ampliada'); });
  ant.addEventListener('click', function () { irA(actual - 1); });
  sig.addEventListener('click', function () { irA(actual + 1); });

  var ancho = window.matchMedia('(min-width: 62rem)');
  var pausa = 0;
  /* Con los botones del visor, el texto acompaña a la imagen. */
  function irA(i) {
    if (i < 0 || i >= laminas.length) return;
    mostrar(i);
    var m = marcas.filter(function (x) { return x.dataset.facs === laminas[i].id; })[0];
    if (m && ancho.matches) { pausa = Date.now() + 900; m.scrollIntoView({ block: 'start' }); }
  }
  marcas.forEach(function (m) {
    m.addEventListener('click', function (e) {
      mostrar(indiceDe(m.dataset.facs));
      /* En pantalla ancha el visor ya está a la vista: no hace falta saltar. */
      if (ancho.matches) e.preventDefault();
    });
  });
  /* Al leer, el visor sigue la página en la que va el texto. */
  function seguir() {
    if (!ancho.matches || Date.now() < pausa) return;
    var limite = window.innerHeight * 0.4, elegido = marcas[0];
    for (var i = 0; i < marcas.length; i++) {
      if (marcas[i].getBoundingClientRect().top <= limite) elegido = marcas[i]; else break;
    }
    if (elegido) mostrar(indiceDe(elegido.dataset.facs));
  }
  var pendiente = false;
  window.addEventListener('scroll', function () {
    if (pendiente) return;
    pendiente = true;
    requestAnimationFrame(function () { pendiente = false; seguir(); });
  }, { passive: true });
  if (laminas.length) mostrar(0); else document.getElementById('facsimil').hidden = true;

  /* ── Lectura crítica / testimonio ── */
  var bc = document.getElementById('modo-critico'), bt = document.getElementById('modo-testimonio');
  function modo(testimonio) {
    document.body.classList.toggle('testimonio', testimonio);
    bc.setAttribute('aria-pressed', String(!testimonio));
    bt.setAttribute('aria-pressed', String(testimonio));
  }
  bc.addEventListener('click', function () { modo(false); });
  bt.addEventListener('click', function () { modo(true); });

  /* ── Fichas emergentes ── */
  var ficha = document.getElementById('ficha');
  function abrirFicha(el) {
    var html = '';
    if (el.dataset.ficha) {
      var origen = document.getElementById(el.dataset.ficha);
      var cuerpo = origen && origen.querySelector('.cuerpo-ficha');
      if (cuerpo) html = cuerpo.innerHTML;
    } else if (el.dataset.nota) {
      ficha.textContent = el.dataset.nota; html = ficha.innerHTML;
    }
    if (!html) return;
    ficha.innerHTML = html;
    ficha.classList.toggle('abierto', el.classList.contains('abierto'));
    ficha.hidden = false;
    var r = el.getBoundingClientRect();
    var x = Math.max(8, Math.min(r.left + window.scrollX, window.scrollX + document.documentElement.clientWidth - ficha.offsetWidth - 8));
    var y = r.bottom + window.scrollY + 6;
    if (r.bottom + ficha.offsetHeight + 12 > window.innerHeight) y = r.top + window.scrollY - ficha.offsetHeight - 6;
    ficha.style.left = x + 'px'; ficha.style.top = y + 'px';
  }
  function cerrarFicha() { ficha.hidden = true; }
  [].forEach.call(document.querySelectorAll('[data-ficha], [data-nota]'), function (el) {
    el.addEventListener('mouseenter', function () { abrirFicha(el); });
    el.addEventListener('mouseleave', cerrarFicha);
    el.addEventListener('focus', function () { abrirFicha(el); });
    el.addEventListener('blur', cerrarFicha);
    if (el.dataset.nota) el.addEventListener('click', function () { abrirFicha(el); });
  });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') cerrarFicha(); });
})();
]]></xsl:variable>

</xsl:stylesheet>
