<?xml version="1.0" encoding="UTF-8"?>

<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
  xmlns:sqf="http://www.schematron-quickfix.com/validator/process" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <phase id="EinzelTest">
    <active pattern="ZahlFehler"/>
  </phase>

  <phase id="BiografieFehler">
    <active pattern="Bios1"/>
    <active pattern="Bios3b"/>
    <active pattern="Bios4"/> 
    <active pattern="BioName"/>
  </phase>
  <phase id="TextFehler">
    <active pattern="dreiIdentBuchstaben"/>
    <active pattern="Bindestrich"/>
    <active pattern="Spaces"/>
  </phase>
  <phase id="KodierungsFehler">
    <active pattern="UmlautFehler"/>
    <active pattern="ZahlFehler"/>
    <active pattern="SpaceFragezeichen"/>
    <active pattern="weitereKodierungsFehler"/>
  </phase>
  <phase id="falscheVerwendung">
    <active pattern="BioURL"/>
    <active pattern="illustrationsNote"/>
    <active pattern="Bios6Hinweis"/>
    <active pattern="SeitenAbbildungsvermerk"/>
    <active pattern="EditionStatementZiffer"/>
  </phase>
  <phase id="Empfehlung">
    <active pattern="suggestedLength"/>
    <active pattern="tocDefaultTextFormat"/>
    <active pattern="seitJahren"/>
    <active pattern="SubtitleAuflage"/>
    <active pattern="SubtitleErweiterung"/>
  </phase>

  <properties>
    <property id="refname"><xsl:value-of select="@refname"/></property>
  </properties>


    <!-- NEU: inflat. Verwendung von Kewords, Tag b067 List 20-->
    <pattern id="KeywordInflation">
        <rule role="warning"
            context="product/subject[1]">
            <report 
              test="count(product//b067='20') &gt; 15"> 
                Keywords reduzieren!
            </report>
        </rule>
    </pattern> 

<!--NEU: Seitenzahl in IllustrationsNote b062 (Verlag C)-->
    <pattern id="SeitenAbbildungsvermerk">
        <rule role="warning" 
            context="*:b062">
            <report 
               test="matches(., 'S[.]')" > 
              Befindet sich eine Seitenzahlangabe in b062 (IllustrationsNote)? Vorschlag: Überführe die Seitenzahlangabe in b061 (NumberOfPages).
            </report>
        </rule>
    </pattern>

<!--NEU: EditionStatement b058 (Verlag D, E, A_V30):  muss eine Beschreibung der Edition enthalten. Nicht nur Zahl.-->
    <pattern id="EditionStatementZiffer">
        <rule role="warning" context="*:b058">
            <report test="string(number(.)) != 'NaN'" properties="refname"> 
                In EditionStatement <name/> steht nur eine Nummer, obwohl hier eine Beschreibung der Edition sein soll.
                Vorschlag: ...
            </report>
        </rule>
    </pattern>


  <!-- Nur ein Contributor (egal welche Rolle), Texte unterscheiden sich -->
  <pattern id="Bios1">
    <rule role="error" context="
        product[count(contributor) = 1]
               [contributor/b044]
               /othertext[d102 = '13']/d104">
      <assert test="ancestor::product[1]/contributor[b044]/b044/normalize-space() = normalize-space(.)" > 
        Es gibt nur einen Contributor und dessen Biografietext weicht vom Text für alle Contributoren ab. 
        Wenn es nur einen Contributor gibt, benötigt es keine Biographical note im OtherText composite.
      </assert>
    </rule>
  </pattern>


  <!-- Nur ein Contributor, Texte stimmen überein -->
  <pattern id="Bios3b">
     <rule role="information"
      context="product[count(contributor) = 1]/othertext[d102 = '13']/d104" >
      <report test="ancestor::product[1]/contributor[b044]/b044/normalize-space() = normalize-space(.)" > 
            Der Biografietext des einzigen Contributors stimmt mit dem Text für alle Contributoren überein.
            Das OtherText composite mit der Biographical note ist redundant und kann gelöscht werden. 
      </report>
     </rule>
  </pattern>
  
  

  <!-- Mehrere Contributoren mit Autorenrolle, aber nicht jeder hat eine Einzelbiografie -->
  <!--Fall vermeiden, dass es z.B. 2 Autoren gibt und nur einer eine Bio hat, die in die Gesamtbio kommt-->
  <pattern id="Bios4">
    <rule role="error" 
          context="product[count(contributor[b035 = 'A01']) &gt; 1]/contributor[b035 = 'A01']/b044">
      <report test="ancestor::product[1][count(contributor[b035 = 'A01']) != count(contributor[b035 = 'A01']/b044)]" > 
        Es gibt ungleich viele Autoren und Biografien (Tag b044). Dies kann zu Fehlern in der Biographical note im OtherText composite führen.
      </report>
    </rule>
  </pattern>
  
  <!-- Mehr als ein Contributor, einer davon hat einen Text und dieser stimmt mit Gesamtbiografie überein (falsche Verwendung)-->
  <pattern id="Bios6Hinweis">
    <rule role="info" context="
        product[count(contributor) &gt; 1]
               [contributor/b044]
               /othertext[d102 = '13']/d104">
      <report test="ancestor::product[1]/contributor[b044]/b044/normalize-space() = normalize-space(.)" > 
        Der Biografietext eines Contributors stimmt mit dem Text für alle Contributoren im OtherText composite überein. 
        Es sollte im OtherText composite aber um mehrere Contributoren gehen.
        (Der Biografietext im OtherText composite sollte gelöscht werden.)
      </report>
    </rule>
  </pattern>

<!-- Fehlendes Leerzeichen zwischen zwei Sätzen, Bsp.: Buch:Wer
  Spaces mit exists--> <!-- Nr. 1: d104 | b044 ; Nr. 2: ONIXmessage/product/othertext/d104 | ONIXmessage/product/contributor/b044 ;
  Nr. 3: ONIXmessage/product[contributor/b044|othertext/d104] Nr. 4: nur product, so gibt es weniger Fehlermeldungen-Anzahl-->
  <pattern id="Spaces">
    <rule role="warning" context="*:d104 | *:b044" >
    <let name="Punkt-Regex" value="'\w*\p{Ll}[.:!?]\p{Lu}\w*'"/>
      <xsl:variable name="VPunkt" as="xs:string*">
        <xsl:analyze-string select="." regex="{$Punkt-Regex}">
          <xsl:matching-substring>
            <xsl:if test="not(. = 'Ph.D')and not(.='e.V') and not(.='a.D') and not(.='z.B')"> 
              <xsl:value-of select="."/>
            </xsl:if>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>
      <report test="exists($VPunkt)"> 
        Fehlt ein Leerzeichen zwischen zwei Sätzen? Fundstelle(n): <xsl:value-of select="string-join($VPunkt, ', ')"/>
      </report>
    </rule>
  </pattern>
  

  <!-- angegebener Name unterscheidet sich bei Name und Einzelbiografie -->
  <pattern id="BioName">
    <rule role="error" context="*:b044" >
      <let name="b036" value="ancestor::*:contributor/*:b036/normalize-space()"/>
      <let name="tokenized" value="tokenize($b036, ' ')"/>
      <let name="firstLast" value="string-join(($tokenized[1], $tokenized[last()]), ' ')"/>
      <let name="b036-regex" value="
          string-join(for $t in $tokenized
          return
          replace(replace($t, '\.', '(\\.|\\w+)'), '\?', '\\?'), ' ')"/>
      <assert test="contains(., $b036) or contains(., $firstLast) or matches(., $b036-regex)"> 
        Der Name des Contributors muss im Biografietext vorkommen und sollte mit dem angegebenen Namen ('<value-of select="ancestor::*:contributor/*:b036"/>')
        übereinstimmen. 
      </assert>
      <!--reicht nur erster Name und Nachname (Info)? Sonderzeichen/Umlaute?
      wenn in Biografie zusätzlich z.B. "J." steht ggf. noch implementieren
       '\s([A-Z]\.)\s' -->
    </rule>
  </pattern>

  <!-- in einer Biografie steht URL, das kann zu Fehlern in Verarbeitung führen -->
  <pattern id="BioURL">
    <rule role="warning" context="*:b044">
      <report test="contains(., 'www.') or contains(., '.de') or contains(., '.com')" > 
        Eine URL sollte nicht in einer Biographical note stehen.
        Vorschlag: Nutze dafür das Website composite.
      </report>
    </rule>
  </pattern>
  
  <!-- IllustrationsNote ist für Anmerkungen da -->
  <pattern id="illustrationsNote">
    <rule role="warning" context="*:b062">
      <!--<report test="matches(., '^\d+$')"> a </report>
      <report test=". castable as xs:integer"> b </report>-->
      <report test="string(number(.)) != 'NaN'" > 
        In b062 (IllustrationsNote) steht nur eine Nummer, obwohl hier eine Anmerkung stehen soll.
        Vorschlag: Überführe die Zahl in b125 (NumberOfIllustrations).
      </report>
    </rule>
  </pattern>

 <!-- Empfehlungen für Zeichenlängen in best. Elementen; hier aus der Dokumentation -->
  <!-- individuelle Empfehlungen oder Wünsche auch mgl. -->
  <pattern id="suggestedLength">
    <rule role="information" context="b336">
      <report test="./string-length() &gt; 100"> 
        Die empfohlene Länge beträgt hier 100 Zeichen. Wenn möglich, kürze den Text.
      </report>
    </rule>
    <rule role="information" context="b203">
      <report test="./string-length() &gt; 300"> 
        Die empfohlene Länge beträgt hier 300 Zeichen. Wenn möglich, kürze den Text.
      </report>
    </rule>
  </pattern>

  <!-- Empfehlung bei seit ... Jahren -->
  <pattern id="seitJahren">
    <rule role="information" context="*:b044 | *:othertext[*:d102 = '13']/*:d104 | *:textcontent[*:x426='12']/*:d104">
      <report 
        test="matches(., 'seit[\p{Zs}\s]+(\d+|zwei|drei|vier|fünf|sechs|sieben|acht|neun|zehn|elf|zwölf)[\p{Zs}\s]+Jahren', 'i')" > 
        Die Information in der Biografie kann veraltet sein. Vorschlag: "seit dem Jahr ..." oder " seit über ... Jahren".
      </report>
    </rule>
  </pattern>

  <!-- Fehlerhafte Worttrennung, Bsp.: be-nutzen -->
  <pattern id="Bindestrich">
    <rule role="information" 
      context="*:product[//*:language[b253 = '01'][//*:b252 = 'ger']]//*:d104 |
               *:product[//*:language[*:b253 = '01'][*:b252 = 'ger']]//*:b044 |
               *:product//*:d104[not(@language='eng')] |
               *:product//*:b044[not(@language='eng')]">
      <let name="Bindestrich-Regex" value="'\p{L}?\p{Ll}+-\p{Ll}+'"/>
      <!-- hier xsl-Teil mit exists() über report lassen, sonst werden auch stellen von not(. = '...') usw. angezeigt -->
        <xsl:variable name="VBindestrich" as="xs:string*">
        <xsl:analyze-string select="." regex="{$Bindestrich-Regex}">
          <xsl:matching-substring>
            <xsl:if test="
                not(. = 'Start-ups') and not(. = 'Start-up')
            and not(. = 'deutsch') 
            and not(. = 'Know-how') and not(. = 'öffentlich-rechtlich')">
              <xsl:value-of select="."/>
            </xsl:if>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>
      <report test="exists($VBindestrich)" properties="refname"> 
        Liegt eine fehlerhafte Worttrennung vor? Fundstelle(n): <xsl:value-of select="string-join($VBindestrich, ', ')"/>
      </report>
    </rule>
  </pattern>  
  
  
  

<!-- drei ident. Buchstaben hintereinander, Bsp.: solllte-->
  <pattern id="dreiIdentBuchstaben">
    <rule role="information" 
      context="*:title | *:subject | *:contributor | *:d104">
      <let name="dreiIdentBuchstaben-Regex" value="'[\p{L}]*([\p{L}])\1\1+[\p{L}]*'"/>  
     <xsl:variable name="VdreiIdentBuchstaben" as="xs:string*">
       <!-- hier xsl-Teil mit exists() über report lassen, sonst werden auch Stellen von not(. = 'www') usw. angezeigt --> <!-- bei if müssen Groß- und Kleinbuchstaben extra erfasst werden. i bringt eig. nichts -->
        <xsl:analyze-string select="." regex="{$dreiIdentBuchstaben-Regex}" flags="i">
          <xsl:matching-substring>
            <xsl:if test="
                not(. = 'www') 
                and
                not(. = 'hmmm') and not(. = 'oooh') 
                and
                not(. = 'III') and not(. = 'VIII') and not(. = 'XIII')">
              <xsl:value-of select="."/>
            </xsl:if>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>
      <report test="exists($VdreiIdentBuchstaben)"> 
        Drei identische Buchstaben erscheinen hintereinander. Liegt ein Rechtschreibfehler vor? 
        Fundstelle(n): <xsl:value-of select="string-join($VdreiIdentBuchstaben, ', ')"/>
      </report>
    </rule>
  </pattern>
  


  <!-- Hinweis, dass es ein IHV im Default text format gibt -->
  <pattern id="tocDefaultTextFormat">
    <rule role="information"
      context="*:othertext[*:d102 = '04'][*:d103 = '06']/*:d104">
      <report test="exists(.)" >
        Das TOC könnte auf eine Website übernommen werden und so seine Struktur verlieren.
        Vorschlag: Nutze bei Tag d102 den Code 02 und überführe das TOC in eine HTML-Struktur.
      </report>
    </rule>
  </pattern>

<!-- Kodierungsfehler in Zahl, Bsp.: 200?000 -->
<pattern id="ZahlFehler">
    <rule role="warning" 
      context="*:title | *:subject | *:contributor | *:d104 | 
               *:titleelement" >
      <let name="ZahlFehler-Regex" value="'\d+[?]\d+'"/>
      <report test="matches(., $ZahlFehler-Regex)"> 
        <xsl:variable name="VZahlFehler" as="xs:string*"> <!-- + auch mgl. -->
        <xsl:analyze-string select="." regex="{$ZahlFehler-Regex}">
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>
        In einer Zahl liegt möglicherweise ein Fehler vor.  
        Fundstelle(n): <xsl:value-of select="string-join($VZahlFehler, ', ')" />
      </report>
    </rule>
  </pattern>
  
  <!-- K1 -->
  <!-- K2 -->
  <!-- K3-->
  
    <!--Idee: SQF bei ZahlFehler: Fragezeichen entweder zu Punkt machen, löschen oder in engl. Texten zu Komma machen-->

  <!-- nach a o u kommt ein Fragezeichen, Bsp.: fu?r -->
  <pattern id="UmlautFehler">
    <rule role="warning" 
      context="*:title | *:subject | *:contributor | *:d104 |
               *:titleelement">
      <let name="UmlautFehler-Regex" value="'\w*[aouAOU][?][a-z]\w*'"/>  
      <report test="matches(., $UmlautFehler-Regex)">
        <xsl:variable name="VUmlautFehler" as="xs:string*">
        <xsl:analyze-string select="." regex="{$UmlautFehler-Regex}">
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>
        Möglicherweise liegt ein Umlautfehler vor. 
        Fundstelle(n): <xsl:value-of select="string-join($VUmlautFehler, ', ')" />
      </report>
    </rule>
  </pattern>
  
  <!-- vor einem Fragezeichen ist ein Whitespace und danach folgt *keine Ziffer oder kein Buchstabe*
       Bsp.: 2018 ? 1 -->
  <pattern id="SpaceFragezeichen">
      <rule role="warning"
        context="*:title | *:subject | *:contributor | *:d104 |
                 *:titleelement" >
        <let name="SpaceFragezeichen-Regex" value="'\w*\s[?]\W\w*'"/>
        <report  test="matches(., $SpaceFragezeichen-Regex, 's')">
        <xsl:variable name="VSpaceFragezeichen" as="xs:string*">
        <xsl:analyze-string select="." regex="{$SpaceFragezeichen-Regex}" flags="s">
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>
        Möglicherweise liegt ein Zeichenfehler mit einem Whitespace vor.  
        Fundstelle(n): <xsl:value-of select="string-join($VSpaceFragezeichen, ', ')" />
      </report>
      </rule>
   </pattern>

<!-- drei weitere Kodierungsfehler mit Fragezeichen; dabei sind die vorherigen Fehler ausgeschlossen.
    Fundstellen nur in OtherText -->
<pattern id="weitereKodierungsFehler">
  <rule role="warning"
    context="*:d104">
    
    <!--A: nach einem Zeichen *außer aou* kommt direkt ein Fragezeichen und danach ein kleiner Buchstabe
      Bsp.: 113?ff -->
    <let name="weitereKodierungsFehler1-Regex" value="'\w*.[^a^o^u^A^O^U][?]\p{Ll}+'"/> 
    <report test="matches(., $weitereKodierungsFehler1-Regex)">
    <xsl:variable name="VwkF1" as="xs:string*">
        <xsl:analyze-string select="." regex="{$weitereKodierungsFehler1-Regex}" flags="s">
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>  
     A: Hier liegen möglicherweise Kodierungsfehler vor. Fundstelle(n): <xsl:value-of select="string-join($VwkF1, ', ')" />
    </report>
   
     <!--B: nach einem Punkt kommt direkt ein Fragezeichen und danach ein Großbuchstabe.
    leicht anders, als "Spaces", Bsp.: St.?Gallen -->
    <let name="weitereKodierungsFehler2-Regex" value="'\w*\.[?]\p{Lu}+'"/>  
    <report test="matches(., $weitereKodierungsFehler2-Regex )">
    <xsl:variable name="VwkF2" as="xs:string*">
        <xsl:analyze-string select="." regex="{$weitereKodierungsFehler2-Regex}" flags="s" >
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>  
     B: Hier liegen möglicherweise Kodierungsfehler vor. Fundstelle(n): <xsl:value-of select="string-join($VwkF2, ', ')" />      
    </report>
    
    
    <!--C: nach einem Zeichen *außer einer Ziffer* kommt direkt ein Fragezeichen und danach eine Ziffer (1?00 ausschließen)
    Bsp.: §?175   kann?10 S.?75-->
    <let name="weitereKodierungsFehler3-Regex" value="'.?\D[?]\d+'"/> 
    <report test="matches(., $weitereKodierungsFehler3-Regex )">
    <xsl:variable name="VwkF3" as="xs:string*">
        <xsl:analyze-string select="." regex="{$weitereKodierungsFehler3-Regex}" flags="s">
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>  
     C: Hier liegen möglicherweise Kodierungsfehler vor. Fundstelle(n): <xsl:value-of select="string-join($VwkF3, ', ')" />        
    </report>
    
  </rule>
</pattern>

<!-- im Tag für die Händler/Lieferantenwebsite steht der Link des Publishers (falsche Verwendung; Tag wird durchgehend genutzt) -->
  <!--<pattern id="SupplierWebsite">
    <rule role="information" 
      context="product/supplydetail/website[b367 = '33']/b295">
      <report test="./text() = ancestor::product/publisher/website[b367 = '01']/b295/text()"
              diagnostics="dSupplierWebsite"> 
        Code 33 (List 73) ist redundant: "Eine Unternehmenswebsite, die von einem Händler oder einem anderen Lieferanten (nicht dem Publisher) betrieben wird."
      </report>
    </rule>
  </pattern>-->
  <!-- &#x2013;&#8220;“   \p{Zs}   \t \r \n\-->


<!-- Die Auflage steht im Untertitel-Segment, 
    Bsp.: 2., aktualisierte Auflage -->
<pattern id="SubtitleAuflage">
  <rule role="information" context="b029">
    <report test="contains(., 'Auflage')">
      Im Subtitle steht die Auflage. 
      Vorschlag: Überführe den Text besser in Tag b058 (EditionStatement).
    </report>
  </rule>
</pattern>
  <!-- NEU oder die Zahl in Tag b057 (EditionNumber) -->
  
  
  <!-- im Untertitel-Segment stehen evtl. Marketinginformationen,
  Bsp.: How to Transform Your Organization from the Inside Out, plus E-Book inside (ePub, mobi oder pdf)-->
  <pattern id="SubtitleErweiterung">
  <rule role="information" context="b029">
    <report test="contains(., 'Book')">
      Im Subtitle stehen möglicherweise zusätzliche Marketinginformationen. 
      Vorschlag: Überführe die Information in ein OtherText composite (z.B. mit Tag d102, Code 19 (Feature)).
    </report>
  </rule>
</pattern>

<!--  <diagnostics>
    <diagnostic id="dSupplierWebsite">Tag b367 mit Code 01 ist für die Publisher-Website vorgesehen. </diagnostic>
  </diagnostics>-->
  
<!-- ALTERNATIVEN vom 29.7. mit matches befinden sich in Datei schematron-onix-praktikum --> 
  
  
</schema>
