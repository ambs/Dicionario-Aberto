
var my_routes = {};

my_routes.search = function(data) {
    load_template("search", function(){
	$.ajax({
	    url: 'http://camelia.perl-hackers.net/word/' + data.word + ("n" in data ? ("/" + data.n) : "")
	}).done(function(data) {
	    if (data.length == 0) {
		$('#notFound').removeClass("hidden");
		$('#entries').addClass('hidden');
	    } else {
		$('#entriesContents').html(formatResults(data));
	    }
	});
	var word = data.word;
	$.ajax({
	    url: 'http://camelia.perl-hackers.net/near/' + word
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
	    url: 'http://camelia.perl-hackers.net/wotd',
	    cache: false,
	}).done(function(data) {
	    $('#wotd').html(formatEntry(data.xml));
	});
	$.ajax({
	    url: 'http://camelia.perl-hackers.net/news?limit=2',
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
	$.router.go('/');
    });
}
