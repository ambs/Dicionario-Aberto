
function formatWord(data) {
    var word;
    var entry = xml$dt.process(data, {
	'#map' : { 'form': 'div' },
	'#default' : function(q,c,v) { return xml$dt.tag(q,c,v); },
	'def' : function(q,c,v) {
	    var s = c.replace(/\n/g,"<br/>");
	    return xml$dt.tag(q,c,v);
	},
	'entry': function(q,c,v) {
	    word = v.id + ('n' in v ? "<sup>"+v.n+"</sup>" : "");
	    return xml$dt.tag(q,c,v);
	}
    });
    console.log(entry);
    return { term: word, def: entry };
}

function formatEntry(data) {
    var template = doT.template("<h3>{{=it.term}}</h3><div>{{=it.def}}</div>");
    return template(formatWord(data));
}

