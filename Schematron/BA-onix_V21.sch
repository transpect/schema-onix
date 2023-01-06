<?xml version="1.0" encoding="UTF-8"?>

<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
  xmlns:sqf="http://www.schematron-quickfix.com/validator/process" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <phase id="EinzelTest">
    <active pattern="Spielmeldung"/><!--Für Anpassung dem Attributwert die ID des entspr. Patterns geben-->
  </phase>
  
  <phase id="FalscheVerwendung">
    <active pattern="AbbildungsnotizSeiten"/>
    <active pattern="EditionsbeschreibungZiffer"/>
    <active pattern="Spielmeldung"/>
    <active pattern="AbbildungsnotizZiffer"/>
    <active pattern="UntertitelAuflage"/>
    <active pattern="UntertitelErweiterung"/>
  </phase>
  <phase id="BiografieFehler">
    <active pattern="ContributorGesamtbio"/>
    <active pattern="EinContributorBios"/>
    <active pattern="AutorenBios"/> 
    <active pattern="BioName"/>
    <active pattern="BioURL"/>
  </phase>
  <phase id="TextFehler">
    <active pattern="Bindestrich"/>
    <active pattern="DreiBuchstaben"/>
    <active pattern="FehlendesSpace"/>
    <active pattern="ZahlFehler"/>
    <active pattern="UmlautFehler"/>
    <active pattern="SonstigeKodierungsfehler"/>
  </phase>
  <phase id="Empfehlung">
    <active pattern="KeywordInflation"/>
    <active pattern="Zeichenlaenge"/>
    <active pattern="SeitJahren"/>
    <active pattern="TOCDefaultTextFormat"/>
  </phase>

  <properties>
    <property id="refname"><xsl:value-of select="@refname"/></property>
  </properties>


  <!-- NEU:Spielmeldung 4.3. , not() in erstem Report-Test, damit sich die Meldungen nicht überschneiden -->
  <pattern id="Spielmeldung">
    <rule context="*:b012[.='BZ'] | *:b012[.='PZ'] | *:b012[.='ZA'] | 
                   *:b012[.='ZZ'] | *:b012[.='00']" >
      <!-- ONIX 2.1 -->
      <report role="information" 
        test="exists(.) and not(parent::product/title[matches(., 'Spiel|spiel|Quiz|quiz|Game|game')])"
        properties="refname">
        Es handelt sich möglicherweise um ein Nonbookprodukt, das ungenau kategorisiert wurde.
        Vorschlag: In b012 (ProductForm) den Code anpassen.
      </report>
      <report role="warning" 
        test="parent::product/title[matches(., 'Spiel|spiel|Quiz|quiz|Game|game')]"
        properties="refname">
        Handelt es sich bei dem Produkt um ein Spiel? Vorschlag: In b012 (ProductForm) den Code ZE nutzen.
      </report>
      
      <!-- ONIX 3.0 (hier kann schwer verhindert werden, dass nicht auch die Meldung des ersten Reports genannt wird. -->
      <report role="warning" 
        test="ancestor::*:product//*:titledetail[matches(., 'Spiel|spiel|Quiz|quiz|Game|game')]"
        properties="refname">
        Handelt es sich bei dem Produkt um ein Spiel? Vorschlag: In b012 (ProductForm) den Code ZE nutzen.
      </report>
    </rule>
  </pattern>
  


    <!-- NEU: inflat. Verwendung von Kewords, Tag b067 List 20-->
    <pattern id="KeywordInflation">
        <rule role="information" 
          context="*:product//*:subject[1]">
          <report 
              test="ancestor::*:product[count(.//*:b067/'20') &gt; 35]"
              properties="refname"> 
              Reduziere die Keywords. Es sind über 35 Keywords zu diesem Produkt eingetragen.
            </report>
        </rule>
    </pattern> 


<!--NEU: Seitenzahl in IllustrationsNote b062 (Verlag C)-->
    <pattern id="AbbildungsnotizSeiten">
        <rule role="warning" 
            context="*:b062">
            <report 
              test="matches(., 'S[.]')" 
              properties="refname" > 
              Befindet sich eine Seitenzahlangabe in b062 (IllustrationsNote)? Vorschlag: Überführe die Seitenzahlangabe in b061 (NumberOfPages).
            </report>
        </rule>
    </pattern>

<!--NEU: EditionStatement b058 (Verlag D, E, A_V30):  muss eine Beschreibung der Edition enthalten. Nicht nur Zahl.-->
    <pattern id="EditionsbeschreibungZiffer">
        <rule role="error" context="*:b058">
            <report 
              test="string(number(.)) != 'NaN'" 
              properties="refname"> 
                In b058 (EditionStatement) steht nur eine Nummer, obwohl hier eine Beschreibung der Edition sein soll.
            </report>
        </rule>
    </pattern>


  <!-- Nur ein Contributor (egal welche Rolle), Texte unterscheiden sich -->
  <pattern id="EinContributorBios">
    <rule role="error" context="
               *:product[count(*:contributor) = 1]
               [*:contributor/*:b044]
               /*:othertext[*:d102 = '13']/*:d104 |
               
               *:product[count(.//*:contributor) = 1]
               [.//*:contributor/*:b044]
               //*:textcontent[*:x426 = '12']/*:d104">
      <assert 
        test="ancestor::*:product[1]//*:contributor[*:b044]/*:b044/normalize-space() = normalize-space(.)"
        properties="refname"> 
        Es gibt nur einen Contributor und dessen Biografietext weicht vom Text für alle Contributoren ab. 
        Wenn es nur einen Contributor gibt, benötigt es keine Gesamtbiografie im Other text bzw. Text content composite.
      </assert>
    </rule>
  </pattern>



  <!-- Mehrere Contributoren mit Autorenrolle, aber nicht jeder hat eine Einzelbiografie -->
  <!--Fall vermeiden, dass es z.B. 2 Autoren gibt und nur einer eine Bio hat, die in die Gesamtbio kommt-->
  <pattern id="AutorenBios">
    <rule role="error" 
      context="*:product[count(.//*:contributor[*:b035 = 'A01']) &gt; 1]
               //*:contributor[b035 = 'A01']/*:b044 ">
      <report 
          test="ancestor::*:product[1]
                [count(.//*:contributor[*:b035 = 'A01']) != count(.//*:contributor[*:b035 = 'A01']/*:b044)]"
          properties="refname"> 
        Es gibt ungleich viele Autoren und Biografien in b044 (BiographicalNote). Dies kann zu Fehlern in der Gesamtbiografie im Other text bzw. Text content composite führen.
      </report>
    </rule>
  </pattern>
  
  <!-- Mehr als ein Contributor, einer davon hat einen Text und dieser stimmt mit Gesamtbiografie überein (falsche Verwendung)-->
  <pattern id="ContributorGesamtbio">
    <rule role="error" context="
                *:product[count(*:contributor) &gt; 1]
                [*:contributor/*:b044]
                /*:othertext[*:d102 = '13']/*:d104 |
               
               *:product[count(.//*:contributor) &gt; 1]
               [.//*:contributor/*:b044]
               //*:textcontent[*:x426 = '12']/*:d104">
      <report 
        test="ancestor::*:product[1]//*:contributor[*:b044]/*:b044/normalize-space() = normalize-space(.)"
        properties="refname"> 
        Der Biografietext eines Contributors stimmt mit dem Text für alle Contributoren im Other text bzw. Text content composite überein,
        obwohl es darin aber um mehrere Contributoren gehen sollte.
        Vorschlag: Der Biografietext im Other text bzw. Text content composite sollte gelöscht werden.
      </report>
    </rule>
  </pattern>

<!-- Fehlendes Leerzeichen zwischen zwei Sätzen, Bsp.: Buch:Wer
  FehlendesSpace mit exists--> <!-- Nr. 1: d104 | b044 ; Nr. 2: ONIXmessage/product/othertext/d104 | ONIXmessage/product/contributor/b044 ;
  Nr. 3: ONIXmessage/product[contributor/b044|othertext/d104] Nr. 4: nur product, so gibt es weniger Fehlermeldungen-Anzahl-->
  <pattern id="FehlendesSpace">
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
      <report 
        test="exists($VPunkt)"
        properties="refname"> 
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
      <assert 
        test="contains(., $b036) or contains(., $firstLast) or matches(., $b036-regex)"
        properties="refname"> 
        Der Name des Contributors muss im Biografietext vorkommen und sollte mit dem angegebenen Namen ('<value-of select="ancestor::*:contributor/*:b036"/>')
        übereinstimmen. 
      </assert>
    </rule>
  </pattern>

  <!-- in einer Biografie steht URL, das kann zu Fehlern in Verarbeitung führen -->
  <pattern id="BioURL">
    <rule role="error" context="*:b044">
      <report 
        test="contains(., 'www.') or contains(., '.de') or contains(., '.com')"
        properties="refname"> 
        Eine URL sollte nicht in einer Biographical note stehen.
        Vorschlag: Nutze dafür das Website composite.
      </report>
    </rule>
  </pattern>
  
  <!-- IllustrationsNote ist für Anmerkungen da -->
  <pattern id="AbbildungsnotizZiffer">
    <rule role="error" context="*:b062">
      <!--<report test="matches(., '^\d+$')"> a </report>
      <report test=". castable as xs:integer"> b </report>-->
      <report 
        test="string(number(.)) != 'NaN'"
        properties="refname"> 
        In b062 (IllustrationsNote) steht nur eine Nummer, obwohl hier eine Anmerkung stehen soll.
        Vorschlag: Überführe die Zahl in b125 (NumberOfIllustrations).
      </report>
    </rule>
  </pattern>

 <!-- Empfehlungen für Zeichenlängen in best. Elementen; hier aus der Dokumentation -->
  <!-- individuelle Empfehlungen oder Wünsche auch mgl. -->
  <pattern id="Zeichenlaenge">
<!--    <rule role="information" context="*:b203">
      <report 
        test="./string-length() &gt; 300"
        properties="refname" > 
        Die empfohlene Länge beträgt hier 300 Zeichen. Vorschlag: Kürze den Text.
      </report>
    </rule>-->
     <rule role="information" context="*:b336">
      <report 
        test="./string-length() &gt; 100"
        properties="refname"> 
        Die empfohlene Länge beträgt hier 100 Zeichen. Wenn möglich, kürze den Text.
      </report>
    </rule>
  </pattern>

  <!-- Empfehlung bei seit ... Jahren -->
  <pattern id="SeitJahren">
    <rule role="warning" context="*:b044 | *:othertext[*:d102 = '13']/*:d104 | *:textcontent[*:x426='12']/*:d104">
      <report 
        test="matches(., 'seit[\p{Zs}\s]+(\d+|zwei|drei|vier|fünf|sechs|sieben|acht|neun|zehn|elf|zwölf)[\p{Zs}\s]+Jahren', 'i')"
        properties="refname"> 
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
      <report 
        test="exists($VBindestrich)" 
        properties="refname"> 
        Liegt eine fehlerhafte Worttrennung vor? Fundstelle(n): <xsl:value-of select="string-join($VBindestrich, ', ')"/>
      </report>
    </rule>
  </pattern>  
  
  
  

<!-- drei ident. Buchstaben hintereinander, Bsp.: solllte-->
  <pattern id="DreiBuchstaben">
    <rule role="information" 
      context="*:title | *:subject | *:contributor | *:d104">
      <let name="DreiBuchstaben-Regex" value="'[\p{L}]*([\p{L}])\1\1+[\p{L}]*'"/>  
     <xsl:variable name="VDreiBuchstaben" as="xs:string*">
       <!-- hier xsl-Teil mit exists() über report lassen, sonst werden auch Stellen von not(. = 'www') usw. angezeigt --> <!-- bei if müssen Groß- und Kleinbuchstaben extra erfasst werden. i bringt eig. nichts -->
        <xsl:analyze-string select="." regex="{$DreiBuchstaben-Regex}" flags="i">
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
      <report 
        test="exists($VDreiBuchstaben)"
        properties="refname"> 
        Drei identische Buchstaben erscheinen hintereinander. Liegt ein Rechtschreibfehler vor? 
        Fundstelle(n): <xsl:value-of select="string-join($VDreiBuchstaben, ', ')"/>
      </report>
    </rule>
  </pattern>
  


  <!-- Hinweis, dass es ein IHV im Default text format gibt, nur für ONIX V2.1 -->
  <pattern id="TOCDefaultTextFormat">
    <rule role="information"
      context="*:othertext[*:d102 = '04'][*:d103 = '06']/*:d104">
      <!-- auch mgl.: test="exists", da werden keine br / geduldet. -->
      <report
        test="not(matches(., 'br /'))"
        properties="refname">
        Das TOC könnte auf eine Website übernommen werden und so seine Struktur verlieren.
        Vorschlag: Nutze bei d102 den Code 02 und überführe das TOC in eine HTML-Struktur.
      </report>
    </rule>
  </pattern>

<!-- Kodierungsfehler in Zahl, Bsp.: 200?000 -->
<pattern id="ZahlFehler">
    <rule role="warning" 
      context="*:title | *:subject | *:contributor | *:d104 | 
               *:titleelement" >
      <let name="ZahlFehler-Regex" value="'\d+[?]\d+'"/>
      <report 
        test="matches(., $ZahlFehler-Regex)"
        properties="refname"> 
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
  
  
    <!--Idee: SQF bei ZahlFehler: Fragezeichen entweder zu Punkt machen, löschen oder in engl. Texten zu Komma machen-->

  <!-- nach a o u kommt ein Fragezeichen, Bsp.: fu?r -->
  <pattern id="UmlautFehler">
    <rule role="warning" 
      context="*:title | *:subject | *:contributor | *:d104 |
               *:titleelement">
      <let name="UmlautFehler-Regex" value="'\w*[aouAOU][?][a-z]\w*'"/>  
      <report 
        test="matches(., $UmlautFehler-Regex)"
        properties="refname">
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
  

<!-- drei weitere Kodierungsfehler mit Fragezeichen; dabei sind die vorherigen Fehler ausgeschlossen.
    Fundstellen nur in OtherText -->
<pattern id="SonstigeKodierungsfehler">
  <rule role="warning"
    context="*:d104 | *:b044">
    
   <!-- SpaceFragezeichen:
   vor einem Fragezeichen ist ein Whitespace und danach folgt *keine Ziffer oder kein Buchstabe*
       Bsp.: 2018 ? 1--> 
    <let name="SpaceFragezeichen-Regex" value="'\w*\s[?]\W\w*'"/>
    <report  
      test="matches(., $SpaceFragezeichen-Regex, 's')"
      properties="refname">
      <xsl:variable name="VSpaceFragezeichen" as="xs:string*">
        <xsl:analyze-string select="." regex="{$SpaceFragezeichen-Regex}" flags="s">
          <xsl:matching-substring>
            <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>
     A: Hier liegen möglicherweise Zeichenfehler mit einem Whitespace vor.  
      Fundstelle(n): <xsl:value-of select="string-join($VSpaceFragezeichen, ', ')" />
    </report>
    
    <!-- B: nach einem Zeichen *außer aou* kommt direkt ein Fragezeichen und danach ein kleiner Buchstabe
      Bsp.: 113?ff -->
    <let name="SonstigeKodierungsfehler1-Regex" value="'\w*.[^a^o^u^A^O^U][?]\p{Ll}+'"/> 
    <report 
      test="matches(., $SonstigeKodierungsfehler1-Regex)"
      properties="refname">
    <xsl:variable name="VwkF1" as="xs:string*">
        <xsl:analyze-string select="." regex="{$SonstigeKodierungsfehler1-Regex}" flags="s">
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>  
     B: Hier liegen möglicherweise Kodierungsfehler vor. Fundstelle(n): <xsl:value-of select="string-join($VwkF1, ', ')" />
    </report>
   
     <!--C: nach einem Punkt kommt direkt ein Fragezeichen und danach ein Großbuchstabe.
    leicht anders, als "FehlendesSpace", Bsp.: St.?Gallen -->
    <let name="SonstigeKodierungsfehler2-Regex" value="'\w*\.[?]\p{Lu}+'"/>  
    <report 
      test="matches(., $SonstigeKodierungsfehler2-Regex )"
      properties="refname">
    <xsl:variable name="VwkF2" as="xs:string*">
        <xsl:analyze-string select="." regex="{$SonstigeKodierungsfehler2-Regex}" flags="s" >
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>  
     C: Hier liegen möglicherweise Kodierungsfehler vor. Fundstelle(n): <xsl:value-of select="string-join($VwkF2, ', ')" />      
    </report>
    
    <!--D: nach einem Zeichen *außer einer Ziffer* kommt direkt ein Fragezeichen und danach eine Ziffer (1?00 ausschließen)
    Bsp.: §?175   kann?10 S.?75-->
    <let name="SonstigeKodierungsfehler3-Regex" value="'.?\D[?]\d+'"/> 
    <report 
      test="matches(., $SonstigeKodierungsfehler3-Regex )"
      properties="refname">
    <xsl:variable name="VwkF3" as="xs:string*">
        <xsl:analyze-string select="." regex="{$SonstigeKodierungsfehler3-Regex}" flags="s">
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>  
     D: Hier liegen möglicherweise Kodierungsfehler vor. Fundstelle(n): <xsl:value-of select="string-join($VwkF3, ', ')" />        
    </report>
    
  </rule>
</pattern>



<!-- Die Auflage steht im Untertitel-Segment, 
    Bsp.: 2., aktualisierte Auflage -->
<pattern id="UntertitelAuflage">
  <rule role="error" context="*:b029">
    <report 
      test="contains(., 'Auflage')"
      properties="refname">
      In b029 (Subtitle) steht die Auflage. 
      Vorschlag: Überführe den Text in b058 (EditionStatement).
    </report>
  </rule>
</pattern>
  
  
  <!-- im Untertitel-Segment stehen evtl. Marketinginformationen,
  Bsp.: How to Transform Your Organization from the Inside Out, plus E-Book inside (ePub, mobi oder pdf)-->
  <pattern id="UntertitelErweiterung">
  <rule role="warning" context="*:b029">
    <report 
      test="contains(., 'Book')"
      properties="refname">
      In b029 (Subtitle) stehen möglicherweise Marketinginformationen. 
      Vorschlag: Überführe die Information in ein Other text bzw. Text content composite.
    </report>
  </rule>
</pattern>


  
</schema>
