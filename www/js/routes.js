
var my_routes = {};
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
}
