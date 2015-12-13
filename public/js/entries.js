function validateXML(xmlString) {
    try {
        if (document.implementation.createDocument) {
            var parser = new DOMParser();
            var myDocument = parser.parseFromString(xmlString, "text/xml");
            with (myDocument.documentElement) {
                if (tagName=="parseerror" ||
                    namespaceURI=="http://www.mozilla.org/newlayout/xml/parsererror.xml") {
                    return false;
                }
            }
        } else if (window.ActiveXObject) {
            var myDocument = new ActiveXObject("Microsoft.XMLDOM")
            myDocument.async = false
            var nret=myDocument.loadXML(xmlString);
            if (!nret) {
                return false;
            }
        }
    } catch(e) {
        return false;
    }
    return true;
}

function quotemeta (s) {
  return s.replace( /([^a-zA-Z0-9])/g, "\\$1" );
}

function check_entry() {
    var xml   = $('#xml').val();
    var word  = $('#w').val();
    var sense = $('#s').val();

    // 1. check <entry id
    var re;
    if ((re = xml.match(/<entry[^>]* n=(['"])(\d+)\1/)) && re &&
        sense == re[2] &&
        !xml.match("<entry[^>]+id=(['\"])" + quotemeta(word) + ":" + sense + "\\1"))
    {
        alert("O identificador do elemento <entry> está errado!\nVerifique que não alterou a palavra, e que o número da acepção se mantém.");
        return false;
    }

    if (xml.match(/<entry[^>]* n=(['"])(\d+)\1/) &&
        !xml.match(/<entry[^>]* type=(['"])hom\1/)) {
        alert("Se a palavra tem mais que uma acepção, o element <entry> deve indicar que se trata de uma palavra homónima com 'type=\"hom\"'.");
        return false;
    }

    if (!xml.match(/<entry[^>]* n=(['"])(\d+)\1/) && sense > 1) {
        alert("O atributo n do elemento <entry> está em falta!");
        return false;
    }

    if (!xml.match(/<entry[^>]* n=(['"])(\d+)\1/) && 
        !xml.match("<entry[^>]* id=(['\"])" + quotemeta(word) + "\\1")) {
        alert("O identificador do elemento <entry> está errado! Não pode alterar a palavra!");
        return false;
    }

    if (!xml.match(new RegExp("<orth>\.*" + quotemeta(word) + "\.*</orth>","i"))) {
        alert("O elemento <orth> é obrigatório, e deve conter a palavra.");
        return false;
    }

    if (!validateXML(xml)) {
        alert("O bloco XML parece não ser válido!");
        return false;
    }

    // alert("OK"); // useful for debuging

    return true;
}
