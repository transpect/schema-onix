<?xml version="1.0" encoding="UTF-8"?>

<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
  xmlns:sqf="http://www.schematron-quickfix.com/validator/process" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <phase id="Test">
    <active pattern="weitereKodierungsFehler"/>
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
  </phase>
  <phase id="KodierungsFehler">
    <active pattern="Spaces"/>
    <active pattern="UmlautFehler"/>
    <active pattern="ZahlFehler"/>
    <active pattern="SpaceFragezeichen"/>
    <active pattern="weitereKodierungsFehler"/>
  </phase>
  <phase id="falscheVerwendung">
    <active pattern="BioURL"/>
    <active pattern="illustrationsNote"/>
    <active pattern="Bios6Hinweis"/>
  </phase>
  <phase id="Empfehlung">
    <active pattern="suggestedLength"/>
    <active pattern="tocDefaultTextFormat"/>
    <active pattern="seitJahren"/>
  </phase>
  <!--<phase id="Redudanzen">
    <active pattern="SupplierWebsite"/>
  </phase>-->


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

<!-- Fehlendes Leerzeichen zwischen zwei Sätzen -->
  <pattern id="Spaces">
    <rule role="warning" context="d104 | b044" >
    <let name="Punkt-RegEx" value="'(\p{Lu}?\p{L}*\p{Ll})[.:!?]\p{Lu}\w*'"/>
      <xsl:variable name="VPunkt" as="text()*">
        <xsl:analyze-string select="." regex="{$Punkt-RegEx}">
          <xsl:matching-substring>
            <xsl:if test="
                not(regex-group(1) = 'www')
                and
                not(. = 'Ph.D')and not(.='e.V') and not(.='a.D') and not(.='z.B')"> 
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
    <rule role="error" context="b044" >
      <let name="b036" value="ancestor::contributor/b036/normalize-space()"/>
      <let name="tokenized" value="tokenize($b036, ' ')"/>
      <let name="firstLast" value="string-join(($tokenized[1], $tokenized[last()]), ' ')"/>
      <let name="b036-regex" value="
          string-join(for $t in $tokenized
          return
          replace(replace($t, '\.', '(\\.|\\w+)'), '\?', '\\?'), ' ')"/>
      <assert test="contains(., $b036) or contains(., $firstLast) or matches(., $b036-regex)"> 
        Der Name des Contributors muss im Biografietext vorkommen und sollte mit dem angegebenen Namen ('<value-of select="ancestor::contributor/b036"/>')
        übereinstimmen. 
      </assert>
      <!--reicht nur erster Name und Nachname (Info)? Sonderzeichen/Umlaute?
      wenn in Biografie zusätzlich z.B. "J." steht ggf. noch implementieren
       '\s([A-Z]\.)\s' -->
    </rule>
  </pattern>

  <!-- in einer Biografie steht URL, das kann zu Fehlern in Verarbeitung führen -->
  <pattern id="BioURL">
    <rule role="warning" context="b044">
      <report test="contains(., 'www.') or contains(., '.de') or contains(., '.com')" > 
        Eine URL sollte nicht in einer Biographical note stehen.
        Vorschlag: Nutze dafür das Website composite.
      </report>
    </rule>
  </pattern>
  
  <!-- IllustrationsNote ist für Anmerkungen da -->
  <pattern id="illustrationsNote">
    <rule role="warning" context="b062">
      <!--<report test="matches(., '^\d+$')"> a </report>
      <report test=". castable as xs:integer"> b </report>-->
      <report test="string(number(.)) != 'NaN'" > 
        In Illustrations note steht nur eine Nummer, obwohl hier eine Anmerkung stehen soll.
        Vorschlag: Überführe die Zahl in Tag b125 (NumberOfIllustrations).
      </report>
    </rule>
  </pattern>

 <!-- Platz für Empfehlungen; hier aus der Dokumentation -->
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
    <rule role="information" context="b044 | othertext[d102 = '13']/d104">
      <report 
        test="matches(., 'seit[\p{Zs}\s]+(\d+|zwei|drei|vier|fünf|sechs|sieben|acht|neun|zehn|elf|zwölf)[\p{Zs}\s]+Jahren', 'i')" > 
        Die Information in der Bio kann veraltet sein. Vorschlag: "seit dem Jahr ..." oder " seit über ... Jahren".
      </report>
    </rule>
  </pattern>

  <!-- Fehlerhafte Worttrennung -->
  <pattern id="Bindestrich">
    <rule role="information" 
      context="product[language[b253 = '01'][b252 = 'ger']]//d104 |
               product[language[b253 = '01'][b252 = 'ger']]//b044">
      <let name="Bindestrich-Regex" value="'\p{L}?\p{Ll}+-\p{Ll}+'"/>
      <!-- hier xsl-Teil mit exists() über report lassen, sonst werden auch stellen von not(. = '...') usw. angezeigt -->
        <xsl:variable name="VBindestrich" as="text()*">
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
      <report test="exists($VBindestrich)"> 
        Liegt eine fehlerhafte Worttrennung vor? Fundstelle(n): <xsl:value-of select="string-join($VBindestrich, ', ')"/>
      </report>
    </rule>
  </pattern>


  <pattern id="dreiIdentBuchstaben">
    <rule role="information" 
      context="title | subject | contributor | othertext/d104">
      <let name="dreiIdentBuchstaben-Regex" value="'[\p{L}]*([\p{L}])\1\1+[\p{L}]*'"/>  
     <xsl:variable name="VdreiIdentBuchstaben" as="text()*">
       <!-- hier xsl-Teil mit exists() über report lassen, sonst werden auch stellen von not(. = 'www') usw. angezeigt -->
        <xsl:analyze-string select="." regex="{$dreiIdentBuchstaben-Regex}">
          <xsl:matching-substring>
            <xsl:if test="
                not(. = 'www') and not(. = 'WWW')
                and
                not(. = 'Hmmm') and not(. = '[Oo]ooh') and not(. = 'hmmm')
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
      context="othertext[d102 = '04'][d103 = '06']/d104">
      <report test="exists(.)" >
        Das TOC könnte auf eine Website übernommen werden und so seine Struktur verlieren.
        Vorschlag: Nutze bei Tag d102 den Code 02 und überführe das TOC in eine HTML-Struktur.
      </report>
    </rule>
  </pattern>

<!-- Kodierungsfehler in Zahl, Bsp.: 200?000 -->
<pattern id="ZahlFehler">
    <rule role="warning" 
      context="title | subject | contributor | othertext/d104" >
      <let name="ZahlFehler-Regex" value="'\d+[?]\d+'"/>
      <report test="matches(., $ZahlFehler-Regex)"> 
        <xsl:variable name="VZahlFehler" as="text()*">
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
  
    <!--Idee: SQF bei ZahlFehler: Fragezeichen entweder zu Punkt machen, löschen oder in engl. Texten zu Komma machen-->

  <!-- nach a o u kommt ein Fragezeichen, Bsp.: fu?r -->
  <pattern id="UmlautFehler">
    <rule role="warning" 
      context="title | subject | contributor | othertext/d104">
      <let name="UmlautFehler-Regex" value="'\w*[aouAOU][?][a-z]\w*'"/>  
      <report test="matches(., $UmlautFehler-Regex)">
        <xsl:variable name="VUmlautFehler" as="text()*">
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
      context="title | subject | contributor | othertext/d104" >
        <let name="SpaceFragezeichen-Regex" value="'\w*\s[?]\W\w*'"/>
        <report  test="matches(., $SpaceFragezeichen-Regex, 's')">
        <xsl:variable name="VSpaceFragezeichen" as="text()*">
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
    context="othertext/d104">
    
<!--    <!-\-A: nach einem Zeichen *außer aou* kommt direkt ein Fragezeichen und danach ein kleiner Buchstabe
      Bsp.: 113?ff -\->
    <let name="weitereKodierungsFehler1-Regex" value="'\w*.[^a^o^u^A^O^U][?]\p{Ll}+'"/> 
    <report test="matches(., $weitereKodierungsFehler1-Regex)">
    <xsl:variable name="VwkF1" as="text()*">
        <xsl:analyze-string select="." regex="{$weitereKodierungsFehler1-Regex}">
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>  
     A: Hier liegen möglicherweise Kodierungsfehler vor. Fundstelle(n): <xsl:value-of select="string-join($VwkF1, ', ')" />
    </report>
   
     <!-\-B: nach einem Punkt kommt direkt ein Fragezeichen und danach ein Großbuchstabe.
    leicht anders, als "Spaces", Bsp.: St.?Gallen -\->
    <let name="weitereKodierungsFehler2-Regex" value="'\w*\.[?]\p{Lu}+'"/>  
    <report test="matches(., $weitereKodierungsFehler2-Regex )">
    <xsl:variable name="VwkF2" as="text()*">
        <xsl:analyze-string select="." regex="{$weitereKodierungsFehler2-Regex}">
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>  
     B: Hier liegen möglicherweise Kodierungsfehler vor. Fundstelle(n): <xsl:value-of select="string-join($VwkF2, ', ')" />      
    </report>-->
    
    
    <!--C: nach einem Zeichen *außer einer Ziffer* kommt direkt ein Fragezeichen und danach eine Ziffer (1?00 ausschließen)
    Bsp.: §?175   kann?10 S.?75-->
    <let name="weitereKodierungsFehler3-Regex" value="'.?\D[?]\d+'"/> 
    <report test="matches(., $weitereKodierungsFehler3-Regex )">
    <xsl:variable name="VwkF3" as="text()*">
        <xsl:analyze-string select="." regex="{$weitereKodierungsFehler3-Regex}">
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


<!--  <diagnostics>
    <diagnostic id="dSupplierWebsite">Tag b367 mit Code 01 ist für die Publisher-Website vorgesehen. </diagnostic>
  </diagnostics>-->
</schema>
