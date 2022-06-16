<?xml version="1.0" encoding="UTF-8"?>

<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
  xmlns:sqf="http://www.schematron-quickfix.com/validator/process" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <phase id="test">
    <active pattern="dreiZeichen" />
  </phase>
  
  <phase id="BiografieFehler">
    <active pattern="Bios2"/>
    <active pattern="BioName"/>
  </phase>
  <phase id="TextFehler">
    <active pattern="Spaces"/>
    <active pattern="dreiZeichen"/>
    <active pattern="ZahlFehler"/>
  </phase>
  <phase id="falscheVerwendung">
    <active pattern="BioURL"/>
    <active pattern="illustrationsNote"/>
  </phase>
  <phase id="Empfehlung">
    <active pattern="suggestedLength"/>
  </phase>
   <phase id="Redudanzen">
    <active pattern="Bios3"/>
    <active pattern="SupplierWebsite"/>
  </phase>
  

  <pattern id="Bios2">
        <rule context="product[count(contributor[b035 = 'A01']) = 1]
                              [count(contributor[not(b035 = 'A01')]) = 0]
                              [contributor[b035 = 'A01'][b044]]
                         /othertext[d102 = '13']/d104">
            <assert role="error"
                test="ancestor::product[1]/contributor[b044]/b044/normalize-space() = normalize-space(.)"> Es gibt nur einen Autor und dessen Biografietext weicht vom Text für alle
                Contributoren ab. Hinweis: Tag b044 sollte die Einzelbiographie beherbergen.</assert>
        </rule>
    </pattern>

  <pattern id="Bios3">
    <rule context="product[count(contributor) = 1]/othertext[d102 = '13']/d104" role="information">
      <report 
        test="exists(ancestor::product[1]/contributor/b044)"> Wenn es nur einen Contributor gibt, benötigt es keine
        Biographical note (Tag d102, Code 13). Tag b044 sollte die Einzelbiographie beherbergen. 
      </report>
    </rule>
  </pattern>

  <!--Hinweis, wenn in b044 und 13 das gleiche steht. Redundanz entfernen ; bei Bios3 kommen mehr Fehlermeldungen-->


  <pattern id="Spaces">
    <rule context="d104 | b044" role="warning">
      <let name="Punkt-RegEx" value="'(\p{L}?\p{L}\p{Ll})[.!?]+\p{Lu}\.?'"/>
      <xsl:variable name="Prelim" as="text()*">
        <xsl:analyze-string select="." regex="{$Punkt-RegEx}">
          <xsl:matching-substring>
            <xsl:if test="
                not(regex-group(1) = 'www')
                and
                not(. = 'Ph.D.')">
              <xsl:value-of select="."/>
            </xsl:if>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>
      <report role="warning" test="exists($Prelim)"> Fehlt ein Leerzeichen zwischen zwei Sätzen? Fundstelle(n): <xsl:value-of
          select="string-join($Prelim, ', ')"/>
      </report>
    </rule>
  </pattern>


  <pattern id="BioName">
    <rule context="b044" role="error">
      <let name="b036" value="ancestor::contributor/b036/normalize-space()"/>
      <let name="tokenized" value="tokenize($b036, ' ')"/>
      <let name="firstLast" value="string-join(($tokenized[1], $tokenized[last()]), ' ')"/>
      <let name="b036-regex" value="string-join(for $t in $tokenized return replace(replace($t, '\.', '(\\.|\\w+)'), '\?', '\\?'), ' ')"/>
      <assert test="contains(., $b036) or contains(., $firstLast) or matches(., $b036-regex)"> 
        Der Name des Contributors muss in der Biographical note vorkommen und sollte mit dem angegebenen Namen 
        ('<value-of select="ancestor::contributor/b036"/>') übereinstimmen. 
      </assert>
      <!--reicht nur erster Name und Nachname (Info)? Sonderzeichen/Umlaute?
      wenn in Biografie zusätzlich z.B. "J." steht ggf. noch implementieren
       '\s([A-Z]\.)\s' -->
    </rule>
  </pattern>


  <pattern id="BioURL">
    <rule context="b044" role="warning">
      <report test="contains(., 'www.') or contains(.,'.de' ) or contains(.,'.com' )">
        Eine URL sollte nicht in einer Biographical note stehen. Nutze dafür das Website composite. 
      </report>
    </rule>
  </pattern>
  <!--b044 Some recipients of ONIX data feeds will not accept text which has embedded URLs. A contributor website link can be sent using the <Website> composite.-->


  <pattern id="illustrationsNote">
    <rule context="b062" role="warning">
      <!--<report test="matches(., '^\d+$')"> a 
      </report>
      <report test=". castable as xs:integer"> b 
      </report>-->
      <report test="string(number(.)) != 'NaN'" diagnostics="NumberOfIllustrations"> 
        In Illustrations note steht nur eine Nummer, obwohl hier eine Anmerkung stehen soll.
      </report>
    </rule>
  </pattern>


  <pattern id="suggestedLength">
    <rule context="b336" role="information">
      <report test="./string-length() &gt; 100"> Die empfohlene Länge beträgt hier 100 Zeichen. Wenn möglich, kürze den Text.
      </report>
    </rule>
    <rule context="b203" role="information">
      <report test="./string-length() &gt; 300"> Die empfohlene Länge beträgt hier 300 Zeichen. Wenn möglich, kürze den Text.
      </report>
    </rule>
  </pattern>

  
<pattern id="SupplierWebsite">
  <rule context="product/supplydetail/website[b367='33']/b295"
        role="information">
    <report test="./text() = ancestor::product/publisher/website[b367='01']/b295/text() ">
      Code 33 (List 73) ist redundant: "Eine Unternehmenswebsite, die von einem Händler oder einem anderen Lieferanten (nicht dem Publisher) betrieben wird."
    </report>
  </rule>
  
</pattern>
<!-- &#x2013;&#8220;“   \p{Zs}   \t \r \n\-->


<pattern id="seitJahren">
  <rule context="b044 | othertext[d102 = '13']/d104">
    <report role="info"
      test="matches(., 'seit[\p{Zs}\s]+(\d+|zwei|drei|vier|fünf|sechs|sieben|acht|neun|zehn|elf|zwölf)[\p{Zs}\s]+Jahren', 'i')">
      Die Information in der Bio kann veraltet sein. Besser wäre "seit dem Jahr ..." oder " seit über ... Jahren".
    </report>
  </rule>
</pattern>

  <!--  Bindestrich Bsp.: ostasiati-sche Weisheit -->
  <pattern id="Bindestrich">
        <rule context="product[language[b253='01'][b252='ger']]//d104 |
              product[language[b253='01'][b252='ger']]//b044">
            <!--<report test="matches(., '[a-zäöüßA-Z]-[a-zäöüß]')">-->
            <report test="matches(., '\p{Ll}+-\p{Ll}+')">
              Bindestrich?
            </report>
        </rule>
    </pattern>
  

  
  <pattern id="dreiZeichen">
    <rule context="title | subject | contributor | othertext/d104 ">
     <!-- <let name="dreiIdentZeichen-Regex" value="'.{0,8}([a-zA-Z])\1\1+.{0,8}'"/>-->
      <let name="dreiIdentZeichen-Regex" value="'\p{L}*([a-zA-Z])\1\1+[\p{L}|.]*'"/>
            <xsl:variable name="VdreiZeichen" as="text()*">
        <xsl:analyze-string select="." regex="{$dreiIdentZeichen-Regex}">
          <xsl:matching-substring>
            <xsl:if test="
                not(. = 'www') and not(. = 'WWW')
                 and 
                 not(.='[Hh]mmm')
                 and
                 not(. = 'III') and not(.='[Oo]ooh')">
              <xsl:value-of select="."/>
            </xsl:if>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:variable>
      <report role="info" test="exists($VdreiZeichen)">
        Es tauchen drei identische Buchstaben hintereinander auf. Prüfe, ob ein Rechtschreibfehler vorkommt! 
        Fundstelle(n): <xsl:value-of select="string-join($VdreiZeichen, ', ')"/> 
        <!--ganzes Wort soll ausgegeben werden-->
      </report>
    </rule>
  </pattern>
  
  <pattern id="tocDefaultTextFormat">
    <rule context="othertext[d102='04'][d103='06']/d104" role="information">
      <report test="exists(.)" diagnostics="TOC">
        Das TOC könnte auf eine Website übernommen werden und so seine Struktur verlieren.
      </report>
    </rule>
  </pattern>
  
  <pattern id="ZahlFehler">
    <rule context="title | subject | contributor | othertext/d104" role="warning">
      <report test="matches(., '\d+[?]\d+')">
        Es liegt in einer Zahl möglicherweise ein Fehler vor.
      </report>
    </rule>
  </pattern>
  
  
  <diagnostics>
    <diagnostic id="NumberOfIllustrations">Die Zahl passt besser in NumberOfIllustrations (Tag b125).</diagnostic>
    <diagnostic id="TOC">Nutze bei Tag d104 den Code 02 und überführe das TOC in eine HTML-Struktur.</diagnostic>
  </diagnostics>
  
</schema>
