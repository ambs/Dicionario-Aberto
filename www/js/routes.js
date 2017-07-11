
var da_authorization = "";
var da_jwt = {};
var my_routes = {};

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
    $.router.addErrorHandler(function (url) {
	// url is the URL which the router couldn't find a callback for
	// console.log(url);
	GO('/');
    });

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
		da_jwt = jwt_decode(da_authorization);

		$('#nav-login').hide();
		$('#nav-user').removeClass('hidden');	    
		$('#nav-user-span').html(da_jwt.username);
		
	    }
	    else {
		da_authorization = "";
		da_jwt = {};
	    }
	}
    );
}


function shade_forms() {
    $('form').block({message: null, overlayCSS:  { backgroundColor: '#FFF' } });
}

/*
var token = 'eyJ0eXAiO.../// jwt token';

var decoded = jwt_decode(token);
console.log(decoded);
*/
