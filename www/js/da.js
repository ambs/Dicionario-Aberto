function formatBrowse(data) {
    return $.map(data.words, function(v,i) {
	var ar;
	if (ar = v.word.match(/([^:]+):(\d+)/)) {
	    return div(entryLink(ar[0], ar[1]));
	} else {
	    return div(entryLink(v.word));
	}
    });
}

function update_browse(cid) {
    $.ajax({
	url: 'http://camelia.perl-hackers.net/browse/' + cid
    }).done(function(data) {
	var size = data.words.length;
	if (data.cid - size/2 > 0) {
	    $('#browseUp').removeClass('hidden');
	    $('#browseUp').unbind().click(function(){
		update_browse(data.cid - size  + 1);
	    });
	}
	else {
	    $('#browseUp').addClass('hidden');
	}


	if (Math.round(data.cid + size / 2 - 1) == data.words[data.words.length-1].id) {
	    $('#browseDown').removeClass('hidden');
	    $('#browseDown').unbind().click(function(){
		update_browse(data.cid + size  - 1);
	    });
	}
	else {
	    $('#browseDown').addClass('hidden');
	}
	
	$('#browseContents').html(formatBrowse(data));
    });
}

function formSearchBox() {
    var word = $('#word').val();
    $.router.go('/search/' + word);
}


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

function formatNearMisses(data) {
    return $.map(data, function(v,i) {
	return div4(spanOnClick(v, "$.router.go('/search/" + v + "');"));
    }).join("");
}

function div4(c) { return "<div class='col-xs-4'>" + c + "</div>"; }
function div(c) { return "<div>" + c + "</div>"; }

function spanOnClick(c, f) { return "<span class='near' onClick=\"" + f + "\">" + c + "</span>"; }
function entryLink(c, n) {
    return "<a onClick=\"$.router.go('/search/" + c + (n?"/"+n:"") + "');\">" + c
	+ (n?"<sup>"+n+"</sup>":"") + "</a>";
}

function formatWord(data) {
    var word;
    var entry = xml$dt.process(data, {
	'#map' : { 'form': 'div' },
	'#default' : function(q,c,v) { return xml$dt.tag(q,c,v); },
	'def' : function(q,c,v) {

	    c = c.replace(/(\smesmo\sque\s)_([^_]+)_(\sou\s)_([^_]+)_/g,
			  "$1" + entryLink("$2") + "$3" + entryLink("$4"));

	    c = c.replace(/(\smesmo\sque\s)_([^_]+)_/g,
			  "$1" + entryLink("$2"));

	    /* [[anona:1]]. */
	    
	    c = c.replace(/(\smesmo\sque\s|Cp\.\s)\[\[([^:]+):(\d+)\]\]/g,
			  "$1" + entryLink("$2", "$3")); 

	    
	    var s = c.replace(/(^\n(\s*\n)*|\n(\s*\n)*$)/g,"").replace(/_([^_]+)_/g, "<i>$1</i>").replace(/\n(\s*\n)*/g,"<br/>");
	    return xml$dt.tag(q,s,v);
	},
	'etym' : function(q,c,v) {
	    return c.replace(/_([^_]+)_/g, "<i>$1</i>");
	},
	'entry': function(q,c,v) {
	    word = v.id;
	    if (word.match(/:\d+$/)) {
		word = word.replace(/:(\d+)/, "<sup>$1</sup>");
	    }
	    return xml$dt.tag(q,c,v);
	}
    });

    return { term: word, def: entry };
}

function formatResults(data) {
    return $.map(data, function(v,i) { return formatEntry(v.xml); }).join("");
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

