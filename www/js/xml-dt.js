
/*
var xmlString = "<entry><term>casa</term><usg type=\"dom\">Fam.</usg><def>edificio quadrado</def></entry>";


    var r = dt( xmlString , { 
    	"usg"   : function(c,q,v) { return el(v.type + ": " + el(c,"i"), "div"); },
    	"def"   : function(c,q,v) { return el(c, "p"); },
    	"term"  : function(c,q,v) { return el(c, "b", {'style':'text-decoration: underline;'});  },
    	"entry" : function(c,q,v) { return el(c, "div"); }
    } );

    document.getElementById("here").innerHTML=r;
*/

function el(content, name, attr) {
	attr = attr || {};

	var r = "<" + name;
	for (var aname in attr) {
		r += " " + aname + "\"" + attr[aname] + "\"";
	}
	r += ">" + content + "</" + name + ">";
	
	return r;
}

function dt(str, conf) {
	var parser = new DOMParser();
	xml = parser.parseFromString(str, "text/xml");

	return __dt(xml, conf);
}

function __map(list, func) {
	var r = [];
	for (var i = 0; i < list.length; i++) {
		r.push(func(list[i]));
	}
	return r;
}

function __dt(element, conf) {
	var child;
	if (element.childNodes.length > 0) {
		childs = __map(element.childNodes, function(x) { return __dt(x, conf); });
		child = childs.join("");
	}
	else {
		child = element.data;
	}

	var attr = {};
	var attributes = element.attributes; // nodeName / nodeValue
	for (var i = 0; attributes && i < attributes.length; i++) {
		attr[attributes[i].nodeName] = attributes[i].nodeValue;
	}

	var result = child;
	if (element.nodeName in conf) {
		result = conf[element.nodeName](child, element.nodeName, attr);
	}
	else if ("#default" in conf && element.nodeName != "#text") {
		result = conf["#default"](child, element.nodeName, attr);	
	}

	return result;
}

