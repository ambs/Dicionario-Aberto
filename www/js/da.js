

function GO(url) {
    hide_alert();
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
    $('#msgAlert').addClass("alert-dismissable");
    $('#msg-text').text(msg);
}

function hide_alert() {
    $('#msg').addClass("hidden");
    $('#msgAlert').removeClass();
}

function random() {
    NProgress.start();    
    $.ajax({
	url: 'https://api.dicionario-aberto.net/random',
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
	url: 'https://api.dicionario-aberto.net/browse/' + cid
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
    var word = "-1";
    var entry = xml$dt.process(data, {
	    'form' : function() { return ""; },
	    '#default' : function(q,c,v) { return xml$dt.tag(q,c,v); },
        'orth' : function(q,c,v) {
            if (word == "-1") {
                word = c;
            }
            return xml$dt.tag(q,c,v); },
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
    });
    
    return { term: word, def: entry };
}

function formatResults(data) {
    return $.map(data, function(v,i) { return formatEntry(v.xml, v.word_id ); }).join("");
}

function formatEntry(xml, wid) { 	
    var template = doT.template("<h3>{{=it.term}} <i class='fas fa-bookmark' id='bookmark{{=it.wid}}' title=''></i></h3><div>{{=it.def}}</div>",
			       $.extend( doT.templateSettings, {varname:'it'}));
    
    $.ajax({ url: 'https://api.dicionario-aberto.net/likes/' + wid })
	.done(function(total){
		var likes = total.tot;
		$("#bookmark" + wid).prop("title", likes + (likes == 1 ? " utilizador gosta" : " utilizadores gostam") + " desta palavra.");
	});
	
    return template($.extend(formatWord(xml), {wid: wid}));
}


function toggle(username, wid){
	$.ajax({ url: 'https://api.dicionario-aberto.net/user/' + username + '/set/' + wid })
		.done(
			(result) => { $("#bookmark" + wid).css('color', result.favourite ? 'blue' : '' ); }
		);
}

function formatNews(data) {
    var template = doT.template("<dl>{{~it.news :value:index}}<dt>{{=value.date.year}}-{{=value.date.month}}-{{=value.date.day}}</dt><dd>{{=value.text}}</dd>{{~}}</dl>",
			       	$.extend( doT.templateSettings, {varname:'it'}));
    data = $.map(data, function(v,i) { v.date = parseDate(v.date); return v; });
    return template({news: data});
}


function load_template(template_name, callback) {
    var url = "https://dicionario-aberto.net/templates/" + template_name + ".tmpl";
    $.ajax({ url: url, dataType: 'html' , mimeType: 'text/html'})
	    .done(
            (html) => {
                var func = doT.template(html,  doT.templateSettings);
	            $('#contents').html(  func ? func : {} );
	            callback();
	        }
        );
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
