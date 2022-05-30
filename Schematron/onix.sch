<?xml version="1.0" encoding="UTF-8"?>

<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <!--<pattern id="bios">
        <rule context="product/othertext[d102='13']/d104">
            <report test="not(ancestor::product[1][count(contributor)=1]/b044/normalize-space()=normalize-space(.))">
                Es gibt nur einen Contributor und dessen Biografietext weicht vom Text für alle Contributoren ab.
            </report>
        </rule>
    </pattern>-->

    <pattern id="bios2">
        <rule context="product[count(contributor[b035 = 'A01']) = 1]
                              [contributor[b035 = 'A01'][b044]]
                         /othertext[d102 = '13']/d104">
            <assert role="warning"
                test="ancestor::product[1]/contributor[b044]/b044/normalize-space() = normalize-space(.)"> Es gibt nur einen Autor und dessen Biografietext weicht vom Text für alle
                Contributoren ab. </assert>
        </rule>
    </pattern>
    
    <pattern id="Spaces">
        <rule context="d104|b044">
          <let name="Punkt-RegEx" value="'(\p{L}?\p{L}\p{Ll})[.!?]+\p{Lu}\.?'"/>
          <xsl:variable name="Prelim" as="text()*">
                  <xsl:analyze-string select="." regex="{$Punkt-RegEx}">
                    <xsl:matching-substring>
                      <xsl:if test="not(regex-group(1)='www')
                                    and
                                    not(.='Ph.D.')">
                        <xsl:value-of select="."/>
                      </xsl:if>
                    </xsl:matching-substring>
                  </xsl:analyze-string>
                </xsl:variable>
            <report role="warning" test="exists($Prelim)">
                Fehlt ein Leerzeichen zwischen zwei Sätzen? Fundstelle(n): 
              <xsl:value-of select="string-join($Prelim, ', ')"/>
            </report>
        </rule>
    </pattern>
    
   <!-- <pattern id="Ausgabe_ProductFormFeatureDescription">
        <rule context="productformfeature/b336">
            <report test=".">
                ProductFormFeatureValue, Ausgabe freier Text: <value-of select="."/>
            </report>
        </rule>
    </pattern>
    
    <pattern id="EditionNumber_Länge">
        <rule context="b057">
            <report test="string-length(.) &gt; 4">
                Edition number darf nicht mehr als 4 Zeichen enthalten.
            </report>
        </rule>
    </pattern>
    
    <pattern id="Test01nurAusserhalbOtherText">
        <rule context="test01">
            <report test="parent::othertext/test01">
               test01 darf nur außerhalb von othertext auftreten
            </report>
        </rule>
    </pattern>-->
    
    <!--<pattern id="AnzahlProdukte">
        <rule context="product" role="info">
            <report test="count(//product)">Es sind <value-of select="count(//product)"/> Produkte aufgelistet.</report>
        </rule>
    </pattern>-->
</schema>
