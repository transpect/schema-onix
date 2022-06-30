<?xml version="1.0" encoding="UTF-8"?>

<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
  xmlns:sqf="http://www.schematron-quickfix.com/validator/process" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <phase id="test">
    <active pattern="SpaceFragezeichen"/>
<!--    <active pattern="Bios3b"/>-->
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
    <active pattern="FragezeichenInWort"/>
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

<!--nur ein Contributor, egal welche Rolle (kürzere Formulierung als Bios2)-->
  <pattern id="Bios1">
  <!-- Texte unterscheiden sich -->
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


<!--  <pattern id="Bios2">
    <rule role="error" context="
        product[count(contributor[b035 = 'A01']) = 1]
        [count(contributor[not(b035 = 'A01')]) = 0]
        [contributor[b035 = 'A01'][b044]]
        /othertext[d102 = '13']/d104">
      <assert test="ancestor::product[1]/contributor[b044]/b044/normalize-space() = normalize-space(.)" 
              diagnostics="Bios2"> 
        Es gibt nur einen Autor (und keine weiteren Contributoren) und dessen Biografietext weicht vom Text für alle Contributoren ab.
      </assert>
    </rule>
  </pattern>-->

<!--
<!-\- Wenn es nur 1 Contributor gibt -\->
  <pattern id="Bios3a"> <!-\- Bios 3a und Bios1 (und Bios2) ergeben das gleiche! -\->
    <!-\- Texte unterscheiden sich -\->
    <rule role="warning"
      context="product[count(contributor) = 1]/othertext[d102 = '13']/d104" >
      <report test="ancestor::product[1]/contributor/b044/normalize-space() != normalize-space(.)"
              diagnostics="dBios3"> 
        Wenn es nur einen Contributor gibt, benötigt es keine Biographical note. 
        Die Angaben der Biografien unterscheiden sich.
       (Tag d102, Code 13, "A note referring to all contributors to a product – NOT linked to a single contributor"). 
      </report> 
    </rule>
  </pattern >-->
  
  <pattern id="Bios3b"> <!-- Bios3b müsste das gleiche ergeben wie Bios6Hinweis - nein -->
     <rule role="information"
      context="product[count(contributor) = 1]/othertext[d102 = '13']/d104" >
        <!-- Texte stimmen überein -->
      <report test="ancestor::product[1]/contributor[b044]/b044/normalize-space() = normalize-space(.)" > 
            Der Biografietext des einzigen Contributors stimmt mit dem Text für alle Contributoren überein.
            Das OtherText composite mit der Biographical note ist redundant und kann gelöscht werden. 
      </report>
     </rule>
  </pattern>
  
  
  <!--Fall vermeiden, dass es z.B. 2 Autoren gibt und nur einer eine Bio hat, die in die Gesamtbio kommt-->
  <pattern id="Bios4">
    <rule role="error" 
          context="product[count(contributor[b035 = 'A01']) &gt; 1]/contributor[b035 = 'A01']/b044">
      <report test="ancestor::product[1][count(contributor[b035 = 'A01']) != count(contributor[b035 = 'A01']/b044)]" > 
        Es gibt ungleich viele Autoren und Biografien (Tag b044). Dies kann zu Fehlern in der Biographical note im OtherText composite führen.
      </report>
    </rule>
  </pattern>
  
  
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

  <pattern id="Spaces">
    <rule role="warning" context="d104 | b044" >
    <let name="Punkt-RegEx" value="'(\p{Lu}?\p{L}*\p{Ll})[.:!?]\p{Lu}\w*'"/>
      <!--<let name="Punkt-RegEx" value="'(\p{L}?\p{L}\p{Ll})[.!?]+\p{Lu}\w?'"/>--> <!-- passt auch auf .?  z. B. St.?Ga-->
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


  <pattern id="BioURL">
    <rule role="warning" context="b044">
      <report test="contains(., 'www.') or contains(., '.de') or contains(., '.com')"
              diagnostics="dBioURL" > 
        Eine URL sollte nicht in einer Biographical note stehen.
      </report>
    </rule>
  </pattern>
  <!--b044 Some recipients of ONIX data feeds will not accept text which has embedded URLs. A contributor website link can be sent using the <Website> composite.-->


  <pattern id="illustrationsNote">
    <rule role="warning" context="b062">
      <!--<report test="matches(., '^\d+$')"> a </report>
      <report test=". castable as xs:integer"> b </report>-->
      <report test="string(number(.)) != 'NaN'" > 
        In Illustrations note steht nur eine Nummer, obwohl hier eine Anmerkung stehen soll.
        (Die Zahl passt besser in NumberOfIllustrations (Tag b125)).
      </report>
    </rule>
  </pattern>


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


  <pattern id="seitJahren">
    <rule role="information" context="b044 | othertext[d102 = '13']/d104">
      <report 
        test="matches(., 'seit[\p{Zs}\s]+(\d+|zwei|drei|vier|fünf|sechs|sieben|acht|neun|zehn|elf|zwölf)[\p{Zs}\s]+Jahren', 'i')" 
        diagnostics="dseitJahren" > 
        Die Information in der Bio kann veraltet sein. 
      </report>
    </rule>
  </pattern>


  <pattern id="Bindestrich">
    <rule role="information" 
      context="product[language[b253 = '01'][b252 = 'ger']]//d104 |
               product[language[b253 = '01'][b252 = 'ger']]//b044">
      <let name="Bindestrich-Regex" value="'\p{L}?\p{Ll}+-\p{Ll}+'"/>
      <report test="matches(., $Bindestrich-Regex)"> 
        <xsl:variable name="VBindestrich" as="text()*">
        <xsl:analyze-string select="." regex="{$Bindestrich-Regex}">
          <xsl:matching-substring>
            <xsl:if test="
                not(. = 'öffentlich-rechtlich') and not(. = 'Start-up')
                and
                not(. = 'Know-how') and not(. = 'deutsch-')">
              <xsl:value-of select="."/>
            </xsl:if>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>
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
        Drei identische Buchstaben erscheinen hintereinander. Prüfe, ob ein Rechtschreibfehler vorliegt! 
        Fundstelle(n): <xsl:value-of select="string-join($VdreiIdentBuchstaben, ', ')"/>
      </report>
    </rule>
  </pattern>


  <pattern id="tocDefaultTextFormat">
    <rule role="information"
      context="othertext[d102 = '04'][d103 = '06']/d104">
      <report test="exists(.)" 
              diagnostics="TOC"> 
        Das TOC könnte auf eine Website übernommen werden und so seine Struktur verlieren. 
      </report>
    </rule>
  </pattern>

  
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

  
  <pattern id="UmlautFehler">
    <rule role="warning" 
      context="title | subject | contributor | othertext/d104">
      <let name="UmlautFehler-Regex" value="'[\p{L}]*[aouAOU][?][a-z][\p{L}]*'"/>  
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
  

   <pattern id="FragezeichenInWort">
    <rule role="warning"
      context="title | subject | contributor | othertext/d104" >     
      <let name="FragezeichenInWort-Regex" value="'\p{L}+[^a^o^u^A^O^U][?][\p{Ll}]+'"/> 
      <!--alt: '[\p{L}]*[b-np-tv-zäöüßB-NP-TV-ZAÖÜ][?][\p{Ll}]+' : äöüß waren noch ausgeschlossen
       '[\p{L}]*[\p{Ll}]+[^(aou)]*[?][\p{Ll}]+' :  hat auch  alles?[...]?sehr   das ?limbische   d.?h angezeigt-->
      <report test="matches(., $FragezeichenInWort-Regex, 's')"> 
      <xsl:variable name="VFragezeichenInWort" as="text()*">
        <xsl:analyze-string select="." regex="{$FragezeichenInWort-Regex}" flags="s"> <!-- flags="s" -->
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable> 
        Möglicherweise liegt ein Zeichenfehler in einem Wort vor. 
        Fundstelle(n): <xsl:value-of select="string-join($VFragezeichenInWort, ', ')" />
      </report>
    </rule>
   </pattern>
  
<pattern id="SpaceFragezeichen">
      <rule role="warning"
      context="title | subject | contributor | othertext/d104" >
<!--  alt:   <let name="SpaceFragezeichen-Regex" value="'(.{0,6})\s+[?](.{0,6})'"/> -->
        <let name="SpaceFragezeichen-Regex" value="'\w*\s+[?]\s\w*'"/>
        <report  test="matches(., $SpaceFragezeichen-Regex, 's')"> <!-- Bsp  passt -->
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

<pattern id="weitereKodierungsFehler">
  <rule role="warning"
    context="othertext/d104"> <!-- nur OtherText -->
    
    <let name="weitereKodierungsFehler-Regex" value="'\d+[?]\p{Ll}+'"/>
    <!-- Zahl Fragezeichen Buchstabe, z. B. 113?ff -->
    <report test="matches(., $weitereKodierungsFehler-Regex)">
    <xsl:variable name="VwkF" as="text()*">
        <xsl:analyze-string select="." regex="{$weitereKodierungsFehler-Regex}">
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>  
     A: Hier liegen möglicherweise Kodierungsfehler vor. Fundstelle(n): <xsl:value-of select="string-join($VwkF, ', ')" />
    </report>
    
    <let name="weitereKodierungsFehler2-Regex" value="'\w*[/§]+[?][\P{Ll}]\w*'"/>   
    <!-- nach Sonderzeichen (außer Punkt) kommt Fragezeichen und danach alles außer kl. Buchstabe  -->
    <!--<let name="weitereKodierungsFehler2-Regex" value="'\w*(\p{Pe}|\p{Po})+[?]\w*'"/>-->   
    <report test="matches(., $weitereKodierungsFehler2-Regex )">
    <xsl:variable name="VwkF2" as="text()*">
        <xsl:analyze-string select="." regex="{$weitereKodierungsFehler2-Regex}">
          <xsl:matching-substring>
              <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>  
     B: Hier liegen möglicherweise Kodierungsfehler vor. Fundstelle(n): <xsl:value-of select="string-join($VwkF2, ', ')" />      
    </report>
    
     <let name="weitereKodierungsFehler3-Regex" value="'\w*[/.§%]+[?]\p{Ll}+\w*'"/> 
    <!-- nach Sonderzeichen kommt Fragezeichen und danach kleiner Buchstabe (id="Spaces" Großbuchstaben ausschließen) -->
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


  <diagnostics>
    <diagnostic id="dBioURL">Nutze dafür das Website composite. </diagnostic>
    <diagnostic id="dSupplierWebsite">Tag b367 mit Code 01 ist für die Publisher-Website vorgesehen. </diagnostic>
    <diagnostic id="TOC">Nutze bei Tag d102 den Code 02 und überführe das TOC in eine HTML-Struktur.</diagnostic>
    <diagnostic id="dseitJahren">Besser wäre "seit dem Jahr ..." oder " seit über ... Jahren".</diagnostic>
  </diagnostics>
</schema>
