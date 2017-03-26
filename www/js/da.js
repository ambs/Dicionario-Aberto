
function parseDate(date) {
    var fields = date.match(/(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+)/);
    return {
	year:    fields[1],
	month:   fields[2],
	day:     fields[3],
	hours:   fields[4],
	minutes: fields[5],
	seconds: fields[6]
    };
}

function formatWord(data) {
    var word;
    var entry = xml$dt.process(data, {
	'#map' : { 'form': 'div' },
	'#default' : function(q,c,v) { return xml$dt.tag(q,c,v); },
	'orth' : function(q,c,v) {
	    if (!('term' in xml$dt.father)) {
		xml$dt.father.term = c;
		return "";
	    }
	    return xml$dt.tag(q,c,v);
	},
	'def' : function(q,c,v) {
	    var s = c.replace(/_([^_]+)_/g, "<i>$1</i>");
	    return xml$dt.tag(q,s,v);
	},
	'etym' : function(q,c,v) {
	    return c.replace(/_([^_]+)_/g, "<i>$1</i>");
	},
	'entry': function(q,c,v) {
	    word = v.id + ('n' in v ? "<sup>"+v.n+"</sup>" : "");
	    return xml$dt.tag(q,c,v);
	}
    });

    return { term: word, def: entry };
}

function formatEntry(data) {
    var template = doT.template("<h3>{{=it.term}}</h3><div>{{=it.def}}</div>");
    return template(formatWord(data));
}

function formatNews(data) {
    var template = doT.template("<dl>{{~it.news :value:index}}<dt>{{=value.date.year}}-{{=value.date.month}}-{{=value.date.day}}</dt><dd>{{=value.text}}</dd>{{~}}</dl>");
    data = $.map(data, function(v,i) { v.date = parseDate(v.date); return v; });
    return template({news: data});
}


function load_template(template_name, callback) {
    var url = "/templates/" + template_name + ".tmpl";
    $.ajax({ url: url, dataType: 'html' , mimeType: 'text/html'})
	.done(function(html){
	    $('#contents').html(html);
	    callback();
	});
}

