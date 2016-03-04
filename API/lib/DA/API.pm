package DA::API;

use DA::Database;

use Dancer2;
use Dancer2::Plugin::Database;

use XML::XML2JSON;

our $VERSION = '0.1';

our $DIC = DA::Database->new(sub { database });
our $X2J = XML::XML2JSON->new();

set serializer => 'JSON'; # Dancer2::Serializer::JSON

hook after => sub {
	response->push_header('Access-Control-Allow-Origin', 'http://novo.dicionario-aberto.net');
};

get '/' => sub {
    "OK"
};

# 185.130.5.247
# 
post '/xmlrpc.php' => sub {
	error ("FUCK THIS GUY, PLEASE! ", request->address);
	"FUCK YOU";
};

get '/news' => sub {
	if (param('limit')) {
		return($DIC->retrieve_news(limit => param('limit')));
	} else {
		return($DIC->retrieve_news);			
	}
};

get '/word/**' => sub {
	my ($x) = splat;
	my $word = $x->[0];
	my $sense = $x->[1];

	return $DIC->retrieve_entry($word, $sense);
};

get '/near/*' => sub {
	my ($word) = splat;
	return $DIC->near_misses($word);
};

get '/browse/:letter' => sub {
  my ($letter) = param('letter');

  my $idx = $DIC->get_browse_letter_position($letter);

  return $DIC->get_browse_range($idx);
};

get '/random' => sub {
	return { xml => $DIC->random };
};

get '/wotd' => sub {
	return { xml => $DIC->wotd };
};

get '/new/*' => sub {
	my $id = splat;
	if ($id !~ /^\d+$/) {
		return my_error('invalid new identifier');
	}
	else {
		return $DIC->retrieve_news( id => $id );
	}
};

sub my_error {
	my $error = shift;
	return { error => $error };
};

true;
