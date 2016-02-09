package DA::API;

use DA::Database;

use Dancer2;
use Dancer2::Plugin::Database;

our $VERSION = '0.1';

our $DIC = DA::Database->new(database);

hook after => sub {
	response->push_header('Access-Control-Allow-Origin', 'http://novo.dicionario-aberto.net');
};

get '/' => sub {
    "OK"
};

get '/news' => sub {
	content_type "json";
	if (param('limit')) {
		to_json($DIC->retrieve_news(limit => param('limit')));
	} else {
		to_json($DIC->retrieve_news);			
	}
};

get '/new/*' => sub {
	my $id = splat;
	if ($id !~ /^\d+$/) {
		error('invalid new identifier');
	}
	else {
		content_type "json";
		to_json $DIC->retrieve_news( id => $id );
	}
};

sub error {
	my $error = shift;
	content_type "json";
	return to_json { error => $error };
};

true;
