'use strict';

function get_title (xml) {
	return xml.replace(/^[\s\S]+<orth>/,"").replace(/<\/orth>[\s\S]+$/, "");
}

function fix_italics (c) {
	return c.replace(/_([^ ][^_]+)_/g, el("i", "$1"));
}

function format_entry(xml) {

	var div   = function(c) { return el("div", c); }
	var empty = function()  { return "" }
	var id    = function(c) { return c }
	var nbsp  = "&nbsp;";
	return dt(xml, {
		"orth"      : empty,
		
		"pron"      : function(c) { return div("/" + el("i", c) + "/", {"style":"font-weight: bold; color: #777777;"})},
		"usg"       : function(c) { return el("i", c + nbsp)},
		"term"      : function(c) { return nbsp + el("a", c, {"href":"#"})},
		"ref"       : div,

		"#document" : id,
		"#text"     : function(c) { return c.replace(/^[\s\n]+|[\s\n]+$/g, "")},

		"entry"     : div,
		"form"      : div,
		"sense"     : div,
		"etym"      : function(c) { return div(fix_italics(c))},

		"gramGrp"   : function(c) { return el("i", c + nbsp) },
		
		"#default"  : function(c,q,v) { return el("b",q) + ": " + c },
		"def"       : function(c)     { 
			return div(fix_italics(c)
				        .replace(/\n\s*\n/g,"\n").replace(/\n/g,"<br/>")); }
});
}

