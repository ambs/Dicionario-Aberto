var my_routes = {};

my_routes.ont_search = function (data) {
    var token = data.words;
    if (token.length < 3) {
	show_warning_alert("Pesquisa demasiado curta. Tente de novo.");
    } else {
	$.ajax({
	    url: 'https://api.dicionario-aberto.net/ontology/' + token
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


my_routes.rev_search = function (data) {
    var token = data.words;
    if (token.length < 3) {
	show_warning_alert("Pesquisa demasiado curta. Tente de novo.");
    } else {
	$.ajax({
	    url: 'https://api.dicionario-aberto.net/reverse/' + token
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
	    url: 'https://api.dicionario-aberto.net/' + type + '/' + token
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
	    url: 'https://api.dicionario-aberto.net/word/' + data.word + ("n" in data ? ("/" + data.n) : "")
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
	    url: 'https://api.dicionario-aberto.net/near/' + word
	}).done(function(data) {
	    if (data.length == 0) {
			$('#nearMisses').addClass('hidden');
	    } else {
			$('#nearMissesContents').html(formatNearMisses($.grep(data, (v) => {
		    	return v != word
			})));
	    }
	});
	update_browse(data.word);
    });
};

my_routes.xpassword = (params) => {
	var hash = params.hash;
	$.ajax({
		url: 'https://api.dicionario-aberto.net/confirm/' + hash
	}).done( (data) => {
		if (data.status == "OK") {
			var username = data.username;
			load_template("password", ( tmpl ) => { $("#hash").value = hash; $("#user").value = username; });
		}
		else {
			GO("/");
			show_danger_alert(data.error);
		}
	}) 
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

my_routes.root = () => {
    load_template("index", function() {
	$.ajax({
	    url: 'https://api.dicionario-aberto.net/wotd',
	    cache: false,
	}).done(function(data) {
	    $('#wotd').html(formatEntry(data.xml, data.word_id));
	});
	$.ajax({
	    url: 'https://api.dicionario-aberto.net/news?limit=2',
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
    $.router.add('/ont_search/:words', my_routes.ont_search);
    $.router.add('/user', my_routes.user);
    $.router.add('/confirm/:hash', my_routes.xpassword);
    $.router.addErrorHandler( (url) => { GO('/'); });
    
    $( document ).ajaxStop(function() {
		$('form').unblock();
		NProgress.done(); NProgress.remove();
    });
    $( document ).ajaxStart( () => { NProgress.start(); });
    $( document ).ajaxSend(
        ( event, request, settings ) => { settings.xhrFields = {withCredentials: true};
    }); 
}


function da_init() {
    $("#word").keyup(function(event){
	 	if(event.keyCode == 13) { formSearchBox(); }
    });
    $('#msgAlert .close').on("click", () => { hide_alert(); });

    registerRoutes();
    $.router.check();
}

function shade_forms() {
	$('form').block({message: null, overlayCSS:  { backgroundColor: '#FFF' } });
}

