'use strict';

function fix_italics (c) {
	return c.replace(/_([^ ][^_]+)_/g, el("i", "$1"));
}

function format_entry(xml) {

	var div   = function(c) { return el("div", c); }
	var empty = function()  { return "" }
	var id    = function(c) { return c }

	return dt(xml, {
		"orth"      : empty,
		
		"#document" : id,
		"#text"     : function(c) { return c.replace(/^[\s\n]+|[\s\n]+$/g, "")},

		"entry"     : div,
		"form"      : div,
		"sense"     : div,
		"etym"      : function(c) { return div(fix_italics(c))},

		"gramGrp"   : function(c) { return el("div", el("i", c)) },
		
		"#default"  : function(c,q,v) { return el("b",q) + ": " + c },
		"def"       : function(c)     { 
			return div(fix_italics(c)
				        .replace(/\n\s*\n/g,"\n").replace(/\n/g,"<br/>")); }
});
}

