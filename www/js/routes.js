var my_routes = {};

my_routes.rev_search = function (data) {
    var token = data.words;
    if (token.length < 3) {
	show_warning_alert("Pesquisa demasiado curta. Tente de novo.");
    } else {
	$.ajax({
	    url: 'http://api.dicionario-aberto.net/reverse/' + token
	}).done( (data) => {
	    load_template('advsearch', () => {
		var $table = $("<table></table>");
		$.each(data, (idx, val) => {
		    $table.append("<tr><td style='padding-right: 5px'><a onClick='GO(\"/search/" + val.word + "/" + val.sense + "\");'>" + val.word + "<sup>" + val.sense + "</sup></a></td><td>" + val.preview + "</td></tr>");
		});
		$('#results').html($table);
	    });
	});
    }
};


my_routes.ss_search = function (data) {
    var type = data.type;
    var token = data.word;
    if (token.length < 3) {
	show_warning_alert("Pesquisa demasiado curta. Tente de novo.");
    } else {
	$.ajax({
	    url: 'http://api.dicionario-aberto.net/' + type + '/' + token
	}).done( (data) => {
	    load_template('advsearch', () => {
		var $table = $("<table></table>");
		$.each(data, (idx, val) => {
		    $table.append("<tr><td style='padding-right: 5px'><a onClick='GO(\"/search/" + val.word + "/" + val.sense + "\");'>" + val.word + "<sup>" + val.sense + "</sup></a></td><td>" + val.preview + "</td></tr>");
		});
		$('#results').html($table);
	    });
	});
    }
};


my_routes.search = function(data) {
    load_template("search", function(){
	$.ajax({
	    url: 'http://api.dicionario-aberto.net/word/' + data.word + ("n" in data ? ("/" + data.n) : "")
	}).done(function(data) {
	    if (data.length == 0) {
		show_danger_alert("Nenhum resultado encontrado");
		$('#entries').addClass('hidden');
	    } else {
		$('#entriesContents').html(formatResults(data));
	    }
	});
	var word = data.word;
	$.ajax({
	    url: 'http://api.dicionario-aberto.net/near/' + word
	}).done(function(data) {
	    if (data.length == 0) {
		$('#nearMisses').addClass('hidden');
	    } else {
		$('#nearMissesContents').html(formatNearMisses($.grep(data, function(v){
		    return v != word
		})));
	    }
	});
	update_browse(data.word);
    });
};

my_routes.user = () => {
    load_template('user', () => {});
};

my_routes.login = function() {
    load_template("login", function() {
	$('a[role="tab"]').click(function (e) {
	    e.preventDefault();
	    $(this).tab('show');
	});
    });
};

my_routes.root = function() {
    load_template("index", function() {
	$.ajax({
	    url: 'http://api.dicionario-aberto.net/wotd',
	    cache: false,
	}).done(function(data) {
	    $('#wotd').html(formatEntry(data.xml));
	});
	$.ajax({
	    url: 'http://api.dicionario-aberto.net/news?limit=2',
	    cache: false,
	}).done(function(data) {
	    $('#news').html(formatNews(data));
	});
    });
};

function registerRoutes() {
    $.router.add('/', my_routes.root);
    $.router.add('/login', my_routes.login);
    $.router.add('/search/:word', my_routes.search);
    $.router.add('/search/:word/:n', my_routes.search);
    $.router.add('/ss_search/:type/:word', my_routes.ss_search);
    $.router.add('/rev_search/:words', my_routes.rev_search);
    $.router.add('/user', my_routes.user);
    $.router.addErrorHandler( (url) => { GO('/'); });
    
    $( document ).ajaxStop(function() {
	$('form').unblock();
	NProgress.done(); NProgress.remove();
    });
    $( document ).ajaxStart( () => { NProgress.start(); });
    $( document ).ajaxSuccess(
	(e, request, settings) => {
	    var header = request.getResponseHeader('Authorization');
	    if (header !== null && header.length > 5) {
		da_authorization = header;
		set_cookie('da_authorization', da_authorization);
		check_jwt_cookie();
	    }
	    else {
		da_authorization = "";
		da_jwt = {};
	    }
	}
    );
}

function check_jwt_cookie() {
    da_authorization = get_cookie('da_authorization');
    if (da_authorization != "") {
	da_jwt = jwt_decode(da_authorization);
		
	var current_time = new Date().getTime() / 1000;
	if (current_time > da_jwt.exp) {
	    da_jwt = {};
	    da_authorization = "";
	}
	else {
	    $('#nav-login').hide();
	    $('#nav-user').removeClass('hidden');	    
	    $('#nav-user-span').html(da_jwt.username);
	}
    }
}


function shade_forms() {
	$('form').block({message: null, overlayCSS:  { backgroundColor: '#FFF' } });
}

/*
var token = 'eyJ0eXAiO.../// jwt token';

var decoded = jwt_decode(token);
console.log(decoded);
*/
