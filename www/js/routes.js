
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
	$.ajax({
	    url: 'http://camelia.perl-hackers.net/near/' + data.word
	}).done(function(data) {
	    if (data.length == 0) {
		$('#nearMisses').addClass('hidden');
	    } else {
		$('#nearMissesContents').html(formatNearMisses(data));
	    }
	});
	    
    });
};


my_routes.random = function() {
    load_template("random", function(){
	$.ajax({
	    url: 'http://camelia.perl-hackers.net/random',
	    cache: false,
	}).done(function(data) {
	    $('#random').html(formatEntry(data.xml));
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
    $.router.add('/random', my_routes.random);
    $.router.add('/search/:word', my_routes.search);
    $.router.add('/search/:word/:n', my_routes.search);
    $.router.addErrorHandler(function (url) {
	// url is the URL which the router couldn't find a callback for
	// console.log(url);
	$.router.go('/');
    });
}
