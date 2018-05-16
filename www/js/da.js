
var da_authorization = "";
var da_jwt = {};

function GO(url) {
    hide_alert();
    check_jwt_cookie();
/*    if (da_authorization !== null && da_authorization.length > 5) {
	url += " ?_jwt= " + da_authorization;
    }*/
    $.router.go(url);
}

function show_warning_alert(msg) {
    _show_alert('warning', msg);
}
function show_info_alert(msg) {
    _show_alert('info', msg);
}
function show_danger_alert(msg) {
    _show_alert('danger', msg);
}

function _show_alert(type, msg) {
    $('#msg').removeClass("hidden");
    $('#msgAlert').removeClass(); // in case it is called without in-between GO's
    $('#msgAlert').addClass("alert");
    $('#msgAlert').addClass("alert-" + type);
    $('#msgAlert').html(msg);
}

function hide_alert() {
    $('#msg').addClass("hidden");
    $('#msgAlert').removeClass();
}

function random() {
    NProgress.start();    
    $.ajax({
	url: 'http://api.dicionario-aberto.net/random',
	cache: false,
    }).done(function(data) {
	GO('/search/' + data.word + "/" + data.sense);
    });
}

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
	url: 'http://api.dicionario-aberto.net/browse/' + cid
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
    GO('/search/' + word);
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
	return div4(spanOnClick(v, "GO('/search/" + v + "');"));
    }).join("");
}

function div4(c) { return "<div class='col-xs-4'>" + c + "</div>"; }
function div(c) { return "<div>" + c + "</div>"; }

function spanOnClick(c, f) { return "<span class='near' onClick=\"" + f + "\">" + c + "</span>"; }
function entryLink(c, n) {
    return "<a onClick=\"GO('/search/" + c + (n?"/"+n:"") + "');\">" + c
	+ (n?"<sup>"+n+"</sup>":"") + "</a>";
}

function formatWord(data) {
    var word;
    var entry = xml$dt.process(data, {
	'form' : function() { return ""; },
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
    var template = doT.template("<h3>{{=it.term}}</h3><div>{{=it.def}}</div><i class='far fa-bookmark' id='bookmark{{=it.word_id}}' title=''></i>",
			       $.extend( doT.templateSettings, {varname:'it'}));
    $ajax({ url: 'http://api.dicionario-aberto.net/' + data.word + '/' + data.sense })
	.done(function(data){
		var likes = data.tot;
		$("#bookmark" + data.word_id).prop("title", likes);
	});
				
    return template(formatWord(data));
}

function formatNews(data) {
    var template = doT.template("<dl>{{~it.news :value:index}}<dt>{{=value.date.year}}-{{=value.date.month}}-{{=value.date.day}}</dt><dd>{{=value.text}}</dd>{{~}}</dl>",
			       	$.extend( doT.templateSettings, {varname:'it'}));
    data = $.map(data, function(v,i) { v.date = parseDate(v.date); return v; });
    return template({news: data});
}


function load_template(template_name, callback) {
    var url = "/templates/" + template_name + ".tmpl";
    $.ajax({ url: url, dataType: 'html' , mimeType: 'text/html'})
	.done(function(html){
	    var func = doT.template(html, $.extend( doT.templateSettings, {varname:'jwt'}));
	    $('#contents').html(  func ? func( da_jwt ) : da_jwt );
	    callback();
	});
}


/* login page et al */
function show_and_hide(show, hide) {
    $.each(show, function (i, e) {
	$("#" + e).removeClass("hidden");
	$("#" + e + "Btn").addClass("hidden");
    });
    $.each(hide, function (i, e) {
	$("#" + e).addClass("hidden");
	$("#" + e + "Btn").removeClass("hidden");
    });

};

function set_cookie(key, value) {
    var expiration = new Date(new Date().getTime() + 30 * 24 * 60 * 60 * 1000).toUTCString();
    document.cookie = key + "=" + value + "; expires=" + expiration + "; path=/";
}

function get_cookie(cname) {
    var name = cname + "=";
    var decodedCookie = decodeURIComponent(document.cookie);
    var ca = decodedCookie.split(';');
    for(var i = 0; i <ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) == ' ') {
            c = c.substring(1);
        }
        if (c.indexOf(name) == 0) {
            return c.substring(name.length, c.length);
        }
    }
    return "";
}

function advAffix() {
    var affixType = $('#affixType').val();
    var affix = $('#affix').val();
    GO('/ss_search/' + affixType + '/' + affix);
    return false;
}

function advReverse() {
    var terms = $('#reverseTerms').val();
    GO('/rev_search/' + terms);
    return false;
}

function advOntology() {
    var terms = $('#ontologyTerms').val();
    GO('/ont_search/' + terms);
    return false;
}
